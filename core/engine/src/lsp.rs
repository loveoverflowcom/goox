use serde_json::{Value, json};
use std::collections::HashMap;
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Child, ChildStdin, ChildStdout, Command, Stdio};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Condvar, LazyLock, Mutex, mpsc};
use std::thread;
use std::time::Duration;
use url::Url;

#[derive(Debug, Clone)]
pub struct LanguageServerDiagnosticRange {
    pub start_line: u32,
    pub start_character: u32,
    pub end_line: u32,
    pub end_character: u32,
}

#[derive(Debug, Clone)]
pub struct LanguageServerDiagnostic {
    pub range: LanguageServerDiagnosticRange,
    pub severity: Option<u32>,
    pub source: Option<String>,
    pub message: String,
}

#[derive(Debug, Clone)]
pub struct LanguageServerSnapshot {
    pub status: String,
    pub executable: Option<String>,
    pub language_id: Option<String>,
    pub document_uri: Option<String>,
    pub version: u64,
    pub diagnostics_generation: u64,
    pub diagnostics: Vec<LanguageServerDiagnostic>,
    pub last_error: Option<String>,
}

impl LanguageServerSnapshot {
    fn inactive() -> Self {
        Self {
            status: "inactive".to_string(),
            executable: None,
            language_id: None,
            document_uri: None,
            version: 0,
            diagnostics_generation: 0,
            diagnostics: Vec::new(),
            last_error: None,
        }
    }
}

