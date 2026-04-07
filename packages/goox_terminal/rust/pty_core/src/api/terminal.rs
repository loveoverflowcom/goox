use anyhow::{anyhow, bail, Context, Result};
use flutter_rust_bridge::frb;
use portable_pty::{native_pty_system, Child, CommandBuilder, MasterPty};
use std::collections::HashMap;
use std::convert::TryFrom;
use std::io::{Read, Write};
use std::path::Path;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, OnceLock};
use std::thread::{self, JoinHandle};
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;

use crate::frb_generated::StreamSink;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TerminalSessionStatus {
    Starting,
    Running,
    Exited,
    Closed,
    Failed,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TerminalSignal {
    Sigint,
    Sigterm,
    Sigkill,
    Sighup,
    Sigquit,
}

#[derive(Clone, Debug)]
pub struct TerminalSpawnRequest {
    pub shell: Option<String>,
    pub args: Vec<String>,
    pub working_directory: Option<String>,
    pub environment: HashMap<String, String>,
    pub rows: i32,
    pub cols: i32,
}

#[derive(Clone, Debug)]
pub struct TerminalSessionSnapshot {
    pub session_id: String,
    pub status: TerminalSessionStatus,
    pub pid: Option<u32>,
    pub exit_code: Option<i32>,
    pub shell: String,
    pub args: Vec<String>,
    pub working_directory: Option<String>,
    pub environment: HashMap<String, String>,
    pub rows: i32,
    pub cols: i32,
    pub attached: bool,
    pub created_at_ms: i64,
    pub started_at_ms: Option<i64>,
    pub last_activity_at_ms: Option<i64>,
}

type RegistryMap = HashMap<String, Arc<TerminalSessionRuntime>>;

static REGISTRY: OnceLock<Mutex<RegistryMap>> = OnceLock::new();

fn registry() -> &'static Mutex<RegistryMap> {
    REGISTRY.get_or_init(|| Mutex::new(HashMap::new()))
}

fn now_ms() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_millis() as i64)
        .unwrap_or_default()
}

fn resolve_shell(shell: Option<&str>) -> String {
    if let Some(shell) = shell {
        return shell.to_string();
    }

    #[cfg(windows)]
    {
        std::env::var("COMSPEC").unwrap_or_else(|_| "cmd.exe".to_string())
    }

    #[cfg(not(windows))]
    {
        std::env::var("SHELL").unwrap_or_else(|_| "/bin/sh".to_string())
    }
}

fn to_native_size(rows: i32, cols: i32) -> Result<portable_pty::PtySize> {
    if rows <= 0 || cols <= 0 {
        bail!("terminal size must be positive");
    }

    let rows = u16::try_from(rows).context("rows exceed supported range")?;
    let cols = u16::try_from(cols).context("cols exceed supported range")?;
    Ok(portable_pty::PtySize {
        rows,
        cols,
        pixel_width: 0,
        pixel_height: 0,
    })
}

fn control_byte(signal_number: i32) -> Option<u8> {
    match signal_number {
        2 => Some(0x03),
        3 => Some(0x1c),
        1 | 9 | 15 => None,
        _ => None,
    }
}

struct TerminalSessionRuntime {
    session_id: String,
    request: TerminalSpawnRequest,
    master: Mutex<Option<Box<dyn MasterPty + Send>>>,
    child: Mutex<Option<Box<dyn Child + Send>>>,
    writer: Mutex<Option<Box<dyn Write + Send>>>,
    pid: Option<u32>,
    status: Mutex<TerminalSessionStatus>,
    exit_code: Mutex<Option<i32>>,
    attached: AtomicBool,
    closed: AtomicBool,
    created_at_ms: i64,
    started_at_ms: Option<i64>,
    last_activity_at_ms: Mutex<Option<i64>>,
    output_thread: Mutex<Option<JoinHandle<()>>>,
}

