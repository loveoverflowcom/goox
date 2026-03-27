use flutter_rust_bridge::frb;
use portable_pty::{CommandBuilder, PtySize, native_pty_system};
use std::io::{Read, Write};
use std::sync::{Arc, Mutex};
use std::thread;

// ── Screen Model ────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Default)]
pub struct Cell {
    pub char: String,
    pub fg_color: Option<String>,
    pub bg_color: Option<String>,
    pub bold: bool,
}

#[derive(Debug, Clone, Default)]
pub struct Row {
    pub cells: Vec<Cell>,
}

#[derive(Debug, Clone, Default)]
pub struct ScreenUpdate {
    pub rows: Vec<Row>,
    pub cursor_r: i64,
    pub cursor_c: i64,
}

// ── Internal Screen State ────────────────────────────────────────────────────

struct Screen {
    cols: usize,
    rows: usize,
    grid: Vec<Vec<Cell>>,
    cursor_row: usize,
    cursor_col: usize,
    // SGR state
    fg_color: Option<String>,
    bg_color: Option<String>,
    bold: bool,
}

impl Screen {
    fn new(cols: usize, rows: usize) -> Self {
        let grid = (0..rows)
            .map(|_| (0..cols).map(|_| Cell::default()).collect())
            .collect();
        Self {
            cols,
            rows,
            grid,
            cursor_row: 0,
            cursor_col: 0,
            fg_color: None,
            bg_color: None,
            bold: false,
        }
    }

    fn snapshot(&self) -> ScreenUpdate {
        ScreenUpdate {
            rows: self
                .grid
                .iter()
                .map(|row| Row { cells: row.clone() })
                .collect(),
            cursor_r: self.cursor_row as i64,
            cursor_c: self.cursor_col as i64,
        }
    }

    fn put_char(&mut self, ch: char) {
        if self.cursor_row >= self.rows {
            return;
        }
        if self.cursor_col < self.cols {
            self.grid[self.cursor_row][self.cursor_col] = Cell {
                char: ch.to_string(),
                fg_color: self.fg_color.clone(),
                bg_color: self.bg_color.clone(),
                bold: self.bold,
            };
            self.cursor_col += 1;
        }
    }

    fn carriage_return(&mut self) {
        self.cursor_col = 0;
    }

    fn line_feed(&mut self) {
        if self.cursor_row + 1 >= self.rows {
            self.grid.remove(0);
            self.grid
                .push((0..self.cols).map(|_| Cell::default()).collect());
        } else {
            self.cursor_row += 1;
        }
    }

    fn backspace(&mut self) {
        if self.cursor_col > 0 {
            self.cursor_col -= 1;
        }
    }

    fn move_to(&mut self, row: usize, col: usize) {
        self.cursor_row = row.saturating_sub(1).min(self.rows - 1);
        self.cursor_col = col.saturating_sub(1).min(self.cols - 1);
    }

    fn erase_in_line(&mut self, mode: usize) {
        let row = self.cursor_row;
        match mode {
            0 => {
                for c in self.cursor_col..self.cols {
                    self.grid[row][c] = Cell::default();
                }
            }
            1 => {
                for c in 0..=self.cursor_col.min(self.cols - 1) {
                    self.grid[row][c] = Cell::default();
                }
            }
            _ => {
                for c in 0..self.cols {
                    self.grid[row][c] = Cell::default();
                }
            }
        }
    }

    fn erase_in_display(&mut self, mode: usize) {
        match mode {
            0 => {
                self.erase_in_line(0);
                for r in self.cursor_row + 1..self.rows {
                    for c in 0..self.cols {
                        self.grid[r][c] = Cell::default();
                    }
                }
            }
            1 => {
                for r in 0..self.cursor_row {
                    for c in 0..self.cols {
                        self.grid[r][c] = Cell::default();
                    }
                }
                self.erase_in_line(1);
            }
            _ => {
                for r in 0..self.rows {
                    for c in 0..self.cols {
                        self.grid[r][c] = Cell::default();
                    }
                }
            }
        }
    }

    fn apply_sgr(&mut self, params: &[u16]) {
        for &p in params {
            match p {
                0 => {
                    self.fg_color = None;
                    self.bg_color = None;
                    self.bold = false;
                }
                1 => self.bold = true,
                22 => self.bold = false,
                30..=37 => self.fg_color = Some(ansi_color_name(p - 30).to_string()),
                39 => self.fg_color = None,
                40..=47 => self.bg_color = Some(ansi_color_name(p - 40).to_string()),
                49 => self.bg_color = None,
                90..=97 => self.fg_color = Some(ansi_bright_color_name(p - 90).to_string()),
                100..=107 => self.bg_color = Some(ansi_bright_color_name(p - 100).to_string()),
                _ => {}
            }
        }
    }
}

fn ansi_color_name(idx: u16) -> &'static str {
    match idx {
        0 => "black",
        1 => "red",
        2 => "green",
        3 => "yellow",
        4 => "blue",
        5 => "magenta",
        6 => "cyan",
        _ => "white",
    }
}

