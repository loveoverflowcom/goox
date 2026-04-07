# Implementation Plan: File Explorer Enhancements

## Overview

Triển khai các cải tiến cho File Explorer trong Goox Editor bao gồm: toolbar với nút tạo file/folder, context menu khi nhấp chuột phải, cải thiện hành vi cursor trong editor, và xử lý lỗi toàn diện. Tất cả các component sẽ được tích hợp vào module `file_explorer` hiện có.

## Tasks

- [x] 1. Thiết lập validation và error handling cơ bản
  - Tạo `FileNameValidator` class trong `lib/features/file_explorer/data/validators/`
  - Tạo `ValidationFailure` class trong `lib/core/errors/failures.dart`
  - Implement validation logic cho tên file/folder (kiểm tra ký tự không hợp lệ, tên rỗng)
  - _Requirements: 4.4, 4.5, 4.6_

- [x] 2. Mở rộng WorkspaceRepository với các method mới
  - [x] 2.1 Thêm method signatures vào abstract class `WorkspaceRepository`
    - Thêm `createFile(String parentPath, String fileName)`
    - Thêm `createFolder(String parentPath, String folderName)`
    - Thêm `renameNode(String nodePath, String newName)`
    - Thêm `deleteNode(String nodePath)`
    - Thêm `validateFileName(String name)`
    - Thêm `refreshWorkspace(String workspacePath)`
    - _Requirements: 1.6, 1.7, 2.7, 2.8, 2.9, 2.10_

  - [x] 2.2 Implement các method trong `WorkspaceRepositoryImpl`
    - Implement file creation với error handling
    - Implement folder creation với error handling
    - Implement rename với validation
    - Implement delete với confirmation
    - Implement path validation
    - Implement workspace refresh
    - _Requirements: 1.6, 1.7, 2.7, 2.8, 2.9, 2.10, 4.1, 4.2, 4.3_

  - [ ]* 2.3 Viết unit tests cho WorkspaceRepository methods
    - Test validation logic với các trường hợp edge case
    - Test error handling cho file operations
    - _Requirements: 4.4, 4.5, 4.6_

- [x] 3. Checkpoint - Đảm bảo repository layer hoạt động đúng
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Mở rộng FileExplorerBloc với events và states mới
  - [x] 4.1 Thêm các event classes mới
    - Tạo `CreateFileEvent` với parentPath và fileName
    - Tạo `CreateFolderEvent` với parentPath và folderName
    - Tạo `RenameNodeEvent` với nodePath và newName
    - Tạo `DeleteNodeEvent` với nodePath
    - Tạo `CopyPathEvent` với nodePath
    - Tạo `RefreshWorkspaceEvent` với workspacePath
    - _Requirements: 1.4, 1.5, 2.1, 2.3, 2.7, 2.8, 2.9, 2.10_

  - [x] 4.2 Mở rộng `FileExplorerState`
    - Thêm `successMessage` field
    - Thêm `pendingOperation` field với enum `FileOperation`
    - Thêm `copyWith` method cho các field mới
    - _Requirements: 4.1, 4.2, 4.3, 4.7_

  - [x] 4.3 Implement event handlers trong FileExplorerBloc
    - Implement `_onCreateFile` với validation và error handling
    - Implement `_onCreateFolder` với validation và error handling
    - Implement `_onRenameNode` với validation
    - Implement `_onDeleteNode` với confirmation
    - Implement `_onCopyPath` với clipboard integration
    - Implement `_onRefreshWorkspace`
    - _Requirements: 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.1, 2.3, 2.7, 2.8, 2.9, 2.10, 4.1, 4.2, 4.3_

  - [ ]* 4.4 Viết unit tests cho FileExplorerBloc
    - Test CreateFileEvent flow (success và error cases)
    - Test CreateFolderEvent flow
    - Test RenameNodeEvent flow
    - Test DeleteNodeEvent flow
    - Test validation failures
    - Test file system errors
    - _Requirements: 1.8, 1.9, 4.1, 4.2, 4.3, 4.6_

- [x] 5. Tạo các dialog widgets
  - [x] 5.1 Tạo `CreateFileDialog` widget
    - TextField với validation real-time
    - Cancel và Create buttons
    - Error message display
    - _Requirements: 1.4, 1.8, 1.9, 4.6_

  - [x] 5.2 Tạo `CreateFolderDialog` widget
    - TextField với validation real-time
    - Cancel và Create buttons
    - Error message display
    - _Requirements: 1.5, 1.8, 1.9, 4.6_

  - [x] 5.3 Tạo `RenameDialog` widget
    - TextField pre-filled với tên hiện tại
    - Cancel và Rename buttons
    - Error message display
    - _Requirements: 2.7, 4.6_

  - [x] 5.4 Tạo `DeleteConfirmationDialog` widget
    - Warning message với tên file/folder
    - Cancel và Delete buttons
    - Hiển thị khác nhau cho file vs folder
    - _Requirements: 2.8_

  - [ ]* 5.5 Viết widget tests cho dialogs
    - Test validation UI
    - Test button callbacks
    - Test error display
    - _Requirements: 1.8, 1.9, 4.6_

