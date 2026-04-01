use portable_pty::{Child, ChildKiller, CommandBuilder, MasterPty, PtySize, native_pty_system};
use serde::Serialize;
use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::io::{Read, Write};
use std::os::raw::c_char;
use std::path::PathBuf;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::mpsc::{self, Receiver, Sender};
use std::sync::{Arc, LazyLock, Mutex};
use std::thread;
use std::time::Duration;

pub type TerminalId = u64;

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TerminalCellSnapshot {
    pub ch: String,
    pub fg: Option<u32>,
    pub bg: Option<u32>,
    pub bold: bool,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TerminalRowSnapshot {
    pub cells: Vec<TerminalCellSnapshot>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TerminalScreenSnapshot {
    pub terminal_id: TerminalId,
    pub generation: u64,
    pub rows: usize,
    pub cols: usize,
    pub cursor_x: usize,
    pub cursor_y: usize,
    pub is_alternate_screen: bool,
    pub cursor_visible: bool,
    pub exited: bool,
    pub exit_code: Option<u32>,
    pub exit_message: Option<String>,
    pub grid: Vec<TerminalRowSnapshot>,
}

#[derive(Debug, Clone)]
pub enum TerminalError {
    SessionNotFound(TerminalId),
    SessionExited(TerminalId),
    InputChannelClosed(TerminalId),
    SpawnFailed(String),
    PtyError(String),
    Serialization(String),
}

impl std::fmt::Display for TerminalError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TerminalError::SessionNotFound(id) => write!(f, "terminal session {id} not found"),
            TerminalError::SessionExited(id) => write!(f, "terminal session {id} has exited"),
            TerminalError::InputChannelClosed(id) => {
                write!(f, "terminal session {id} input channel is closed")
            }
            TerminalError::SpawnFailed(message) => {
                write!(f, "failed to spawn terminal: {message}")
            }
            TerminalError::PtyError(message) => write!(f, "pty error: {message}"),
            TerminalError::Serialization(message) => {
                write!(f, "snapshot serialization failed: {message}")
            }
        }
    }
}

