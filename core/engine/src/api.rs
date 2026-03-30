use crate::{
    BufferError, BufferPatchBatch, BufferSnapshot, BufferTransaction, EditorBuffer,
    ViewportRequest, ViewportSnapshot,
};
pub struct CursorPos {
    pub line: usize,
    pub column: usize,
}
use flutter_rust_bridge::frb;
use std::sync::{LazyLock, Mutex};

static BUFFER: LazyLock<Mutex<EditorBuffer>> = LazyLock::new(|| Mutex::new(EditorBuffer::new("")));

#[frb(init)]
pub fn init_app() {
    // Default setup
}

pub fn seed_document(text: String) {
    let mut buffer = BUFFER.lock().unwrap();
    *buffer = EditorBuffer::new(&text);
}

pub fn get_snapshot() -> BufferSnapshot {
    BUFFER.lock().unwrap().snapshot()
}

pub fn apply_transaction(transaction: BufferTransaction) -> Result<BufferPatchBatch, BufferError> {
    BUFFER.lock().unwrap().apply_transaction(transaction)
}

pub fn undo() -> Result<BufferPatchBatch, BufferError> {
    BUFFER.lock().unwrap().undo()
}

pub fn redo() -> Result<BufferPatchBatch, BufferError> {
    BUFFER.lock().unwrap().redo()
}

pub fn get_viewport(request: ViewportRequest) -> ViewportSnapshot {
    BUFFER.lock().unwrap().viewport(request)
}

pub fn get_cursor_position(char_index: usize) -> CursorPos {
    let (line, column) = BUFFER.lock().unwrap().char_to_line_column(char_index);
    CursorPos {
        line: line + 1,
        column: column + 1,
    }
}

pub fn delete_line(char_index: usize) -> Result<BufferPatchBatch, BufferError> {
    let mut buffer = BUFFER.lock().unwrap();
    let (line_index, _) = buffer.char_to_line_column(char_index);
    if let Some((start, end)) = buffer.line_range(line_index) {
        let transaction = crate::BufferTransaction {
            operations: vec![crate::BufferOperation::Delete { start, end }],
            mergeable: false,
            label: "delete line".to_string(),
        };
        buffer.apply_transaction(transaction)
    } else {
        Err(crate::BufferError::EmptyTransaction)
    }
}

pub fn refresh_workspace_extensions(workspace_root: String) -> usize {
    crate::extensions::refresh_workspace_extensions(workspace_root)
}

pub fn activate_extension_for_file(workspace_root: String, file_path: String) -> bool {
    crate::extensions::activate_extension_for_file(workspace_root, file_path)
}

pub fn extension_for_file(
    workspace_root: String,
    file_path: String,
) -> Option<crate::extensions::ExtensionInfo> {
    crate::extensions::extension_for_file(workspace_root, file_path)
}

pub fn erp_open_session(workspace_root: String, file_path: String) -> Result<u32, String> {
    crate::erp::open_session(workspace_root, file_path)
}

pub fn erp_get_page_count(session_id: u32) -> Result<i32, String> {
    crate::erp::get_page_count(session_id)
}

pub fn erp_render_page(
    session_id: u32,
    page_index: i32,
    width: i32,
    height: i32,
) -> Result<Vec<u8>, String> {
    crate::erp::render_page(session_id, page_index, width, height)
}

pub fn erp_close_session(session_id: u32) -> Result<(), String> {
    crate::erp::close_session(session_id)
}

pub fn validate_source_text(language_id: String, text: String) -> Option<String> {
    crate::extensions::validate_source_text(language_id, text)
}

pub fn registered_extension_commands() -> Vec<String> {
    crate::extensions::registered_extension_commands()
}

pub fn sync_language_server(
    workspace_root: Option<String>,
    file_path: Option<String>,
    language_id: Option<String>,
    lsp_executable: Option<String>,
    text: String,
) -> bool {
    crate::lsp::sync_language_server(
        workspace_root,
        file_path,
        language_id,
        lsp_executable,
        text,
    )
}

pub fn poll_language_server() -> crate::lsp::LanguageServerSnapshot {
    crate::lsp::poll_language_server()
}

pub fn shutdown_language_server() {
    crate::lsp::shutdown_language_server();
}

pub type TerminalId = crate::terminal::TerminalId;

pub fn create_terminal(
    rows: u16,
    cols: u16,
    working_directory: Option<String>,
) -> Result<TerminalId, crate::terminal::TerminalError> {
    crate::terminal::create_terminal(rows, cols, working_directory)
}

pub fn send_terminal_input(
    id: TerminalId,
    bytes: Vec<u8>,
) -> Result<(), crate::terminal::TerminalError> {
    crate::terminal::send_input(id, bytes)
}

pub fn poll_terminal_screen(
    id: TerminalId,
) -> Result<crate::terminal::TerminalScreenSnapshot, crate::terminal::TerminalError> {
    crate::terminal::poll_screen(id)
}

pub fn resize_terminal(
    id: TerminalId,
    rows: u16,
    cols: u16,
) -> Result<(), crate::terminal::TerminalError> {
    crate::terminal::resize_terminal(id, rows, cols)
}

pub fn dispose_terminal(id: TerminalId) {
    crate::terminal::dispose_terminal(id);
}