- [x] 6. Checkpoint - Đảm bảo BLoC và dialogs hoạt động đúng
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Tạo FileExplorerToolbar widget
  - [x] 7.1 Implement toolbar UI
    - Container với height 40px và border bottom
    - IconButton cho "New File" với icon `insert_drive_file_outlined`
    - IconButton cho "New Folder" với icon `create_new_folder_outlined`
    - Tooltips cho các buttons
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 7.2 Wire toolbar callbacks
    - Connect onNewFile callback để show CreateFileDialog
    - Connect onNewFolder callback để show CreateFolderDialog
    - _Requirements: 1.4, 1.5_

  - [ ]* 7.3 Viết widget tests cho FileExplorerToolbar
    - Test button rendering
    - Test button callbacks
    - Test tooltips
    - _Requirements: 1.1, 1.2, 1.3_

- [x] 8. Tạo FileNodeContextMenu widget
  - [x] 8.1 Implement context menu logic
    - Build menu items dựa trên node type (file, folder, null)
    - File menu: Rename, Delete, Copy Path
    - Folder menu: New File, New Folder, Rename, Delete, Copy Path
    - Empty area menu: New File, New Folder, Refresh
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [x] 8.2 Wire context menu callbacks
    - Connect các action callbacks đến BLoC events
    - Handle menu positioning
    - _Requirements: 2.7, 2.8, 2.9, 2.10_

  - [ ]* 8.3 Viết widget tests cho FileNodeContextMenu
    - Test menu items cho từng node type
    - Test action callbacks
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 9. Tích hợp toolbar và context menu vào FileExplorerWidget
  - [x] 9.1 Thêm toolbar vào top của FileExplorerWidget
    - Wrap existing tree view với Column
    - Add FileExplorerToolbar ở trên cùng
    - _Requirements: 1.1_

  - [x] 9.2 Thêm right-click handling cho tree nodes
    - Add GestureDetector với onSecondaryTapDown cho file nodes
    - Add GestureDetector với onSecondaryTapDown cho folder nodes
    - Add GestureDetector với onSecondaryTapDown cho empty area
    - Show FileNodeContextMenu tại vị trí click
    - _Requirements: 2.1, 2.3, 2.5_

  - [x] 9.3 Implement UI updates sau thao tác
    - Auto-reload workspace sau create/delete/rename
    - Auto-select và expand node mới tạo
    - Maintain expand/collapse state của các folder khác
    - Auto-open file mới trong editor
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

  - [ ]* 9.4 Viết integration tests cho FileExplorerWidget
    - Test complete file creation flow
    - Test complete folder creation flow
    - Test context menu interactions
    - Test UI updates sau operations
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

- [x] 10. Checkpoint - Đảm bảo file explorer enhancements hoạt động end-to-end
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Cải thiện TextEditorWidget cursor behavior
  - [x] 11.1 Wrap TextField với GestureDetector
    - Add GestureDetector với onTapDown handler
    - Implement `_handleTapInEmptyArea` method
    - _Requirements: 3.1, 3.2_

  - [x] 11.2 Implement cursor movement logic
    - Calculate text height dựa trên số dòng và line height
    - Detect tap below content area
    - Move cursor đến end of last line
    - Request focus cho text field
    - _Requirements: 3.1, 3.2, 3.3_

  - [x] 11.3 Maintain normal click behavior
    - Ensure tap trên text vẫn hoạt động bình thường
    - Preserve existing selection behavior
    - _Requirements: 3.4, 3.5_

  - [ ]* 11.4 Viết widget tests cho cursor behavior
    - Test cursor movement khi tap below content
    - Test normal click behavior preserved
    - Test focus behavior
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 12. Thêm error message formatting và display
  - [x] 12.1 Implement error message formatter
    - Format FileSystemFailure messages
    - Format ValidationFailure messages
    - Format generic error messages
    - _Requirements: 4.1, 4.2, 4.3, 4.6_

  - [x] 12.2 Add error display UI
    - Show SnackBar hoặc error banner cho errors
    - Show success messages sau operations thành công
    - Auto-dismiss messages sau timeout
    - _Requirements: 4.1, 4.2, 4.3, 4.7_

- [x] 13. Final checkpoint và testing
  - [x] 13.1 Run all tests
    - Run unit tests
    - Run widget tests
    - Run integration tests
    - _Requirements: All_

  - [x] 13.2 Manual testing
    - Test tạo file/folder từ toolbar
    - Test context menu cho file, folder, empty area
    - Test rename và delete operations
    - Test error cases (duplicate names, invalid characters)
    - Test cursor behavior trong editor
    - Test UI updates sau operations
    - _Requirements: All_

  - [x] 13.3 Final verification
    - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks đánh dấu `*` là optional và có thể bỏ qua để triển khai nhanh hơn
- Mỗi task tham chiếu đến requirements cụ thể để đảm bảo traceability
- Checkpoints đảm bảo validation từng bước
- Tất cả code sử dụng Dart/Flutter với BLoC pattern
- Integration tests sử dụng temporary directories để test file operations