impl TerminalSessionRuntime {
    fn spawn(request: TerminalSpawnRequest) -> Result<Arc<Self>> {
        request.validate()?;

        let session_id = Uuid::new_v4().to_string();
        let created_at_ms = now_ms();

        let pty_system = native_pty_system();
        let native_size = to_native_size(request.rows, request.cols)?;
        let pair = pty_system
            .openpty(native_size)
            .context("failed to open PTY")?;

        let shell = resolve_shell(request.shell.as_deref());
        let mut command = CommandBuilder::new(shell.clone());
        for arg in &request.args {
            command.arg(arg);
        }
        if let Some(working_directory) = request.working_directory.as_ref() {
            command.cwd(Path::new(working_directory));
        }
        for (key, value) in &request.environment {
            command.env(key, value);
        }
        if !request.environment.contains_key("TERM") {
            command.env("TERM", "xterm-256color");
        }

        let child = pair
            .slave
            .spawn_command(command)
            .context("failed to spawn terminal process")?;

        let pid = child.process_id();
        let master = pair.master;
        let writer = master.take_writer().context("failed to take PTY writer")?;

        Ok(Arc::new(Self {
            session_id,
            request,
            master: Mutex::new(Some(master)),
            child: Mutex::new(Some(child)),
            writer: Mutex::new(Some(writer)),
            pid,
            status: Mutex::new(TerminalSessionStatus::Running),
            exit_code: Mutex::new(None),
            attached: AtomicBool::new(false),
            closed: AtomicBool::new(false),
            created_at_ms,
            started_at_ms: Some(created_at_ms),
            last_activity_at_ms: Mutex::new(Some(created_at_ms)),
            output_thread: Mutex::new(None),
        }))
    }

    fn validate_request(request: &TerminalSpawnRequest) -> Result<()> {
        if request.rows <= 0 || request.cols <= 0 {
            bail!("terminal size must be positive");
        }
        Ok(())
    }

    fn snapshot(&self) -> Result<TerminalSessionSnapshot> {
        self.refresh_exit_state()?;
        Ok(TerminalSessionSnapshot {
            session_id: self.session_id.clone(),
            status: *self
                .status
                .lock()
                .map_err(|_| anyhow!("session status lock poisoned"))?,
            pid: self.pid,
            exit_code: *self
                .exit_code
                .lock()
                .map_err(|_| anyhow!("exit code lock poisoned"))?,
            shell: resolve_shell(self.request.shell.as_deref()),
            args: self.request.args.clone(),
            working_directory: self.request.working_directory.clone(),
            environment: self.request.environment.clone(),
            rows: self.request.rows,
            cols: self.request.cols,
            attached: self.attached.load(Ordering::SeqCst),
            created_at_ms: self.created_at_ms,
            started_at_ms: self.started_at_ms,
            last_activity_at_ms: *self
                .last_activity_at_ms
                .lock()
                .map_err(|_| anyhow!("last activity lock poisoned"))?,
        })
    }

    fn refresh_exit_state(&self) -> Result<()> {
        if self.closed.load(Ordering::SeqCst) {
            let mut status = self
                .status
                .lock()
                .map_err(|_| anyhow!("session status lock poisoned"))?;
            if *status != TerminalSessionStatus::Closed {
                *status = TerminalSessionStatus::Closed;
            }
            return Ok(());
        }

        let mut child_guard = self
            .child
            .lock()
            .map_err(|_| anyhow!("child lock poisoned"))?;
        if let Some(child) = child_guard.as_mut() {
            if let Some(exit_status) = child.try_wait().context("failed to poll child process")? {
                let exit_code = exit_status.exit_code() as i32;
                *self
                    .exit_code
                    .lock()
                    .map_err(|_| anyhow!("exit code lock poisoned"))? = Some(exit_code);
                *self
                    .status
                    .lock()
                    .map_err(|_| anyhow!("session status lock poisoned"))? =
                    TerminalSessionStatus::Exited;
            }
        }
        Ok(())
    }

    fn mark_activity(&self) -> Result<()> {
        *self
            .last_activity_at_ms
            .lock()
            .map_err(|_| anyhow!("last activity lock poisoned"))? = Some(now_ms());
        Ok(())
    }

    fn set_status(&self, status: TerminalSessionStatus) -> Result<()> {
        *self
            .status
            .lock()
            .map_err(|_| anyhow!("session status lock poisoned"))? = status;
        Ok(())
    }

    fn write_bytes(&self, data: &[u8]) -> Result<usize> {
        if self.closed.load(Ordering::SeqCst) {
            bail!("session is closed");
        }
        self.refresh_exit_state()?;
        if matches!(
            *self
                .status
                .lock()
                .map_err(|_| anyhow!("session status lock poisoned"))?,
            TerminalSessionStatus::Exited
        ) {
            bail!("session has exited");
        }

        let mut writer_guard = self
            .writer
            .lock()
            .map_err(|_| anyhow!("writer lock poisoned"))?;
        let writer = writer_guard
            .as_mut()
            .ok_or_else(|| anyhow!("terminal input is closed"))?;
        writer
            .write_all(data)
            .context("failed to write to terminal input")?;
        writer.flush().ok();
        self.mark_activity()?;
        Ok(data.len())
    }

