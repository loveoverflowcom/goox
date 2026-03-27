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

pub fn validate_source_text(language_id: String, text: String) -> Option<String> {
    crate::extensions::validate_source_text(language_id, text)
}

pub fn registered_extension_commands() -> Vec<String> {
    crate::extensions::registered_extension_commands()
}