impl std::error::Error for TerminalError {}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Cursor {
    x: usize,
    y: usize,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct Cell {
    ch: char,
    fg: Option<u32>,
    bg: Option<u32>,
    bold: bool,
}

impl Default for Cell {
    fn default() -> Self {
        Self {
            ch: ' ',
            fg: None,
            bg: None,
            bold: false,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ScreenKind {
    Main,
    Alternate,
}

#[derive(Debug, Clone)]
struct ScreenBuffer {
    cells: Vec<Vec<Cell>>,
    cursor: Cursor,
    saved_cursor: Option<Cursor>,
    scroll_top: usize,
    scroll_bottom: usize,
    cursor_visible: bool,
    fg: Option<u32>,
    bg: Option<u32>,
    bold: bool,
}

impl ScreenBuffer {
    fn new(rows: usize, cols: usize) -> Self {
        let rows = rows.max(1);
        let cols = cols.max(1);
        Self {
            cells: blank_grid(rows, cols),
            cursor: Cursor { x: 0, y: 0 },
            saved_cursor: None,
            scroll_top: 0,
            scroll_bottom: rows - 1,
            cursor_visible: true,
            fg: None,
            bg: None,
            bold: false,
        }
    }

    fn reset(&mut self, rows: usize, cols: usize) {
        *self = Self::new(rows, cols);
    }

    fn resize(&mut self, rows: usize, cols: usize) {
        let rows = rows.max(1);
        let cols = cols.max(1);
        let mut next = blank_grid(rows, cols);
        let copy_rows = self.cells.len().min(rows);
        let copy_cols = self
            .cells
            .first()
            .map(|row| row.len())
            .unwrap_or(0)
            .min(cols);

        for row in 0..copy_rows {
            for col in 0..copy_cols {
                next[row][col] = self.cells[row][col].clone();
            }
        }

        self.cells = next;
        self.cursor.x = self.cursor.x.min(cols - 1);
        self.cursor.y = self.cursor.y.min(rows - 1);
        self.scroll_top = self.scroll_top.min(rows - 1);
        self.scroll_bottom = self.scroll_bottom.min(rows - 1);
        if self.scroll_top > self.scroll_bottom {
            self.scroll_top = 0;
            self.scroll_bottom = rows - 1;
        }
    }

    fn rows(&self) -> usize {
        self.cells.len()
    }

    fn cols(&self) -> usize {
        self.cells.first().map(|row| row.len()).unwrap_or(1)
    }

    fn clamp_cursor(&mut self) {
        let max_x = self.cols().saturating_sub(1);
        let max_y = self.rows().saturating_sub(1);
        self.cursor.x = self.cursor.x.min(max_x);
        self.cursor.y = self.cursor.y.min(max_y);
    }

    fn save_cursor(&mut self) -> bool {
        self.saved_cursor = Some(self.cursor);
        true
    }

    fn restore_cursor(&mut self) -> bool {
        if let Some(saved) = self.saved_cursor {
            self.cursor = saved;
            self.clamp_cursor();
            return true;
        }
        false
    }

    fn set_cursor_visible(&mut self, visible: bool) -> bool {
        if self.cursor_visible == visible {
            return false;
        }
        self.cursor_visible = visible;
        true
    }

    fn set_scroll_region(&mut self, top: usize, bottom: usize) -> bool {
        let rows = self.rows();
        if rows == 0 {
            return false;
        }

        let top = top.min(rows - 1);
        let bottom = bottom.min(rows - 1);
        if top >= bottom {
            self.scroll_top = 0;
            self.scroll_bottom = rows - 1;
        } else {
            self.scroll_top = top;
            self.scroll_bottom = bottom;
        }

        self.cursor = Cursor {
            x: 0,
            y: self.scroll_top,
        };
        true
    }

    fn move_to(&mut self, row: usize, col: usize) -> bool {
        let next = Cursor {
            x: col.min(self.cols().saturating_sub(1)),
            y: row.min(self.rows().saturating_sub(1)),
        };
        if self.cursor == next {
            return false;
        }
        self.cursor = next;
        true
    }

    fn move_row(&mut self, delta: isize) -> bool {
        let max_y = self.rows().saturating_sub(1) as isize;
        let next = (self.cursor.y as isize + delta).clamp(0, max_y) as usize;
        if next == self.cursor.y {
            return false;
        }
        self.cursor.y = next;
        true
    }

    fn move_col(&mut self, delta: isize) -> bool {
        let max_x = self.cols().saturating_sub(1) as isize;
        let next = (self.cursor.x as isize + delta).clamp(0, max_x) as usize;
        if next == self.cursor.x {
            return false;
        }
        self.cursor.x = next;
        true
    }

    fn move_to_column(&mut self, col: usize) -> bool {
        let next = col.saturating_sub(1).min(self.cols().saturating_sub(1));
        if next == self.cursor.x {
            return false;
        }
        self.cursor.x = next;
        true
    }

    fn line_feed(&mut self) -> bool {
        if self.cursor.y == self.scroll_bottom {
            return self.scroll_up(1);
        }

        let next = (self.cursor.y + 1).min(self.rows().saturating_sub(1));
        if next == self.cursor.y {
            return false;
        }
        self.cursor.y = next;
        true
    }

    fn reverse_index(&mut self) -> bool {
        if self.cursor.y == self.scroll_top {
            return self.scroll_down(1);
        }

        if self.cursor.y == 0 {
            return false;
        }
        self.cursor.y -= 1;
        true
    }

    fn carriage_return(&mut self) -> bool {
        if self.cursor.x == 0 {
            return false;
        }
        self.cursor.x = 0;
        true
    }

    fn backspace(&mut self) -> bool {
        if self.cursor.x == 0 {
            return false;
        }
        self.cursor.x -= 1;
        true
    }

    fn tab(&mut self) -> bool {
        let next = ((self.cursor.x / 8) + 1) * 8;
        let max_x = self.cols().saturating_sub(1);
        let next = next.min(max_x);
        if next == self.cursor.x {
            return false;
        }
        self.cursor.x = next;
        true
    }

    fn put_char(&mut self, ch: char) -> bool {
        if self.cursor.y >= self.rows() || self.cursor.x >= self.cols() {
            return false;
        }

        let row = &mut self.cells[self.cursor.y];
        row[self.cursor.x] = Cell {
            ch,
            fg: self.fg,
            bg: self.bg,
            bold: self.bold,
        };

        if self.cursor.x + 1 >= self.cols() {
            self.cursor.x = 0;
            let _ = self.line_feed();
        } else {
            self.cursor.x += 1;
        }

        true
    }

    fn clear_line(&mut self, mode: usize) -> bool {
        let row = self.cursor.y;
        if row >= self.rows() {
            return false;
        }

        let mut changed = false;
        match mode {
            0 => {
                for col in self.cursor.x..self.cols() {
                    self.cells[row][col] = Cell::default();
                    changed = true;
                }
            }
            1 => {
                let end = self.cursor.x.min(self.cols() - 1);
                for col in 0..=end {
                    self.cells[row][col] = Cell::default();
                    changed = true;
                }
            }
            _ => {
                for col in 0..self.cols() {
                    self.cells[row][col] = Cell::default();
                    changed = true;
                }
            }
        }
        changed
    }

    fn clear_display(&mut self, mode: usize) -> bool {
        let mut changed = false;
        match mode {
            0 => {
                changed |= self.clear_line(0);
                for row in self.cursor.y + 1..self.rows() {
                    for col in 0..self.cols() {
                        self.cells[row][col] = Cell::default();
                        changed = true;
                    }
                }
            }
            1 => {
                for row in 0..self.cursor.y {
                    for col in 0..self.cols() {
                        self.cells[row][col] = Cell::default();
                        changed = true;
                    }
                }
                changed |= self.clear_line(1);
            }
            _ => {
                for row in 0..self.rows() {
                    for col in 0..self.cols() {
                        self.cells[row][col] = Cell::default();
                        changed = true;
                    }
                }
            }
        }
        changed
    }

    fn insert_lines(&mut self, count: usize) -> bool {
        if self.cursor.y < self.scroll_top || self.cursor.y > self.scroll_bottom {
            return false;
        }

        let count = count.max(1).min(self.scroll_bottom - self.scroll_top + 1);
        for _ in 0..count {
            self.cells.insert(self.cursor.y, blank_row(self.cols()));
            self.cells.remove(self.scroll_bottom + 1);
        }
        true
    }

    fn delete_lines(&mut self, count: usize) -> bool {
        if self.cursor.y < self.scroll_top || self.cursor.y > self.scroll_bottom {
            return false;
        }

        let count = count.max(1).min(self.scroll_bottom - self.scroll_top + 1);
        for _ in 0..count {
            self.cells.remove(self.cursor.y);
            self.cells
                .insert(self.scroll_bottom, blank_row(self.cols()));
        }
        true
    }

    fn insert_chars(&mut self, count: usize) -> bool {
        if self.cursor.y >= self.rows() || self.cursor.x >= self.cols() {
            return false;
        }

        let count = count.max(1).min(self.cols() - self.cursor.x);
        let row = &mut self.cells[self.cursor.y];
        for _ in 0..count {
            row.insert(self.cursor.x, Cell::default());
            row.pop();
        }
        true
    }

    fn delete_chars(&mut self, count: usize) -> bool {
        if self.cursor.y >= self.rows() || self.cursor.x >= self.cols() {
            return false;
        }

        let count = count.max(1).min(self.cols() - self.cursor.x);
        let row = &mut self.cells[self.cursor.y];
        for _ in 0..count {
            row.remove(self.cursor.x);
            row.push(Cell::default());
        }
        true
    }

    fn erase_chars(&mut self, count: usize) -> bool {
        if self.cursor.y >= self.rows() || self.cursor.x >= self.cols() {
            return false;
        }

        let count = count.max(1).min(self.cols() - self.cursor.x);
        let row = &mut self.cells[self.cursor.y];
        for col in self.cursor.x..self.cursor.x + count {
            row[col] = Cell::default();
        }
        true
    }

    fn scroll_up(&mut self, count: usize) -> bool {
        let span = self.scroll_bottom.saturating_sub(self.scroll_top) + 1;
        if span == 0 {
            return false;
        }

        let count = count.max(1).min(span);
        for _ in 0..count {
            self.cells.remove(self.scroll_top);
            self.cells
                .insert(self.scroll_bottom, blank_row(self.cols()));
        }
        true
    }

    fn scroll_down(&mut self, count: usize) -> bool {
        let span = self.scroll_bottom.saturating_sub(self.scroll_top) + 1;
        if span == 0 {
            return false;
        }

        let count = count.max(1).min(span);
        for _ in 0..count {
            self.cells.remove(self.scroll_bottom);
            self.cells.insert(self.scroll_top, blank_row(self.cols()));
        }
        true
    }

    fn apply_sgr(&mut self, params: &[usize]) -> bool {
        let mut changed = false;
        if params.is_empty() {
            return self.reset_sgr();
        }

        for &param in params {
            match param {
                0 => changed |= self.reset_sgr(),
                1 => {
                    if !self.bold {
                        self.bold = true;
                        changed = true;
                    }
                }
                22 => {
                    if self.bold {
                        self.bold = false;
                        changed = true;
                    }
                }
                30..=37 => {
                    let next = Some(ansi_color_value(param - 30, false));
                    if self.fg != next {
                        self.fg = next;
                        changed = true;
                    }
                }
                39 => {
                    if self.fg.is_some() {
                        self.fg = None;
                        changed = true;
                    }
                }
                40..=47 => {
                    let next = Some(ansi_color_value(param - 40, false));
                    if self.bg != next {
                        self.bg = next;
                        changed = true;
                    }
                }
                49 => {
                    if self.bg.is_some() {
                        self.bg = None;
                        changed = true;
                    }
                }
                90..=97 => {
                    let next = Some(ansi_color_value(param - 90, true));
                    if self.fg != next {
                        self.fg = next;
                        changed = true;
                    }
                }
                100..=107 => {
                    let next = Some(ansi_color_value(param - 100, true));
                    if self.bg != next {
                        self.bg = next;
                        changed = true;
                    }
                }
                _ => {}
            }
        }

        changed
    }

    fn reset_sgr(&mut self) -> bool {
        let mut changed = false;
        if self.fg.is_some() {
            self.fg = None;
            changed = true;
        }
        if self.bg.is_some() {
            self.bg = None;
            changed = true;
        }
        if self.bold {
            self.bold = false;
            changed = true;
        }
        changed
    }
}

#[derive(Debug, Clone)]
struct ScreenState {
    rows: usize,
    cols: usize,
    main: ScreenBuffer,
    alternate: ScreenBuffer,
    active: ScreenKind,
    saved_main_cursor: Option<Cursor>,
    generation: u64,
    exited: bool,
    exit_code: Option<u32>,
    exit_message: Option<String>,
}

impl ScreenState {
    fn new(rows: usize, cols: usize) -> Self {
        let rows = rows.max(1);
        let cols = cols.max(1);
        Self {
            rows,
            cols,
            main: ScreenBuffer::new(rows, cols),
            alternate: ScreenBuffer::new(rows, cols),
            active: ScreenKind::Main,
            saved_main_cursor: None,
            generation: 0,
            exited: false,
            exit_code: None,
            exit_message: None,
        }
    }

    fn is_exited(&self) -> bool {
        self.exited
    }

    fn touch(&mut self) {
        self.generation = self.generation.wrapping_add(1);
    }

    fn active_buffer(&self) -> &ScreenBuffer {
        match self.active {
            ScreenKind::Main => &self.main,
            ScreenKind::Alternate => &self.alternate,
        }
    }

    fn active_buffer_mut(&mut self) -> &mut ScreenBuffer {
        match self.active {
            ScreenKind::Main => &mut self.main,
            ScreenKind::Alternate => &mut self.alternate,
        }
    }

    fn resize(&mut self, rows: usize, cols: usize) -> bool {
        let rows = rows.max(1);
        let cols = cols.max(1);
        self.rows = rows;
        self.cols = cols;
        self.main.resize(rows, cols);
        self.alternate.resize(rows, cols);
        self.main.scroll_top = 0;
        self.main.scroll_bottom = rows - 1;
        self.alternate.scroll_top = 0;
        self.alternate.scroll_bottom = rows - 1;
        self.main.clamp_cursor();
        self.alternate.clamp_cursor();
        if let Some(saved) = self.saved_main_cursor.as_mut() {
            saved.x = saved.x.min(cols - 1);
            saved.y = saved.y.min(rows - 1);
        }
        self.touch();
        true
    }

    fn set_exit(&mut self, exit_code: Option<u32>, message: String) -> bool {
        if self.exited
            && self.exit_code == exit_code
            && self.exit_message.as_deref() == Some(message.as_str())
        {
            return false;
        }
        self.exited = true;
        self.exit_code = exit_code;
        self.exit_message = Some(message);
        self.touch();
        true
    }

    fn print_char(&mut self, ch: char) -> bool {
        let changed = self.active_buffer_mut().put_char(ch);
        if changed {
            self.touch();
        }
        changed
    }

    fn execute(&mut self, byte: u8) -> bool {
        let changed = match byte {
            0x0A => self.active_buffer_mut().line_feed(),
            0x0D => self.active_buffer_mut().carriage_return(),
            0x08 => self.active_buffer_mut().backspace(),
            0x09 => self.active_buffer_mut().tab(),
            _ => false,
        };
        if changed {
            self.touch();
        }
        changed
    }

    fn esc_dispatch(&mut self, byte: u8) -> bool {
        let changed = match byte as char {
            '7' => self.active_buffer_mut().save_cursor(),
            '8' => self.active_buffer_mut().restore_cursor(),
            'D' => self.active_buffer_mut().line_feed(),
            'E' => {
                let mut inner = self.active_buffer_mut().carriage_return();
                inner |= self.active_buffer_mut().line_feed();
                inner
            }
            'M' => self.active_buffer_mut().reverse_index(),
            'c' => {
                self.main.reset(self.rows, self.cols);
                self.alternate.reset(self.rows, self.cols);
                self.active = ScreenKind::Main;
                self.saved_main_cursor = None;
                true
            }
            _ => false,
        };
        if changed {
            self.touch();
        }
        changed
    }

    fn csi_dispatch(&mut self, params: &vte::Params, intermediates: &[u8], action: char) -> bool {
        let values: Vec<usize> = params
            .iter()
            .map(|param| param.first().copied().unwrap_or(0) as usize)
            .collect();
        let private_mode = intermediates.first() == Some(&b'?');

        let changed = if private_mode {
            self.handle_private_mode(action, &values)
        } else {
            self.handle_csi(action, &values)
        };

        if changed {
            self.touch();
        }
        changed
    }

    fn handle_private_mode(&mut self, action: char, values: &[usize]) -> bool {
        let mut changed = false;
        for &value in values {
            match (action, value) {
                ('h', 25) => changed |= self.active_buffer_mut().set_cursor_visible(true),
                ('l', 25) => changed |= self.active_buffer_mut().set_cursor_visible(false),
                ('h', 47) | ('h', 1047) | ('h', 1049) => changed |= self.enter_alternate_screen(),
                ('l', 47) | ('l', 1047) | ('l', 1049) => changed |= self.leave_alternate_screen(),
                _ => {}
            }
        }
        changed
    }

    fn handle_csi(&mut self, action: char, values: &[usize]) -> bool {
        let rows = self.rows;
        let buffer = self.active_buffer_mut();
        match action {
            'H' | 'f' => {
                let row = values.first().copied().unwrap_or(1).saturating_sub(1);
                let col = values.get(1).copied().unwrap_or(1).saturating_sub(1);
                buffer.move_to(row, col)
            }
            'A' => buffer.move_row(-(values.first().copied().unwrap_or(1) as isize)),
            'B' => buffer.move_row(values.first().copied().unwrap_or(1) as isize),
            'C' => buffer.move_col(values.first().copied().unwrap_or(1) as isize),
            'D' => buffer.move_col(-(values.first().copied().unwrap_or(1) as isize)),
            'E' => {
                let count = values.first().copied().unwrap_or(1);
                let mut changed = false;
                for _ in 0..count.max(1) {
                    changed |= buffer.carriage_return();
                    changed |= buffer.line_feed();
                }
                changed
            }
            'F' => {
                let count = values.first().copied().unwrap_or(1);
                let mut changed = false;
                for _ in 0..count.max(1) {
                    changed |= buffer.carriage_return();
                    changed |= buffer.move_row(-1);
                }
                changed
            }
            'G' => buffer.move_to_column(values.first().copied().unwrap_or(1)),
            'd' => {
                let row = values.first().copied().unwrap_or(1).saturating_sub(1);
                let col = buffer.cursor.x;
                buffer.move_to(row, col)
            }
            'J' => buffer.clear_display(values.first().copied().unwrap_or(0)),
            'K' => buffer.clear_line(values.first().copied().unwrap_or(0)),
            'L' => buffer.insert_lines(values.first().copied().unwrap_or(1)),
            'M' => buffer.delete_lines(values.first().copied().unwrap_or(1)),
            '@' => buffer.insert_chars(values.first().copied().unwrap_or(1)),
            'P' => buffer.delete_chars(values.first().copied().unwrap_or(1)),
            'X' => buffer.erase_chars(values.first().copied().unwrap_or(1)),
            'S' => buffer.scroll_up(values.first().copied().unwrap_or(1)),
            'T' => buffer.scroll_down(values.first().copied().unwrap_or(1)),
            'r' => {
                let top = values.first().copied().unwrap_or(1).saturating_sub(1);
                let bottom = values.get(1).copied().unwrap_or(rows).saturating_sub(1);
                buffer.set_scroll_region(top, bottom)
            }
            's' => buffer.save_cursor(),
            'u' => buffer.restore_cursor(),
            'm' => buffer.apply_sgr(&values),
            _ => false,
        }
    }

    fn enter_alternate_screen(&mut self) -> bool {
        if self.active == ScreenKind::Alternate {
            return false;
        }

        self.saved_main_cursor = Some(self.main.cursor);
        self.alternate.reset(self.rows, self.cols);
        self.active = ScreenKind::Alternate;
        true
    }

    fn leave_alternate_screen(&mut self) -> bool {
        if self.active == ScreenKind::Main {
            return false;
        }

        self.active = ScreenKind::Main;
        if let Some(saved) = self.saved_main_cursor.take() {
            self.main.cursor = saved;
            self.main.clamp_cursor();
        }
        true
    }

    fn snapshot(&self, terminal_id: TerminalId) -> TerminalScreenSnapshot {
        let buffer = self.active_buffer();
        let grid = buffer
            .cells
            .iter()
            .map(|row| TerminalRowSnapshot {
                cells: row
                    .iter()
                    .map(|cell| TerminalCellSnapshot {
                        ch: cell.ch.to_string(),
                        fg: cell.fg,
                        bg: cell.bg,
                        bold: cell.bold,
                    })
                    .collect(),
            })
            .collect();

        TerminalScreenSnapshot {
            terminal_id,
            generation: self.generation,
            rows: self.rows,
            cols: self.cols,
            cursor_x: buffer.cursor.x,
            cursor_y: buffer.cursor.y,
            is_alternate_screen: self.active == ScreenKind::Alternate,
            cursor_visible: buffer.cursor_visible,
            exited: self.exited,
            exit_code: self.exit_code,
            exit_message: self.exit_message.clone(),
            grid,
        }
    }
}

struct TerminalSession {
    id: TerminalId,
    master: Arc<Mutex<Box<dyn MasterPty + Send>>>,
    input_tx: Sender<Vec<u8>>,
    screen: Arc<Mutex<ScreenState>>,
    child_killer: Arc<Mutex<Option<Box<dyn ChildKiller + Send + Sync>>>>,
}

impl TerminalSession {
    fn spawn(
        id: TerminalId,
        rows: u16,
        cols: u16,
        working_directory: Option<PathBuf>,
    ) -> Result<Arc<Self>, TerminalError> {
        let rows = rows.max(1);
        let cols = cols.max(1);
        let size = PtySize {
            rows,
            cols,
            pixel_width: 0,
            pixel_height: 0,
        };

        let mut last_error: Option<String> = None;
        for shell in shell_candidates() {
            let pty_system = native_pty_system();
            let mut pair = pty_system
                .openpty(size)
                .map_err(|error| TerminalError::PtyError(error.to_string()))?;

            let mut command = CommandBuilder::new(&shell);
            command.env("TERM", "xterm-256color");
            command.env("LANG", "en_US.UTF-8");
            if let Some(ref cwd) = working_directory {
                command.cwd(cwd);
            }

            match pair.slave.spawn_command(command) {
                Ok(child) => {
                    let master = pair.master;
                    let reader = master
                        .try_clone_reader()
                        .map_err(|error| TerminalError::PtyError(error.to_string()))?;
                    let writer = master
                        .take_writer()
                        .map_err(|error| TerminalError::PtyError(error.to_string()))?;
                    let master = Arc::new(Mutex::new(master));
                    let screen =
                        Arc::new(Mutex::new(ScreenState::new(rows as usize, cols as usize)));
                    let (input_tx, input_rx) = mpsc::channel::<Vec<u8>>();
                    let child_killer = Arc::new(Mutex::new(Some(child.clone_killer())));

                    spawn_reader_thread(id, reader, Arc::clone(&screen), Arc::clone(&child_killer));
                    spawn_writer_thread(
                        id,
                        writer,
                        input_rx,
                        Arc::clone(&screen),
                        Arc::clone(&child_killer),
                    );
                    spawn_wait_thread(id, child, Arc::clone(&screen));

                    return Ok(Arc::new(Self {
                        id,
                        master,
                        input_tx,
                        screen,
                        child_killer,
                    }));
                }
                Err(error) => {
                    last_error = Some(error.to_string());
                }
            }
        }

        Err(TerminalError::SpawnFailed(
            last_error.unwrap_or_else(|| "unable to spawn any shell".to_string()),
        ))
    }

    fn send_input(&self, bytes: &[u8]) -> Result<(), TerminalError> {
        if self.screen.lock().unwrap().is_exited() {
            return Err(TerminalError::SessionExited(self.id));
        }

        self.input_tx
            .send(bytes.to_vec())
            .map_err(|_| TerminalError::InputChannelClosed(self.id))
    }

    fn poll_screen(&self) -> TerminalScreenSnapshot {
        self.screen.lock().unwrap().snapshot(self.id)
    }

    fn resize(&self, rows: u16, cols: u16) -> Result<(), TerminalError> {
        let rows = rows.max(1);
        let cols = cols.max(1);
        {
            let master = self.master.lock().unwrap();
            master
                .resize(PtySize {
                    rows,
                    cols,
                    pixel_width: 0,
                    pixel_height: 0,
                })
                .map_err(|error| TerminalError::PtyError(error.to_string()))?;
        }

        let mut screen = self.screen.lock().unwrap();
        screen.resize(rows as usize, cols as usize);
        Ok(())
    }

    fn dispose(&self) {
        if let Some(killer) = self.child_killer.lock().unwrap().as_mut() {
            let _ = killer.kill();
        }
        let mut screen = self.screen.lock().unwrap();
        let exit_code = screen.exit_code;
        let _ = screen.set_exit(exit_code, "terminal disposed".to_string());
    }
}

fn spawn_reader_thread(
    id: TerminalId,
    mut reader: Box<dyn Read + Send>,
    screen: Arc<Mutex<ScreenState>>,
    child_killer: Arc<Mutex<Option<Box<dyn ChildKiller + Send + Sync>>>>,
) {
    thread::spawn(move || {
        let mut parser = vte::Parser::new();
        let mut performer = TerminalPerformer {
            terminal_id: id,
            screen: Arc::clone(&screen),
        };
        let mut buf = [0u8; 4096];
        loop {
            match reader.read(&mut buf) {
                Ok(0) => {
                    let mut screen = screen.lock().unwrap();
                    let _ = screen.set_exit(None, "pty reader closed".to_string());
                    break;
                }
                Ok(count) => {
                    for &byte in &buf[..count] {
                        parser.advance(&mut performer, byte);
                    }
                }
                Err(error) => {
                    let mut screen = screen.lock().unwrap();
                    let _ = screen.set_exit(None, format!("pty read error: {error}"));
                    if let Some(killer) = child_killer.lock().unwrap().as_mut() {
                        let _ = killer.kill();
                    }
                    break;
                }
            }
        }
    });
}

fn spawn_writer_thread(
    id: TerminalId,
    mut writer: Box<dyn Write + Send>,
    input_rx: Receiver<Vec<u8>>,
    screen: Arc<Mutex<ScreenState>>,
    child_killer: Arc<Mutex<Option<Box<dyn ChildKiller + Send + Sync>>>>,
) {
    thread::spawn(move || {
        loop {
            if screen.lock().unwrap().is_exited() {
                break;
            }

            match input_rx.recv_timeout(Duration::from_millis(50)) {
                Ok(bytes) => {
                    if bytes.is_empty() {
                        continue;
                    }

                    if let Err(error) = writer.write_all(&bytes).and_then(|_| writer.flush()) {
                        let mut screen = screen.lock().unwrap();
                        let _ = screen.set_exit(None, format!("pty write error: {error}"));
                        if let Some(killer) = child_killer.lock().unwrap().as_mut() {
                            let _ = killer.kill();
                        }
                        break;
                    }
                }
                Err(mpsc::RecvTimeoutError::Timeout) => {}
                Err(mpsc::RecvTimeoutError::Disconnected) => {
                    let mut screen = screen.lock().unwrap();
                    let _ = screen.set_exit(None, format!("terminal input channel closed ({id})"));
                    break;
                }
            }
        }
    });
}

fn spawn_wait_thread(
    id: TerminalId,
    mut child: Box<dyn Child + Send + Sync>,
    screen: Arc<Mutex<ScreenState>>,
) {
    thread::spawn(move || match child.wait() {
        Ok(status) => {
            let mut screen = screen.lock().unwrap();
            let _ = screen.set_exit(Some(status.exit_code()), status.to_string());
        }
        Err(error) => {
            let mut screen = screen.lock().unwrap();
            let _ = screen.set_exit(None, format!("terminal wait error ({id}): {error}"));
        }
    });
}

struct TerminalPerformer {
    terminal_id: TerminalId,
    screen: Arc<Mutex<ScreenState>>,
}

impl vte::Perform for TerminalPerformer {
    fn print(&mut self, c: char) {
        let mut screen = self.screen.lock().unwrap();
        let _ = screen.print_char(c);
    }

    fn execute(&mut self, byte: u8) {
        let mut screen = self.screen.lock().unwrap();
        let _ = screen.execute(byte);
    }

    fn csi_dispatch(
        &mut self,
        params: &vte::Params,
        intermediates: &[u8],
        _ignore: bool,
        action: char,
    ) {
        let mut screen = self.screen.lock().unwrap();
        let _ = screen.csi_dispatch(params, intermediates, action);
    }

    fn osc_dispatch(&mut self, _params: &[&[u8]], _bell_terminated: bool) {}

    fn hook(&mut self, _params: &vte::Params, _intermediates: &[u8], _ignore: bool, _action: char) {
    }

    fn put(&mut self, _byte: u8) {}

    fn unhook(&mut self) {}

    fn esc_dispatch(&mut self, _intermediates: &[u8], _ignore: bool, byte: u8) {
        let mut screen = self.screen.lock().unwrap();
        let _ = screen.esc_dispatch(byte);
    }
}

static NEXT_TERMINAL_ID: AtomicU64 = AtomicU64::new(1);
static TERMINALS: LazyLock<Mutex<HashMap<TerminalId, Arc<TerminalSession>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

pub fn create_terminal(
    rows: u16,
    cols: u16,
    working_directory: Option<String>,
) -> Result<TerminalId, TerminalError> {
    let id = NEXT_TERMINAL_ID.fetch_add(1, Ordering::Relaxed);
    let working_directory = working_directory.map(PathBuf::from);
    let session = TerminalSession::spawn(id, rows, cols, working_directory)?;
    TERMINALS.lock().unwrap().insert(id, session);
    Ok(id)
}

pub fn send_input(id: TerminalId, bytes: Vec<u8>) -> Result<(), TerminalError> {
    let session = get_session(id)?;
    session.send_input(&bytes)
}

pub fn poll_screen(id: TerminalId) -> Result<TerminalScreenSnapshot, TerminalError> {
    let session = get_session(id)?;
    Ok(session.poll_screen())
}

pub fn resize_terminal(id: TerminalId, rows: u16, cols: u16) -> Result<(), TerminalError> {
    let session = get_session(id)?;
    session.resize(rows, cols)
}

pub fn dispose_terminal(id: TerminalId) {
    let session = TERMINALS.lock().unwrap().remove(&id);
    if let Some(session) = session {
        session.dispose();
    }
}

pub fn terminal_exists(id: TerminalId) -> bool {
    TERMINALS.lock().unwrap().contains_key(&id)
}

pub fn terminal_snapshot_json(id: TerminalId) -> Result<String, TerminalError> {
    let snapshot = poll_screen(id)?;
    serde_json::to_string(&snapshot)
        .map_err(|error| TerminalError::Serialization(error.to_string()))
}

fn get_session(id: TerminalId) -> Result<Arc<TerminalSession>, TerminalError> {
    TERMINALS
        .lock()
        .unwrap()
        .get(&id)
        .cloned()
        .ok_or(TerminalError::SessionNotFound(id))
}

#[unsafe(no_mangle)]
pub extern "C" fn goox_terminal_create(
    rows: u16,
    cols: u16,
    working_directory: *const c_char,
) -> u64 {
    let working_directory = unsafe { c_string_ptr_to_option_string(working_directory) };
    match create_terminal(rows, cols, working_directory) {
        Ok(id) => id,
        Err(error) => {
            eprintln!("[goox-terminal] create failed: {error}");
            0
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn goox_terminal_send_input(id: u64, bytes_ptr: *const u8, len: usize) -> bool {
    if bytes_ptr.is_null() || len == 0 {
        return true;
    }

    let bytes = unsafe { std::slice::from_raw_parts(bytes_ptr, len) }.to_vec();
    match send_input(id, bytes) {
        Ok(()) => true,
        Err(error) => {
            eprintln!("[goox-terminal] send_input failed: {error}");
            false
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn goox_terminal_poll_screen_json(id: u64) -> *mut c_char {
    match terminal_snapshot_json(id) {
        Ok(json) => match CString::new(json) {
            Ok(c_string) => c_string.into_raw(),
            Err(error) => {
                eprintln!("[goox-terminal] snapshot CString failed: {error}");
                std::ptr::null_mut()
            }
        },
        Err(error) => {
            eprintln!("[goox-terminal] poll_screen failed: {error}");
            std::ptr::null_mut()
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn goox_terminal_resize(id: u64, rows: u16, cols: u16) -> bool {
    match resize_terminal(id, rows, cols) {
        Ok(()) => true,
        Err(error) => {
            eprintln!("[goox-terminal] resize failed: {error}");
            false
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn goox_terminal_dispose(id: u64) {
    dispose_terminal(id);
}

#[unsafe(no_mangle)]
pub extern "C" fn goox_terminal_free_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }

    unsafe {
        let _ = CString::from_raw(ptr);
    }
}

fn shell_candidates() -> Vec<String> {
    let mut candidates = Vec::new();
    if let Ok(shell) = std::env::var("SHELL") {
        if !shell.trim().is_empty() {
            candidates.push(shell);
        }
    }

    if cfg!(windows) {
        candidates.extend([
            "powershell.exe".to_string(),
            "pwsh.exe".to_string(),
            "cmd.exe".to_string(),
        ]);
    } else {
        candidates.extend(["bash".to_string(), "zsh".to_string(), "/bin/sh".to_string()]);
    }

    candidates
}

fn blank_grid(rows: usize, cols: usize) -> Vec<Vec<Cell>> {
    (0..rows)
        .map(|_| (0..cols).map(|_| Cell::default()).collect())
        .collect()
}

fn blank_row(cols: usize) -> Vec<Cell> {
    (0..cols).map(|_| Cell::default()).collect()
}

fn ansi_color_value(index: usize, bright: bool) -> u32 {
    let colors = if bright {
        [
            0xFF666666, 0xFFFF5555, 0xFF55FF55, 0xFFFFFF55, 0xFF5555FF, 0xFFFF55FF, 0xFF55FFFF,
            0xFFFFFFFF,
        ]
    } else {
        [
            0xFF000000, 0xFFCC0000, 0xFF00CC00, 0xFFCCCC00, 0xFF0000CC, 0xFFCC00CC, 0xFF00CCCC,
            0xFFCCCCCC,
        ]
    };
    colors[index.min(7)]
}

unsafe fn c_string_ptr_to_option_string(ptr: *const c_char) -> Option<String> {
    if ptr.is_null() {
        return None;
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    let value = c_str.to_string_lossy().trim().to_string();
    if value.is_empty() { None } else { Some(value) }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn creates_blank_snapshot() {
        let screen = ScreenState::new(3, 5);
        let snapshot = screen.snapshot(7);
        assert_eq!(snapshot.terminal_id, 7);
        assert_eq!(snapshot.rows, 3);
        assert_eq!(snapshot.cols, 5);
        assert_eq!(snapshot.grid.len(), 3);
        assert_eq!(snapshot.grid[0].cells.len(), 5);
        assert!(!snapshot.exited);
    }
}