fn ansi_bright_color_name(idx: u16) -> &'static str {
    match idx {
        0 => "bright_black",
        1 => "bright_red",
        2 => "bright_green",
        3 => "bright_yellow",
        4 => "bright_blue",
        5 => "bright_magenta",
        6 => "bright_cyan",
        _ => "bright_white",
    }
}

// ── VTE Performer ────────────────────────────────────────────────────────────

struct VtePerformer {
    screen: Arc<Mutex<Screen>>,
}

impl vte::Perform for VtePerformer {
    fn print(&mut self, c: char) {
        self.screen.lock().unwrap().put_char(c);
    }

    fn execute(&mut self, byte: u8) {
        let mut s = self.screen.lock().unwrap();
        match byte {
            0x0A => s.line_feed(),
            0x0D => s.carriage_return(),
            0x08 => s.backspace(),
            _ => {}
        }
    }

    fn csi_dispatch(
        &mut self,
        params: &vte::Params,
        _intermediates: &[u8],
        _ignore: bool,
        action: char,
    ) {
        let p: Vec<u16> = params.iter().map(|s| s[0]).collect();

        let mut s = self.screen.lock().unwrap();
        match action {
            'H' | 'f' => {
                let row = p.first().copied().unwrap_or(1) as usize;
                let col = p.get(1).copied().unwrap_or(1) as usize;
                s.move_to(row, col);
            }
            'A' => {
                let n = p.first().copied().unwrap_or(1) as usize;
                s.cursor_row = s.cursor_row.saturating_sub(n);
            }
            'B' => {
                let n = p.first().copied().unwrap_or(1) as usize;
                s.cursor_row = (s.cursor_row + n).min(s.rows - 1);
            }
            'C' => {
                let n = p.first().copied().unwrap_or(1) as usize;
                s.cursor_col = (s.cursor_col + n).min(s.cols - 1);
            }
            'D' => {
                let n = p.first().copied().unwrap_or(1) as usize;
                s.cursor_col = s.cursor_col.saturating_sub(n);
            }
            'J' => {
                let mode = p.first().copied().unwrap_or(0) as usize;
                s.erase_in_display(mode);
            }
            'K' => {
                let mode = p.first().copied().unwrap_or(0) as usize;
                s.erase_in_line(mode);
            }
            'm' => {
                if p.is_empty() {
                    s.apply_sgr(&[0]);
                } else {
                    s.apply_sgr(&p);
                }
            }
            _ => {}
        }
    }

    fn osc_dispatch(&mut self, _params: &[&[u8]], _bell_terminated: bool) {}
    fn hook(&mut self, _params: &vte::Params, _intermediates: &[u8], _ignore: bool, _action: char) {
    }
    fn put(&mut self, _byte: u8) {}
    fn unhook(&mut self) {}
    fn esc_dispatch(&mut self, _intermediates: &[u8], _ignore: bool, _byte: u8) {}
}

// ── TerminalSession (FRB opaque) ─────────────────────────────────────────────

#[frb(opaque)]
pub struct GooxTerminalSession {
    writer: Mutex<Box<dyn Write + Send>>,
    screen: Arc<Mutex<Screen>>,
}

impl GooxTerminalSession {
    /// Send raw keyboard input to the PTY
    pub fn send_input(&self, input: String) {
        let mut w = self.writer.lock().unwrap();
        let _ = w.write_all(input.as_bytes());
    }

    /// Return a snapshot of the current screen state
    pub fn poll_update(&self) -> ScreenUpdate {
        self.screen.lock().unwrap().snapshot()
    }
}

/// Create a new terminal session running the system shell.
pub fn create_terminal(cols: u16, rows: u16) -> Result<GooxTerminalSession, String> {
    let pty_system = native_pty_system();

    let pair = pty_system
        .openpty(PtySize {
            rows,
            cols,
            pixel_width: 0,
            pixel_height: 0,
        })
        .map_err(|e| e.to_string())?;

    // Take the writer from the master before moving master into the thread.
    let writer = pair.master.take_writer().map_err(|e| e.to_string())?;

    let shell = std::env::var("SHELL").unwrap_or_else(|_| "/bin/sh".to_string());
    let mut cmd = CommandBuilder::new(&shell);
    cmd.env("TERM", "xterm-256color");
    cmd.env("LANG", "en_US.UTF-8");

    pair.slave.spawn_command(cmd).map_err(|e| e.to_string())?;

    let screen = Arc::new(Mutex::new(Screen::new(cols as usize, rows as usize)));
    let screen_clone = screen.clone();

    let mut reader = pair.master.try_clone_reader().map_err(|e| e.to_string())?;

    thread::spawn(move || {
        let mut parser = vte::Parser::new();
        let mut performer = VtePerformer {
            screen: screen_clone,
        };
        let mut buf = [0u8; 4096];
        loop {
            match reader.read(&mut buf) {
                Ok(0) | Err(_) => break,
                Ok(n) => {
                    for &byte in &buf[..n] {
                        parser.advance(&mut performer, byte);
                    }
                }
            }
        }
    });

    Ok(GooxTerminalSession {
        writer: Mutex::new(writer),
        screen,
    })
}