    fn resize(&self, rows: i32, cols: i32) -> Result<()> {
        if self.closed.load(Ordering::SeqCst) {
            bail!("session is closed");
        }
        let native_size = to_native_size(rows, cols)?;
        let mut master_guard = self
            .master
            .lock()
            .map_err(|_| anyhow!("master lock poisoned"))?;
        let master = master_guard
            .as_mut()
            .ok_or_else(|| anyhow!("terminal master is closed"))?;
        master
            .resize(native_size)
            .context("failed to resize terminal")?;
        self.mark_activity()?;
        Ok(())
    }

    fn send_signal(&self, signal_number: i32) -> Result<()> {
        if self.closed.load(Ordering::SeqCst) {
            bail!("session is closed");
        }
        if let Some(byte) = control_byte(signal_number) {
            return self.write_bytes(&[byte]).map(|_| ());
        }

        let mut child_guard = self
            .child
            .lock()
            .map_err(|_| anyhow!("child lock poisoned"))?;
        let child = child_guard
            .as_mut()
            .ok_or_else(|| anyhow!("terminal process is no longer available"))?;
        child.kill().context("failed to terminate child process")?;
        self.mark_activity()?;
        Ok(())
    }

    fn wait_for_exit(&self) -> Result<i32> {
        if let Some(exit_code) = *self
            .exit_code
            .lock()
            .map_err(|_| anyhow!("exit code lock poisoned"))?
        {
            return Ok(exit_code);
        }

        let mut child_guard = self
            .child
            .lock()
            .map_err(|_| anyhow!("child lock poisoned"))?;
        let child = child_guard
            .as_mut()
            .ok_or_else(|| anyhow!("terminal process is no longer available"))?;
        let exit_status = child.wait().context("failed while waiting for exit")?;
        let exit_code = exit_status.exit_code() as i32;
        *self
            .exit_code
            .lock()
            .map_err(|_| anyhow!("exit code lock poisoned"))? = Some(exit_code);
        *self
            .status
            .lock()
            .map_err(|_| anyhow!("session status lock poisoned"))? = TerminalSessionStatus::Exited;
        Ok(exit_code)
    }

    fn attach_output(self: &Arc<Self>, sink: StreamSink<Vec<u8>>) -> Result<()> {
        if self.closed.load(Ordering::SeqCst) {
            bail!("session is closed");
        }

        if self.attached.swap(true, Ordering::SeqCst) {
            return Ok(());
        }

        self.set_status(TerminalSessionStatus::Running)?;
        self.mark_activity()?;

        let reader = {
            let mut master_guard = self
                .master
                .lock()
                .map_err(|_| anyhow!("master lock poisoned"))?;
            let master = master_guard
                .as_mut()
                .ok_or_else(|| anyhow!("terminal master is closed"))?;
            master
                .try_clone_reader()
                .context("failed to clone PTY reader")?
        };

        let session = Arc::clone(self);
        let handle = thread::spawn(move || {
            let mut reader = reader;
            let mut buffer = vec![0_u8; 8192];
            loop {
                match reader.read(&mut buffer) {
                    Ok(0) => break,
                    Ok(count) => {
                        let chunk = buffer[..count].to_vec();
                        let _ = sink.add(chunk);
                        let _ = session.mark_activity();
                    }
                    Err(error) => {
                        let _ =
                            sink.add_error(anyhow!(error).context("terminal output stream failed"));
                        let _ = session.set_status(TerminalSessionStatus::Failed);
                        break;
                    }
                }
            }
        });

        *self
            .output_thread
            .lock()
            .map_err(|_| anyhow!("output thread lock poisoned"))? = Some(handle);
        Ok(())
    }

    fn close(&self) -> Result<()> {
        if self.closed.swap(true, Ordering::SeqCst) {
            return Ok(());
        }

        self.attached.store(false, Ordering::SeqCst);
        let _ = self.mark_activity();

        let _ = self.writer.lock().map(|mut guard| guard.take());
        let _ = self.master.lock().map(|mut guard| guard.take());

        if let Some(mut child) = self
            .child
            .lock()
            .map_err(|_| anyhow!("child lock poisoned"))?
            .take()
        {
            let _ = child.kill();
            if let Ok(exit_status) = child.wait() {
                *self
                    .exit_code
                    .lock()
                    .map_err(|_| anyhow!("exit code lock poisoned"))? =
                    Some(exit_status.exit_code() as i32);
            }
        }

        if let Some(handle) = self
            .output_thread
            .lock()
            .map_err(|_| anyhow!("output thread lock poisoned"))?
            .take()
        {
            let _ = handle.join();
        }

        self.set_status(TerminalSessionStatus::Closed)?;
        Ok(())
    }
}

impl TerminalSpawnRequest {
    fn validate(&self) -> Result<()> {
        TerminalSessionRuntime::validate_request(self)
    }
}

/// Initializes terminal registry state for the FRB bridge.
#[frb(init)]
pub fn init_pty_core() {
    let _ = registry();
}