impl Default for LanguageServerSnapshot {
    fn default() -> Self {
        Self::inactive()
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct LanguageServerConfig {
    workspace_root: Option<PathBuf>,
    document_path: PathBuf,
    language_id: String,
    executable: String,
    args: Vec<String>,
}

impl LanguageServerConfig {
    fn from_inputs(
        workspace_root: Option<String>,
        file_path: Option<String>,
        language_id: Option<String>,
        lsp_executable: Option<String>,
    ) -> Option<Self> {
        let file_path = normalize_optional_path(file_path)?;
        let language_id =
            normalize_optional_string(language_id).or_else(|| infer_language_id(&file_path))?;
        let executable = normalize_optional_string(lsp_executable)?;
        let workspace_root = normalize_optional_path(workspace_root);

        let mut parts = executable
            .split_whitespace()
            .filter(|part| !part.trim().is_empty())
            .map(ToString::to_string)
            .collect::<Vec<_>>();
        if parts.is_empty() {
            return None;
        }

        let executable = parts.remove(0);
        if parts.is_empty() {
            parts.push("--stdio".to_string());
        }
        Some(Self {
            workspace_root,
            document_path: file_path,
            language_id,
            executable,
            args: parts,
        })
    }

    fn file_uri(&self) -> Option<String> {
        file_uri(&self.document_path)
    }

    fn root_uri(&self) -> Option<String> {
        self.workspace_root.as_deref().and_then(file_uri)
    }

    fn signature(&self) -> String {
        format!(
            "{}|{}|{}|{}|{}",
            self.workspace_root
                .as_ref()
                .map(|path| path.display().to_string())
                .unwrap_or_default(),
            self.document_path.display(),
            self.language_id,
            self.executable,
            self.args.join(" ")
        )
    }
}

#[derive(Debug)]
struct LanguageServerState {
    snapshot: LanguageServerSnapshot,
    document_opened: bool,
}

#[derive(Debug)]
struct LanguageServerSession {
    config: LanguageServerConfig,
    state: Arc<(Mutex<LanguageServerState>, Condvar)>,
    request_tx: mpsc::Sender<Vec<u8>>,
    pending_requests: Arc<Mutex<HashMap<u64, mpsc::Sender<Result<Value, String>>>>>,
    next_request_id: AtomicU64,
    child: Arc<Mutex<Child>>,
}

#[derive(Debug, Default)]
struct LanguageServerRuntime {
    session: Option<Arc<LanguageServerSession>>,
    last_snapshot: LanguageServerSnapshot,
    last_signature: Option<String>,
}

static RUNTIME: LazyLock<Mutex<LanguageServerRuntime>> =
    LazyLock::new(|| Mutex::new(LanguageServerRuntime::default()));

pub fn sync_language_server(
    workspace_root: Option<String>,
    file_path: Option<String>,
    language_id: Option<String>,
    lsp_executable: Option<String>,
    text: String,
) -> bool {
    let Some(config) =
        LanguageServerConfig::from_inputs(workspace_root, file_path, language_id, lsp_executable)
    else {
        shutdown_language_server();
        return false;
    };

    let session = {
        let mut runtime = RUNTIME.lock().unwrap();
        let signature = config.signature();
        let needs_restart = runtime
            .last_signature
            .as_ref()
            .map_or(true, |existing| existing != &signature);

        if needs_restart {
            if let Some(existing) = runtime.session.take() {
                existing.shutdown();
            }

            match LanguageServerSession::start(config.clone()) {
                Ok(session) => {
                    let session = Arc::new(session);
                    runtime.last_signature = Some(signature);
                    runtime.last_snapshot = session.snapshot();
                    runtime.session = Some(Arc::clone(&session));
                    session
                }
                Err(error) => {
                    runtime.last_signature = Some(signature);
                    runtime.last_snapshot = LanguageServerSnapshot {
                        status: "error".to_string(),
                        executable: Some(config.executable.clone()),
                        language_id: Some(config.language_id.clone()),
                        document_uri: config.file_uri(),
                        version: 0,
                        diagnostics_generation: 0,
                        diagnostics: Vec::new(),
                        last_error: Some(error),
                    };
                    return false;
                }
            }
        } else {
            match runtime.session.as_ref() {
                Some(session) => Arc::clone(session),
                None => match LanguageServerSession::start(config.clone()) {
                    Ok(session) => {
                        let session = Arc::new(session);
                        runtime.last_snapshot = session.snapshot();
                        runtime.session = Some(Arc::clone(&session));
                        session
                    }
                    Err(error) => {
                        runtime.last_snapshot = LanguageServerSnapshot {
                            status: "error".to_string(),
                            executable: Some(config.executable.clone()),
                            language_id: Some(config.language_id.clone()),
                            document_uri: config.file_uri(),
                            version: 0,
                            diagnostics_generation: 0,
                            diagnostics: Vec::new(),
                            last_error: Some(error),
                        };
                        return false;
                    }
                },
            }
        }
    };

    let sync_result = session.sync_document(&text);
    if let Err(error) = sync_result {
        let mut runtime = RUNTIME.lock().unwrap();
        runtime.last_snapshot = LanguageServerSnapshot {
            status: "error".to_string(),
            executable: Some(config.executable.clone()),
            language_id: Some(config.language_id.clone()),
            document_uri: config.file_uri(),
            version: 0,
            diagnostics_generation: 0,
            diagnostics: Vec::new(),
            last_error: Some(error),
        };
        runtime.session = None;
        return false;
    }

    let mut runtime = RUNTIME.lock().unwrap();
    runtime.last_snapshot = session.snapshot();
    true
}

pub fn poll_language_server() -> LanguageServerSnapshot {
    let runtime = RUNTIME.lock().unwrap();
    match &runtime.session {
        Some(session) => session.snapshot(),
        None => runtime.last_snapshot.clone(),
    }
}

pub fn shutdown_language_server() {
    let mut runtime = RUNTIME.lock().unwrap();
    if let Some(session) = runtime.session.take() {
        session.shutdown();
    }
    runtime.last_signature = None;
    runtime.last_snapshot = LanguageServerSnapshot::inactive();
}

impl LanguageServerSession {
    fn start(config: LanguageServerConfig) -> Result<Self, String> {
        let mut command_parts = vec![config.executable.clone()];
        command_parts.extend(config.args.clone());

        let mut command = Command::new(&command_parts[0]);
        command.args(&command_parts[1..]);
        command.stdin(Stdio::piped());
        command.stdout(Stdio::piped());
        command.stderr(Stdio::null());
        if let Some(root) = &config.workspace_root {
            command.current_dir(root);
        }

        let mut child = command
            .spawn()
            .map_err(|error| format!("failed to spawn language server: {error}"))?;

        let stdin = child
            .stdin
            .take()
            .ok_or_else(|| "language server stdin is unavailable".to_string())?;
        let stdout = child
            .stdout
            .take()
            .ok_or_else(|| "language server stdout is unavailable".to_string())?;

        let (request_tx, request_rx) = mpsc::channel::<Vec<u8>>();
        let pending_requests: Arc<Mutex<HashMap<u64, mpsc::Sender<Result<Value, String>>>>> =
            Arc::new(Mutex::new(HashMap::new()));
        let state = Arc::new((
            Mutex::new(LanguageServerState {
                snapshot: LanguageServerSnapshot {
                    status: "starting".to_string(),
                    executable: Some(command_parts.join(" ")),
                    language_id: Some(config.language_id.clone()),
                    document_uri: config.file_uri(),
                    version: 0,
                    diagnostics_generation: 0,
                    diagnostics: Vec::new(),
                    last_error: None,
                },
                document_opened: false,
            }),
            Condvar::new(),
        ));
        let child = Arc::new(Mutex::new(child));

        spawn_writer_thread(stdin, request_rx, Arc::clone(&state));
        spawn_reader_thread(stdout, Arc::clone(&pending_requests), Arc::clone(&state));

        let session = Self {
            config,
            state,
            request_tx,
            pending_requests,
            next_request_id: AtomicU64::new(1),
            child,
        };

        if let Err(error) = session.initialize() {
            session.force_kill();
            return Err(error);
        }
        session.update_status("ready", None);
        Ok(session)
    }

    fn initialize(&self) -> Result<(), String> {
        let params = json!({
            "processId": Value::Null,
            "clientInfo": {
                "name": "Goox",
                "version": "0.1.0",
            },
            "rootUri": self.config.root_uri().map(Value::String).unwrap_or(Value::Null),
            "workspaceFolders": self.config.root_uri().map(|root_uri| {
                vec![json!({
                    "uri": root_uri,
                    "name": self.config
                        .workspace_root
                        .as_ref()
                        .and_then(|root| root.file_name())
                        .and_then(|name| name.to_str())
                        .unwrap_or("workspace"),
                })]
            }),
            "capabilities": {
                "textDocument": {
                    "publishDiagnostics": {
                        "relatedInformation": true
                    }
                }
            }
        });

        let response = self.send_request("initialize", params)?;
        if response.is_object() {
            self.send_notification("initialized", json!({}));
            Ok(())
        } else {
            Err("language server returned an invalid initialize response".to_string())
        }
    }

    fn sync_document(&self, text: &str) -> Result<(), String> {
        let uri = self
            .config
            .file_uri()
            .ok_or_else(|| "language server document uri is unavailable".to_string())?;

        let mut state = self.state.0.lock().unwrap();
        state.snapshot.document_uri = Some(uri.clone());
        state.snapshot.language_id = Some(self.config.language_id.clone());
        state.snapshot.executable = Some(self.config.executable.clone());
        state.snapshot.last_error = None;
        state.snapshot.status = "ready".to_string();
        state.snapshot.version = state.snapshot.version.saturating_add(1);
        let version = state.snapshot.version;

        let is_change = state.document_opened;
        let message = if is_change {
            json!({
                "textDocument": {
                    "uri": uri,
                    "version": version,
                },
                "contentChanges": [{
                    "text": text,
                }],
            })
        } else {
            state.document_opened = true;
            json!({
                "textDocument": {
                    "uri": uri,
                    "languageId": self.config.language_id.clone(),
                    "version": version,
                    "text": text,
                }
            })
        };

        drop(state);
        if is_change {
            self.send_notification("textDocument/didChange", message);
        } else {
            self.send_notification("textDocument/didOpen", message);
        }

        Ok(())
    }

    fn send_request(&self, method: &str, params: Value) -> Result<Value, String> {
        let request_id = self.next_request_id.fetch_add(1, Ordering::SeqCst);
        let (response_tx, response_rx) = mpsc::channel();
        self.pending_requests
            .lock()
            .unwrap()
            .insert(request_id, response_tx);

        self.send_message(json!({
            "jsonrpc": "2.0",
            "id": request_id,
            "method": method,
            "params": params,
        }))?;

        response_rx
            .recv_timeout(Duration::from_secs(5))
            .map_err(|_| format!("language server request timed out: {method}"))?
    }

    fn send_notification(&self, method: &str, params: Value) {
        let _ = self.send_message(json!({
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
        }));
    }

    fn send_message(&self, message: Value) -> Result<(), String> {
        let bytes = encode_message(&message)?;
        self.request_tx
            .send(bytes)
            .map_err(|_| "language server writer channel is closed".to_string())
    }

    fn update_status(&self, status: &str, last_error: Option<String>) {
        let (state_mutex, condvar) = &*self.state;
        let mut state = state_mutex.lock().unwrap();
        state.snapshot.status = status.to_string();
        state.snapshot.last_error = last_error;
        condvar.notify_all();
    }

    fn snapshot(&self) -> LanguageServerSnapshot {
        self.refresh_health();
        let (state_mutex, _) = &*self.state;
        state_mutex.lock().unwrap().snapshot.clone()
    }

    fn shutdown(&self) {
        let _ = self.send_request("shutdown", json!({}));
        self.send_notification("exit", json!({}));

        self.update_status("stopping", None);
        if let Ok(mut child) = self.child.lock() {
            let _ = child.try_wait();
            let _ = child.kill();
        }
        self.update_status("stopped", None);
    }

    fn force_kill(&self) {
        if let Ok(mut child) = self.child.lock() {
            let _ = child.kill();
        }
    }

    fn refresh_health(&self) {
        if let Ok(mut child) = self.child.lock() {
            match child.try_wait() {
                Ok(Some(status)) => {
                    let (state_mutex, condvar) = &*self.state;
                    let mut state = state_mutex.lock().unwrap();
                    if status.success() {
                        state.snapshot.status = "stopped".to_string();
                        state.snapshot.last_error = None;
                    } else {
                        state.snapshot.status = "error".to_string();
                        state.snapshot.last_error =
                            Some(format!("language server exited with {status}"));
                    }
                    condvar.notify_all();
                }
                Ok(None) => {
                    let (state_mutex, _) = &*self.state;
                    let mut state = state_mutex.lock().unwrap();
                    if state.snapshot.status == "starting" {
                        state.snapshot.status = "ready".to_string();
                    }
                }
                Err(error) => {
                    let (state_mutex, condvar) = &*self.state;
                    let mut state = state_mutex.lock().unwrap();
                    state.snapshot.status = "error".to_string();
                    state.snapshot.last_error =
                        Some(format!("language server health check failed: {error}"));
                    condvar.notify_all();
                }
            }
        }
    }
}

fn spawn_writer_thread(
    mut stdin: ChildStdin,
    request_rx: mpsc::Receiver<Vec<u8>>,
    state: Arc<(Mutex<LanguageServerState>, Condvar)>,
) {
    thread::spawn(move || {
        for bytes in request_rx {
            if stdin.write_all(&bytes).and_then(|_| stdin.flush()).is_err() {
                let (state_mutex, condvar) = &*state;
                let mut state = state_mutex.lock().unwrap();
                state.snapshot.status = "error".to_string();
                state.snapshot.last_error = Some("failed to write to language server".to_string());
                condvar.notify_all();
                break;
            }
        }
    });
}

fn spawn_reader_thread(
    mut stdout: ChildStdout,
    pending_requests: Arc<Mutex<HashMap<u64, mpsc::Sender<Result<Value, String>>>>>,
    state: Arc<(Mutex<LanguageServerState>, Condvar)>,
) {
    thread::spawn(move || {
        let mut buffer = Vec::<u8>::new();
        let mut read_buf = [0u8; 4096];

        loop {
            match stdout.read(&mut read_buf) {
                Ok(0) => {
                    let (state_mutex, condvar) = &*state;
                    let mut state = state_mutex.lock().unwrap();
                    state.snapshot.status = "stopped".to_string();
                    condvar.notify_all();
                    break;
                }
                Ok(count) => {
                    buffer.extend_from_slice(&read_buf[..count]);
                    while let Some((message, consumed)) = try_parse_message(&buffer) {
                        buffer.drain(..consumed);
                        handle_message(message, &pending_requests, &state);
                    }
                }
                Err(error) => {
                    let (state_mutex, condvar) = &*state;
                    let mut state = state_mutex.lock().unwrap();
                    state.snapshot.status = "error".to_string();
                    state.snapshot.last_error =
                        Some(format!("language server read error: {error}"));
                    condvar.notify_all();
                    break;
                }
            }
        }
    });
}

fn handle_message(
    message: Value,
    pending_requests: &Arc<Mutex<HashMap<u64, mpsc::Sender<Result<Value, String>>>>>,
    state: &Arc<(Mutex<LanguageServerState>, Condvar)>,
) {
    if let Some(id) = message.get("id").and_then(parse_message_id) {
        let response = if let Some(error) = message.get("error") {
            Err(error_to_string(error))
        } else {
            Ok(message.get("result").cloned().unwrap_or(Value::Null))
        };

        if let Some(sender) = pending_requests.lock().unwrap().remove(&id) {
            let _ = sender.send(response);
        }
        return;
    }

    let Some(method) = message.get("method").and_then(Value::as_str) else {
        return;
    };

    if method == "textDocument/publishDiagnostics" {
        if let Some(params) = message.get("params") {
            if let Some(diagnostics) = parse_diagnostics(params) {
                let (state_mutex, condvar) = &**state;
                let mut state = state_mutex.lock().unwrap();
                state.snapshot.diagnostics = diagnostics;
                state.snapshot.diagnostics_generation =
                    state.snapshot.diagnostics_generation.saturating_add(1);
                condvar.notify_all();
            }
        }
    }
}

fn parse_diagnostics(params: &Value) -> Option<Vec<LanguageServerDiagnostic>> {
    let diagnostics = params.get("diagnostics")?.as_array()?;
    Some(
        diagnostics
            .iter()
            .map(|diagnostic| {
                let range = diagnostic.get("range")?;
                let start = range.get("start")?;
                let end = range.get("end")?;
                Some(LanguageServerDiagnostic {
                    range: LanguageServerDiagnosticRange {
                        start_line: start.get("line")?.as_u64()? as u32,
                        start_character: start.get("character")?.as_u64()? as u32,
                        end_line: end.get("line")?.as_u64()? as u32,
                        end_character: end.get("character")?.as_u64()? as u32,
                    },
                    severity: diagnostic
                        .get("severity")
                        .and_then(Value::as_u64)
                        .map(|value| value as u32),
                    source: diagnostic
                        .get("source")
                        .and_then(Value::as_str)
                        .map(ToString::to_string),
                    message: diagnostic
                        .get("message")
                        .and_then(Value::as_str)
                        .unwrap_or("")
                        .to_string(),
                })
            })
            .collect::<Option<Vec<_>>>()?,
    )
}

fn try_parse_message(buffer: &[u8]) -> Option<(Value, usize)> {
    let header_end = buffer.windows(4).position(|window| window == b"\r\n\r\n")?;
    let headers = std::str::from_utf8(&buffer[..header_end]).ok()?;
    let content_length = headers.lines().find_map(|line| {
        let (name, value) = line.split_once(':')?;
        if name.trim().eq_ignore_ascii_case("content-length") {
            value.trim().parse::<usize>().ok()
        } else {
            None
        }
    })?;
    let body_start = header_end + 4;
    let body_end = body_start + content_length;
    if buffer.len() < body_end {
        return None;
    }

    let body = std::str::from_utf8(&buffer[body_start..body_end]).ok()?;
    let message = serde_json::from_str::<Value>(body).ok()?;
    Some((message, body_end))
}

fn encode_message(message: &Value) -> Result<Vec<u8>, String> {
    let body = serde_json::to_vec(message).map_err(|error| error.to_string())?;
    let mut output = format!("Content-Length: {}\r\n\r\n", body.len()).into_bytes();
    output.extend_from_slice(&body);
    Ok(output)
}

fn parse_message_id(value: &Value) -> Option<u64> {
    value.as_u64()
}

fn error_to_string(value: &Value) -> String {
    value
        .get("message")
        .and_then(Value::as_str)
        .unwrap_or("language server error")
        .to_string()
}

fn normalize_optional_string(value: Option<String>) -> Option<String> {
    value.and_then(|value| {
        let trimmed = value.trim();
        if trimmed.is_empty() {
            None
        } else {
            Some(trimmed.to_string())
        }
    })
}

fn normalize_optional_path(value: Option<String>) -> Option<PathBuf> {
    normalize_optional_string(value).map(PathBuf::from)
}

fn infer_language_id(path: &Path) -> Option<String> {
    let extension = path
        .extension()
        .and_then(|ext| ext.to_str())?
        .to_lowercase();
    let inferred = match extension.as_str() {
        "js" | "mjs" | "cjs" => "javascript",
        "ts" | "tsx" => "typescript",
        "jsx" => "javascriptreact",
        "py" | "pyw" => "python",
        "rs" => "rust",
        "go" => "go",
        "json" => "json",
        "css" => "css",
        "html" | "htm" => "html",
        "md" => "markdown",
        other => other,
    };

    Some(inferred.to_string())
}

fn file_uri(path: &Path) -> Option<String> {
    let absolute = if path.is_absolute() {
        path.to_path_buf()
    } else {
        std::env::current_dir().ok()?.join(path)
    };

    Url::from_file_path(&absolute)
        .ok()
        .map(|url| url.to_string())
}
