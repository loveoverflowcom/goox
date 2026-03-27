use goox_core::BufferSnapshot;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DocumentRecord {
    pub path: PathBuf,
    pub snapshot: BufferSnapshot,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StorageError {
    Unsupported(String),
}

pub struct WorkspaceStorage;

impl WorkspaceStorage {
    pub fn new() -> Self {
        Self
    }

    pub fn load_document(&self, path: &Path) -> Result<DocumentRecord, StorageError> {
        Err(StorageError::Unsupported(format!(
            "load_document is not implemented yet for {}",
            path.display()
        )))
    }

    pub fn save_document(&self, path: &Path, snapshot: BufferSnapshot) -> Result<(), StorageError> {
        let _record = DocumentRecord {
            path: path.to_path_buf(),
            snapshot,
        };
        Err(StorageError::Unsupported(format!(
            "save_document is not implemented yet for {}",
            path.display()
        )))
    }
}

impl Default for WorkspaceStorage {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::{StorageError, WorkspaceStorage};
    use std::path::Path;

    #[test]
    fn returns_stub_error_until_storage_is_implemented() {
        let storage = WorkspaceStorage::new();
        let result = storage.load_document(Path::new("draft.txt"));

        match result {
            Ok(_) => panic!("expected storage stub to return an error"),
            Err(StorageError::Unsupported(message)) => {
                assert!(message.contains("draft.txt"));
            }
        }
    }
}