/// Creates a new terminal session and returns its session identifier.
#[frb]
pub fn create_session(request: TerminalSpawnRequest) -> Result<String> {
    let session = TerminalSessionRuntime::spawn(request)?;
    let session_id = session.session_id.clone();
    let mut sessions = registry()
        .lock()
        .map_err(|_| anyhow!("terminal registry lock poisoned"))?;
    sessions.insert(session.session_id.clone(), session);
    Ok(session_id)
}

/// Returns the latest snapshot for a managed terminal session.
#[frb]
pub fn session_snapshot(session_id: String) -> Result<TerminalSessionSnapshot> {
    let session = {
        let sessions = registry()
            .lock()
            .map_err(|_| anyhow!("terminal registry lock poisoned"))?;
        sessions.get(&session_id).cloned()
    }
    .ok_or_else(|| anyhow!("session not found: {session_id}"))?;
    session.snapshot()
}

/// Lists all managed terminal sessions.
#[frb]
pub fn list_sessions() -> Result<Vec<TerminalSessionSnapshot>> {
    let sessions = {
        let sessions = registry()
            .lock()
            .map_err(|_| anyhow!("terminal registry lock poisoned"))?;
        let mut values: Vec<_> = sessions.values().cloned().collect();
        values.sort_by(|left, right| left.created_at_ms.cmp(&right.created_at_ms));
        values
    };
    sessions
        .into_iter()
        .map(|session| session.snapshot())
        .collect()
}

/// Attaches a listener to terminal output.
#[frb]
pub fn attach_output(session_id: String, sink: StreamSink<Vec<u8>>) -> Result<()> {
    let session = {
        let sessions = registry()
            .lock()
            .map_err(|_| anyhow!("terminal registry lock poisoned"))?;
        sessions.get(&session_id).cloned()
    }
    .ok_or_else(|| anyhow!("session not found: {session_id}"))?;
    session.attach_output(sink)
}

/// Writes raw bytes into the terminal input stream.
#[frb]
pub fn write_input(session_id: String, data: Vec<u8>) -> Result<i32> {
    let session = {
        let sessions = registry()
            .lock()
            .map_err(|_| anyhow!("terminal registry lock poisoned"))?;
        sessions.get(&session_id).cloned()
    }
    .ok_or_else(|| anyhow!("session not found: {session_id}"))?;
    let written = session.write_bytes(&data)?;
    Ok(written as i32)
}

/// Resizes the terminal to the requested rows and columns.
#[frb]
pub fn resize_session(session_id: String, rows: i32, cols: i32) -> Result<()> {
    let session = {
        let sessions = registry()
            .lock()
            .map_err(|_| anyhow!("terminal registry lock poisoned"))?;
        sessions.get(&session_id).cloned()
    }
    .ok_or_else(|| anyhow!("session not found: {session_id}"))?;
    session.resize(rows, cols)
}

/// Sends a terminal signal to the process.
#[frb]
pub fn send_signal(session_id: String, signal_number: i32) -> Result<()> {
    let session = {
        let sessions = registry()
            .lock()
            .map_err(|_| anyhow!("terminal registry lock poisoned"))?;
        sessions.get(&session_id).cloned()
    }
    .ok_or_else(|| anyhow!("session not found: {session_id}"))?;
    session.send_signal(signal_number)
}

/// Waits for the terminal process to exit and returns the exit code.
#[frb]
pub fn wait_for_exit(session_id: String) -> Result<i32> {
    let session = {
        let sessions = registry()
            .lock()
            .map_err(|_| anyhow!("terminal registry lock poisoned"))?;
        sessions.get(&session_id).cloned()
    }
    .ok_or_else(|| anyhow!("session not found: {session_id}"))?;
    session.wait_for_exit()
}

/// Closes a managed terminal session and releases all native resources.
#[frb]
pub fn close_session(session_id: String) -> Result<()> {
    let session = {
        let mut sessions = registry()
            .lock()
            .map_err(|_| anyhow!("terminal registry lock poisoned"))?;
        sessions.remove(&session_id)
    }
    .ok_or_else(|| anyhow!("session not found: {session_id}"))?;
    session.close()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn validates_sizes() {
        let request = TerminalSpawnRequest {
            shell: None,
            args: vec![],
            working_directory: None,
            environment: HashMap::new(),
            rows: 24,
            cols: 80,
        };

        assert!(request.validate().is_ok());
    }

    #[test]
    fn rejects_invalid_size() {
        let request = TerminalSpawnRequest {
            shell: None,
            args: vec![],
            working_directory: None,
            environment: HashMap::new(),
            rows: 0,
            cols: 80,
        };

        assert!(request.validate().is_err());
    }
}
