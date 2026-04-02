mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
use ropey::Rope;
use std::ops::Range;
pub mod api;
pub mod erp;
pub mod extensions;
pub mod image_renderer;
pub mod lsp;
pub mod pdf_renderer;
pub mod terminal;
pub mod wasm_runtime;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BufferOperation {
    Insert { char_index: usize, text: String },
    Delete { start: usize, end: usize },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BufferTransaction {
    pub operations: Vec<BufferOperation>,
    pub mergeable: bool,
    pub label: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BufferPatchBatch {
    pub revision: u64,
    pub label: String,
    pub patches: Vec<BufferOperation>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BufferSnapshot {
    pub revision: u64,
    pub line_count: usize,
    pub char_count: usize,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ViewportRequest {
    pub first_line: usize,
    pub max_lines: usize,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ViewportLine {
    pub line_index: usize,
    pub text: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ViewportSnapshot {
    pub revision: u64,
    pub first_visible_line: usize,
    pub total_lines: usize,
    pub lines: Vec<ViewportLine>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BufferError {
    EmptyTransaction,
    InvalidInsertPosition {
        char_index: usize,
        len_chars: usize,
    },
    InvalidDeleteRange {
        start: usize,
        end: usize,
        len_chars: usize,
    },
    NoUndoEntry,
    NoRedoEntry,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct UndoEntry {
    forward_operations: Vec<BufferOperation>,
    inverse_operations: Vec<BufferOperation>,
    mergeable: bool,
    label: String,
}

#[derive(Debug, Clone)]
pub struct EditorBuffer {
    rope: Rope,
    revision: u64,
    undo_stack: Vec<UndoEntry>,
    redo_stack: Vec<UndoEntry>,
}

impl EditorBuffer {
    pub fn new(initial_text: &str) -> Self {
        Self {
            rope: Rope::from_str(initial_text),
            revision: 0,
            undo_stack: Vec::new(),
            redo_stack: Vec::new(),
        }
    }

    pub fn snapshot(&self) -> BufferSnapshot {
        BufferSnapshot {
            revision: self.revision,
            line_count: self.rope.len_lines(),
            char_count: self.rope.len_chars(),
        }
    }

    pub fn text(&self) -> String {
        self.rope.to_string()
    }

    pub fn viewport(&self, request: ViewportRequest) -> ViewportSnapshot {
        let total_lines = self.rope.len_lines();
        let first_visible_line = request.first_line.min(total_lines.saturating_sub(1));
        let last_exclusive = first_visible_line
            .saturating_add(request.max_lines)
            .min(total_lines);
        let mut lines = Vec::with_capacity(last_exclusive.saturating_sub(first_visible_line));

        for line_index in first_visible_line..last_exclusive {
            let rope_line = self.rope.line(line_index).to_string();
            let line_text = trim_trailing_newline(rope_line);
            lines.push(ViewportLine {
                line_index,
                text: line_text,
            });
        }

        ViewportSnapshot {
            revision: self.revision,
            first_visible_line,
            total_lines,
            lines,
        }
    }

    pub fn apply_transaction(
        &mut self,
        transaction: BufferTransaction,
    ) -> Result<BufferPatchBatch, BufferError> {
        if transaction.operations.is_empty() {
            return Err(BufferError::EmptyTransaction);
        }

        let mut inverse_operations = Vec::with_capacity(transaction.operations.len());
        for operation in &transaction.operations {
            let inverse = self.apply_operation(operation)?;
            inverse_operations.push(inverse);
        }

        inverse_operations.reverse();
        self.revision = self.revision.saturating_add(1);

        let undo_entry = UndoEntry {
            forward_operations: transaction.operations.clone(),
            inverse_operations,
            mergeable: transaction.mergeable,
            label: transaction.label.clone(),
        };

        if transaction.mergeable {
            if let Some(previous) = self.undo_stack.last_mut() {
                if previous.mergeable {
                    previous
                        .forward_operations
                        .extend(undo_entry.forward_operations.clone());
                    let mut merged_inverse = undo_entry.inverse_operations.clone();
                    merged_inverse.extend(previous.inverse_operations.clone());
                    previous.inverse_operations = merged_inverse;
                    previous.label = undo_entry.label.clone();
                    self.redo_stack.clear();

                    return Ok(BufferPatchBatch {
                        revision: self.revision,
                        label: transaction.label,
                        patches: transaction.operations,
                    });
                }
            }
        }

        self.undo_stack.push(undo_entry);
        self.redo_stack.clear();

        Ok(BufferPatchBatch {
            revision: self.revision,
            label: transaction.label,
            patches: transaction.operations,
        })
    }

    pub fn undo(&mut self) -> Result<BufferPatchBatch, BufferError> {
        let Some(entry) = self.undo_stack.pop() else {
            return Err(BufferError::NoUndoEntry);
        };

        for operation in &entry.inverse_operations {
            let _ignored_inverse = self.apply_operation(operation)?;
        }

        self.revision = self.revision.saturating_add(1);
        let patches = entry.inverse_operations.clone();
        self.redo_stack.push(entry);

        Ok(BufferPatchBatch {
            revision: self.revision,
            label: "undo".to_string(),
            patches,
        })
    }

    pub fn redo(&mut self) -> Result<BufferPatchBatch, BufferError> {
        let Some(entry) = self.redo_stack.pop() else {
            return Err(BufferError::NoRedoEntry);
        };

        for operation in &entry.forward_operations {
            let _ignored_inverse = self.apply_operation(operation)?;
        }

        self.revision = self.revision.saturating_add(1);
        let patches = entry.forward_operations.clone();
        self.undo_stack.push(entry);

        Ok(BufferPatchBatch {
            revision: self.revision,
            label: "redo".to_string(),
            patches,
        })
    }

    pub fn can_undo(&self) -> bool {
        !self.undo_stack.is_empty()
    }

    pub fn can_redo(&self) -> bool {
        !self.redo_stack.is_empty()
    }

    fn apply_operation(
        &mut self,
        operation: &BufferOperation,
    ) -> Result<BufferOperation, BufferError> {
        match operation {
            BufferOperation::Insert { char_index, text } => {
                let len_chars = self.rope.len_chars();
                if *char_index > len_chars {
                    return Err(BufferError::InvalidInsertPosition {
                        char_index: *char_index,
                        len_chars,
                    });
                }

                self.rope.insert(*char_index, text);
                let inserted_len = text.chars().count();

                Ok(BufferOperation::Delete {
                    start: *char_index,
                    end: char_index.saturating_add(inserted_len),
                })
            }
            BufferOperation::Delete { start, end } => {
                validate_delete_range(*start..*end, self.rope.len_chars())?;
                let deleted_text = self.rope.slice(*start..*end).to_string();
                self.rope.remove(*start..*end);

                Ok(BufferOperation::Insert {
                    char_index: *start,
                    text: deleted_text,
                })
            }
        }
    }

    pub fn char_to_line_column(&self, char_index: usize) -> (usize, usize) {
        let line_index = self
            .rope
            .char_to_line(char_index.min(self.rope.len_chars()));
        let line_start_char = self.rope.line_to_char(line_index);
        let column = char_index.saturating_sub(line_start_char);
        (line_index, column)
    }

    pub fn line_range(&self, line_index: usize) -> Option<(usize, usize)> {
        if line_index >= self.rope.len_lines() {
            return None;
        }

        let start = self.rope.line_to_char(line_index);
        let end = if line_index + 1 < self.rope.len_lines() {
            self.rope.line_to_char(line_index + 1)
        } else {
            self.rope.len_chars()
        };

        Some((start, end))
    }
}

fn validate_delete_range(range: Range<usize>, len_chars: usize) -> Result<(), BufferError> {
    if range.start >= range.end || range.end > len_chars {
        return Err(BufferError::InvalidDeleteRange {
            start: range.start,
            end: range.end,
            len_chars,
        });
    }

    Ok(())
}

fn trim_trailing_newline(line: String) -> String {
    if let Some(stripped) = line.strip_suffix("\r\n") {
        return stripped.to_string();
    }

    if let Some(stripped) = line.strip_suffix('\n') {
        return stripped.to_string();
    }

    line
}

#[cfg(test)]
mod tests {
    use super::{BufferError, BufferOperation, BufferTransaction, EditorBuffer, ViewportRequest};

    #[test]
    fn applies_insert_transaction_and_emits_revisioned_patch() {
        let mut buffer = EditorBuffer::new("goox");
        let result = buffer.apply_transaction(BufferTransaction {
            operations: vec![BufferOperation::Insert {
                char_index: 4,
                text: " editor".to_string(),
            }],
            mergeable: false,
            label: "type".to_string(),
        });

        match result {
            Ok(batch) => {
                assert_eq!(batch.revision, 1);
                assert_eq!(batch.patches.len(), 1);
                assert_eq!(buffer.text(), "goox editor");
                assert!(buffer.can_undo());
            }
            Err(error) => panic!("expected success, got {error:?}"),
        }
    }

    #[test]
    fn supports_delete_undo_and_redo() {
        let mut buffer = EditorBuffer::new("hello\nworld");
        let delete_result = buffer.apply_transaction(BufferTransaction {
            operations: vec![BufferOperation::Delete { start: 5, end: 6 }],
            mergeable: false,
            label: "delete newline".to_string(),
        });
        assert!(delete_result.is_ok());
        assert_eq!(buffer.text(), "helloworld");

        let undo_result = buffer.undo();
        assert!(undo_result.is_ok());
        assert_eq!(buffer.text(), "hello\nworld");

        let redo_result = buffer.redo();
        assert!(redo_result.is_ok());
        assert_eq!(buffer.text(), "helloworld");
    }

    #[test]
    fn returns_visible_lines_without_rendering_full_document() {
        let buffer = EditorBuffer::new("line 1\nline 2\nline 3\nline 4\n");
        let viewport = buffer.viewport(ViewportRequest {
            first_line: 1,
            max_lines: 2,
        });

        assert_eq!(viewport.first_visible_line, 1);
        assert_eq!(viewport.lines.len(), 2);
        assert_eq!(viewport.lines[0].text, "line 2");
        assert_eq!(viewport.lines[1].text, "line 3");
    }

    #[test]
    fn rejects_invalid_delete_range() {
        let mut buffer = EditorBuffer::new("goox");
        let result = buffer.apply_transaction(BufferTransaction {
            operations: vec![BufferOperation::Delete { start: 3, end: 9 }],
            mergeable: false,
            label: "bad".to_string(),
        });

        match result {
            Ok(_) => panic!("expected invalid range error"),
            Err(BufferError::InvalidDeleteRange {
                start,
                end,
                len_chars,
            }) => {
                assert_eq!(start, 3);
                assert_eq!(end, 9);
                assert_eq!(len_chars, 4);
            }
            Err(other) => panic!("expected invalid delete range, got {other:?}"),
        }
    }
}
