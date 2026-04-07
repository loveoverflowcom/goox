# Design Document: File Explorer Enhancements

## Overview

Tính năng File Explorer Enhancements bổ sung các khả năng quản lý file và folder cho Goox Editor, bao gồm:

- Toolbar với các nút tạo file/folder mới
- Context menu khi nhấp chuột phải với các action phổ biến (rename, delete, copy path, refresh)
- Cải thiện hành vi cursor trong editor khi click vào vùng trống
- Validation và xử lý lỗi toàn diện
- Tự động cập nhật UI sau các thao tác

Thiết kế này tập trung vào việc cải thiện trải nghiệm người dùng khi làm việc với file system trong editor, đồng thời đảm bảo tính nhất quán và xử lý lỗi tốt.

## Architecture

### High-Level Architecture

Tính năng này mở rộng module `file_explorer` hiện có với các component mới:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
├─────────────────────────────────────────────────────────┤
│  FileExplorerWidget (enhanced)                          │
│    ├─ FileExplorerToolbar (new)                         │
│    ├─ FileNodeContextMenu (new)                         │
│    ├─ CreateFileDialog (new)                            │
│    ├─ CreateFolderDialog (new)                          │
│    ├─ RenameDialog (new)                                │
│    └─ DeleteConfirmationDialog (new)                    │
│                                                          │
│  FileExplorerBloc (enhanced)                            │
│    ├─ CreateFileEvent (new)                             │
│    ├─ CreateFolderEvent (new)                           │
│    ├─ RenameNodeEvent (new)                             │
│    ├─ DeleteNodeEvent (new)                             │
│    ├─ CopyPathEvent (new)                               │
│    └─ RefreshWorkspaceEvent (new)                       │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
├─────────────────────────────────────────────────────────┤
│  WorkspaceRepository (enhanced)                         │
│    ├─ createFile(path, name) (new)                      │
│    ├─ createFolder(path, name) (new)                    │
│    ├─ renameNode(oldPath, newName) (new)                │
│    ├─ deleteNode(path) (new)                            │
│    ├─ validateFileName(name) (new)                      │
│    └─ refreshWorkspace(path) (new)                      │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   File System (Dart IO)                  │
└─────────────────────────────────────────────────────────┘
```

### Editor Cursor Enhancement

```
┌─────────────────────────────────────────────────────────┐
│              TextEditorWidget (enhanced)                 │
├─────────────────────────────────────────────────────────┤
│  GestureDetector                                         │
│    └─ onTapDown: _handleTapInEmptyArea                  │
│                                                          │
│  TextField                                               │
│    └─ controller: TextEditingController                 │
└─────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Enhanced FileExplorerBloc

Mở rộng bloc hiện có với các event và state mới:

```dart
// New Events
class CreateFileEvent extends FileExplorerEvent {
  final String parentPath;
  final String fileName;
}

class CreateFolderEvent extends FileExplorerEvent {
  final String parentPath;
  final String folderName;
}

class RenameNodeEvent extends FileExplorerEvent {
  final String nodePath;
  final String newName;
}

class DeleteNodeEvent extends FileExplorerEvent {
  final String nodePath;
}

class CopyPathEvent extends FileExplorerEvent {
  final String nodePath;
}

class RefreshWorkspaceEvent extends FileExplorerEvent {
  final String workspacePath;
}

// Enhanced State
class FileExplorerState {
  final List<FileNode> rootNodes;
  final Map<String, List<FileNode>> expandedFolders;
  final String? selectedPath;
  final FileExplorerStatus status;
  final String? errorMessage;
  final String? successMessage; // new
  final FileOperation? pendingOperation; // new
}

enum FileOperation {
  creating,
  renaming,
  deleting,
  copying,
  refreshing,
}
```

### 2. FileExplorerToolbar Widget

Widget mới hiển thị toolbar với các nút action:

```dart
class FileExplorerToolbar extends StatelessWidget {
  final VoidCallback onNewFile;
  final VoidCallback onNewFolder;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.insert_drive_file_outlined),
            tooltip: 'New File',
            onPressed: onNewFile,
          ),
          IconButton(
            icon: Icon(Icons.create_new_folder_outlined),
            tooltip: 'New Folder',
            onPressed: onNewFolder,
          ),
        ],
      ),
    );
  }
}
```

### 3. FileNodeContextMenu Widget

Widget hiển thị context menu với các action phù hợp:

```dart
class FileNodeContextMenu extends StatelessWidget {
  final FileNode? node; // null for empty area
  final Offset position;
  final VoidCallback onNewFile;
  final VoidCallback onNewFolder;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onCopyPath;
  final VoidCallback? onRefresh;
  
  List<PopupMenuEntry> _buildMenuItems() {
    if (node == null) {
      // Empty area menu
      return [
        PopupMenuItem(child: Text('New File'), onTap: onNewFile),
        PopupMenuItem(child: Text('New Folder'), onTap: onNewFolder),
        PopupMenuDivider(),
        PopupMenuItem(child: Text('Refresh'), onTap: onRefresh),
      ];
    } else if (node.type == FileNodeType.directory) {
      // Folder menu
      return [
        PopupMenuItem(child: Text('New File'), onTap: onNewFile),
        PopupMenuItem(child: Text('New Folder'), onTap: onNewFolder),
        PopupMenuDivider(),
        PopupMenuItem(child: Text('Rename'), onTap: onRename),
        PopupMenuItem(child: Text('Delete'), onTap: onDelete),
        PopupMenuDivider(),
        PopupMenuItem(child: Text('Copy Path'), onTap: onCopyPath),
      ];
    } else {
      // File menu
      return [
        PopupMenuItem(child: Text('Rename'), onTap: onRename),
        PopupMenuItem(child: Text('Delete'), onTap: onDelete),
        PopupMenuDivider(),
        PopupMenuItem(child: Text('Copy Path'), onTap: onCopyPath),
      ];
    }
  }
}
```

### 4. Input Dialogs

Các dialog để nhập tên file/folder hoặc tên mới:

```dart
class CreateFileDialog extends StatelessWidget {
  final String parentPath;
  final Function(String) onConfirm;
  
  // TextField with validation
  // Cancel and Create buttons
}

class CreateFolderDialog extends StatelessWidget {
  final String parentPath;
  final Function(String) onConfirm;
  
  // TextField with validation
  // Cancel and Create buttons
}

class RenameDialog extends StatelessWidget {
  final String currentName;
  final Function(String) onConfirm;
  
  // TextField pre-filled with current name
  // Cancel and Rename buttons
}

class DeleteConfirmationDialog extends StatelessWidget {
  final String nodeName;
  final FileNodeType nodeType;
  final VoidCallback onConfirm;
  
  // Warning message
  // Cancel and Delete buttons
}
```

### 5. Enhanced WorkspaceRepository

Mở rộng repository với các method mới:

```dart
abstract class WorkspaceRepository {
  // Existing methods
  TaskEither<Failure, List<FileNode>> loadWorkspace(String path);
  TaskEither<Failure, List<FileNode>> loadChildren(String path);
  Future<bool> pathExists(String path);
  
  // New methods
  TaskEither<Failure, FileNode> createFile(String parentPath, String fileName);
  TaskEither<Failure, FileNode> createFolder(String parentPath, String folderName);
  TaskEither<Failure, FileNode> renameNode(String nodePath, String newName);
  TaskEither<Failure, Unit> deleteNode(String nodePath);
  Either<ValidationFailure, String> validateFileName(String name);
  TaskEither<Failure, List<FileNode>> refreshWorkspace(String workspacePath);
}
```

### 6. FileNameValidator

Utility class để validate tên file/folder:

```dart
class FileNameValidator {
  static const invalidChars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|'];
  
  static Either<ValidationFailure, String> validate(String name) {
    // Check empty or whitespace only
    if (name.trim().isEmpty) {
      return Left(ValidationFailure('File name cannot be empty'));
    }
    
    // Check invalid characters
    for (final char in invalidChars) {
      if (name.contains(char)) {
        return Left(ValidationFailure('File name cannot contain: $char'));
      }
    }
    
    return Right(name);
  }
}
```

### 7. Enhanced TextEditorWidget

Cải thiện widget editor để xử lý click vào vùng trống:

```dart
class TextEditorWidget extends StatefulWidget {
  // Wrap TextField with GestureDetector
  
  void _handleTapInEmptyArea(TapDownDetails details) {
    final textHeight = _calculateTextHeight();
    final tapY = details.localPosition.dy;
    
    if (tapY > textHeight) {
      // Move cursor to end of last line
      final endPosition = _controller.text.length;
      _controller.selection = TextSelection.collapsed(offset: endPosition);
      
      // Request focus
      _focusNode.requestFocus();
    }
  }
  
  double _calculateTextHeight() {
    final lines = _controller.text.split('\n').length;
    final lineHeight = AppSpacing.fontSize * AppSpacing.lineHeight;
    return lines * lineHeight + AppSpacing.editorPadding * 2;
  }
}
```

## Data Models

### Enhanced FileNode

Không cần thay đổi model hiện có, nhưng sẽ sử dụng đầy đủ các thuộc tính:

```dart
final class FileNode extends Equatable {
  final String name;
  final String path;
  final FileNodeType type;
  final List<FileNode> children;
  final bool isExpanded;
  final DateTime? lastModified;
  final int? size;
  
  // copyWith method for immutable updates
}
```

### ValidationFailure

Failure mới cho validation errors:

```dart
class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);
}
```

## Error Handling

### Error Types

1. **ValidationFailure**: Lỗi validation input (tên file không hợp lệ)
2. **FileSystemFailure**: Lỗi từ file system (quyền truy cập, file đã tồn tại)
3. **UnknownFailure**: Lỗi không xác định

### Error Handling Strategy

```dart
// In Bloc event handlers
Future<void> _onCreateFile(
  CreateFileEvent event,
  Emitter<FileExplorerState> emit,
) async {
  emit(state.copyWith(
    status: FileExplorerStatus.loading,
    pendingOperation: FileOperation.creating,
  ));
  
  // Validate file name
  final validationResult = repository.validateFileName(event.fileName);
  
  validationResult.fold(
    (failure) {
      emit(state.copyWith(
        status: FileExplorerStatus.error,
        errorMessage: failure.message,
        pendingOperation: null,
      ));
      return;
    },
    (_) async {
      // Proceed with creation
      final result = await repository.createFile(
        event.parentPath,
        event.fileName,
      ).run();
      
      result.fold(
        (failure) => emit(state.copyWith(
          status: FileExplorerStatus.error,
          errorMessage: _formatErrorMessage(failure),
          pendingOperation: null,
        )),
        (newNode) {
          // Reload workspace and select new file
          _reloadAndSelect(newNode.path, emit);
        },
      );
    },
  );
}

String _formatErrorMessage(Failure failure) {
  if (failure is FileSystemFailure) {
    return 'File system error: ${failure.message}';
  } else if (failure is ValidationFailure) {
    return 'Validation error: ${failure.message}';
  }
  return 'An error occurred: ${failure.message}';
}
```

### User-Facing Error Messages

- **File already exists**: "A file with this name already exists. Please choose a different name."
- **Invalid characters**: "File name cannot contain: / \\ : * ? \" < > |"
- **Empty name**: "File name cannot be empty."
- **Permission denied**: "Permission denied. You don't have access to modify this location."
- **Unknown error**: "An unexpected error occurred. Please try again."

## Testing Strategy

### Assessment: Property-Based Testing Applicability

Tính năng này chủ yếu liên quan đến:
- UI interactions (toolbar, context menu, dialogs)
- File system operations (I/O with external dependencies)
- State management (BLoC pattern)

**Property-based testing KHÔNG phù hợp** cho tính năng này vì:

1. **UI Rendering**: Toolbar, context menu, dialogs là UI components - nên dùng snapshot tests và widget tests
2. **File System Operations**: Các thao tác create, delete, rename phụ thuộc vào file system thực tế - nên dùng integration tests với mock file system
3. **Side-effect Operations**: Các thao tác này chủ yếu là side effects (tạo/xóa file) không có return value để assert universal properties
4. **State Management**: BLoC state transitions nên được test bằng example-based unit tests

Do đó, tôi sẽ **bỏ qua phần Correctness Properties** và tập trung vào unit tests và integration tests.

### Unit Testing Strategy

#### 1. FileNameValidator Tests

```dart
group('FileNameValidator', () {
  test('should reject empty name', () {
    final result = FileNameValidator.validate('');
    expect(result.isLeft(), true);
  });
  
  test('should reject whitespace-only name', () {
    final result = FileNameValidator.validate('   ');
    expect(result.isLeft(), true);
  });
  
  test('should reject name with invalid characters', () {
    final invalidNames = ['file/name', 'file\\name', 'file:name', 
                          'file*name', 'file?name', 'file"name',
                          'file<name', 'file>name', 'file|name'];
    
    for (final name in invalidNames) {
      final result = FileNameValidator.validate(name);
      expect(result.isLeft(), true, reason: 'Should reject: $name');
    }
  });
  
  test('should accept valid file names', () {
    final validNames = ['file.txt', 'my-file.dart', 'file_name.json',
                        'file123.md', 'file.name.with.dots.txt'];
    
    for (final name in validNames) {
      final result = FileNameValidator.validate(name);
      expect(result.isRight(), true, reason: 'Should accept: $name');
    }
  });
});
```

#### 2. FileExplorerBloc Tests

```dart
group('FileExplorerBloc', () {
  late MockWorkspaceRepository mockRepository;
  late FileExplorerBloc bloc;
  
  setUp(() {
    mockRepository = MockWorkspaceRepository();
    bloc = FileExplorerBloc(repository: mockRepository);
  });
  
  group('CreateFileEvent', () {
    test('should emit loading then loaded with new file', () async {
      // Arrange
      final newFile = FileNode(
        name: 'test.txt',
        path: '/workspace/test.txt',
        type: FileNodeType.file,
      );
      
      when(() => mockRepository.validateFileName('test.txt'))
          .thenReturn(Right('test.txt'));
      when(() => mockRepository.createFile('/workspace', 'test.txt'))
          .thenAnswer((_) => TaskEither.right(newFile));
      when(() => mockRepository.loadWorkspace('/workspace'))
          .thenAnswer((_) => TaskEither.right([newFile]));
      
      // Act
      bloc.add(CreateFileEvent(
        parentPath: '/workspace',
        fileName: 'test.txt',
      ));
      
      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<FileExplorerState>(
            (state) => state.status == FileExplorerStatus.loading &&
                       state.pendingOperation == FileOperation.creating,
          ),
          predicate<FileExplorerState>(
            (state) => state.status == FileExplorerStatus.loaded &&
                       state.selectedPath == '/workspace/test.txt',
          ),
        ]),
      );
    });
    
    test('should emit error when validation fails', () async {
      // Arrange
      when(() => mockRepository.validateFileName('invalid/name'))
          .thenReturn(Left(ValidationFailure('Invalid character: /')));
      
      // Act
      bloc.add(CreateFileEvent(
        parentPath: '/workspace',
        fileName: 'invalid/name',
      ));
      
      // Assert
      await expectLater(
        bloc.stream,
        emits(predicate<FileExplorerState>(
          (state) => state.status == FileExplorerStatus.error &&
                     state.errorMessage!.contains('Invalid character'),
        )),
      );
    });
    
    test('should emit error when file already exists', () async {
      // Arrange
      when(() => mockRepository.validateFileName('existing.txt'))
          .thenReturn(Right('existing.txt'));
      when(() => mockRepository.createFile('/workspace', 'existing.txt'))
          .thenAnswer((_) => TaskEither.left(
            FileSystemFailure('File already exists'),
          ));
      
      // Act
      bloc.add(CreateFileEvent(
        parentPath: '/workspace',
        fileName: 'existing.txt',
      ));
      
      // Assert
      await expectLater(
        bloc.stream,
        emits(predicate<FileExplorerState>(
          (state) => state.status == FileExplorerStatus.error &&
                     state.errorMessage!.contains('already exists'),
        )),
      );
    });
  });
  
  group('DeleteNodeEvent', () {
    test('should show confirmation and delete on confirm', () async {
      // Similar structure for delete tests
    });
  });
  
  group('RenameNodeEvent', () {
    test('should rename and update tree', () async {
      // Similar structure for rename tests
    });
  });
  
  group('CopyPathEvent', () {
    test('should copy path to clipboard', () async {
      // Test clipboard interaction
    });
  });
});
```

#### 3. Widget Tests

```dart
group('FileExplorerToolbar', () {
  testWidgets('should display new file and new folder buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileExplorerToolbar(
            onNewFile: () {},
            onNewFolder: () {},
          ),
        ),
      ),
    );
    
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    expect(find.byIcon(Icons.create_new_folder_outlined), findsOneWidget);
  });
  
  testWidgets('should call onNewFile when new file button tapped', (tester) async {
    var called = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileExplorerToolbar(
            onNewFile: () => called = true,
            onNewFolder: () {},
          ),
        ),
      ),
    );
    
    await tester.tap(find.byIcon(Icons.insert_drive_file_outlined));
    expect(called, true);
  });
});

group('FileNodeContextMenu', () {
  testWidgets('should show file menu items for file node', (tester) async {
    final fileNode = FileNode(
      name: 'test.txt',
      path: '/test.txt',
      type: FileNodeType.file,
    );
    
    // Test menu items
  });
  
  testWidgets('should show folder menu items for folder node', (tester) async {
    final folderNode = FileNode(
      name: 'folder',
      path: '/folder',
      type: FileNodeType.directory,
    );
    
    // Test menu items
  });
  
  testWidgets('should show empty area menu items when node is null', (tester) async {
    // Test menu items for empty area
  });
});

group('CreateFileDialog', () {
  testWidgets('should show validation error for invalid name', (tester) async {
    // Test validation UI
  });
  
  testWidgets('should call onConfirm with valid name', (tester) async {
    // Test successful creation
  });
});
```

#### 4. TextEditorWidget Cursor Tests

```dart
group('TextEditorWidget cursor behavior', () {
  testWidgets('should move cursor to end when tapping below content', (tester) async {
    final controller = TextEditingController(text: 'Line 1\nLine 2');
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextEditorWidget(),
        ),
      ),
    );
    
    // Tap below content
    final textHeight = /* calculate based on content */;
    await tester.tapAt(Offset(100, textHeight + 50));
    await tester.pump();
    
    // Verify cursor is at end
    expect(controller.selection.baseOffset, controller.text.length);
  });
  
  testWidgets('should maintain normal behavior when tapping on text', (tester) async {
    // Test normal click behavior
  });
});
```

### Integration Testing Strategy

#### 1. File System Integration Tests

```dart
group('WorkspaceRepository file operations', () {
  late Directory testDir;
  late WorkspaceRepositoryImpl repository;
  
  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('test_workspace_');
    repository = WorkspaceRepositoryImpl();
  });
  
  tearDown(() async {
    await testDir.delete(recursive: true);
  });
  
  test('should create file in workspace', () async {
    final result = await repository.createFile(
      testDir.path,
      'test.txt',
    ).run();
    
    expect(result.isRight(), true);
    expect(File('${testDir.path}/test.txt').existsSync(), true);
  });
  
  test('should fail when creating duplicate file', () async {
    // Create file first
    await File('${testDir.path}/existing.txt').create();
    
    // Try to create again
    final result = await repository.createFile(
      testDir.path,
      'existing.txt',
    ).run();
    
    expect(result.isLeft(), true);
  });
  
  test('should rename file successfully', () async {
    // Create file
    await File('${testDir.path}/old.txt').create();
    
    // Rename
    final result = await repository.renameNode(
      '${testDir.path}/old.txt',
      'new.txt',
    ).run();
    
    expect(result.isRight(), true);
    expect(File('${testDir.path}/new.txt').existsSync(), true);
    expect(File('${testDir.path}/old.txt').existsSync(), false);
  });
  
  test('should delete file successfully', () async {
    // Create file
    await File('${testDir.path}/delete.txt').create();
    
    // Delete
    final result = await repository.deleteNode(
      '${testDir.path}/delete.txt',
    ).run();
    
    expect(result.isRight(), true);
    expect(File('${testDir.path}/delete.txt').existsSync(), false);
  });
});
```

#### 2. End-to-End Widget Integration Tests

```dart
group('File Explorer E2E', () {
  testWidgets('complete file creation flow', (tester) async {
    // 1. Setup app with file explorer
    // 2. Tap new file button
    // 3. Enter file name in dialog
    // 4. Confirm creation
    // 5. Verify file appears in tree
    // 6. Verify file is selected
    // 7. Verify editor opens with file
  });
  
  testWidgets('complete context menu flow', (tester) async {
    // 1. Right-click on file
    // 2. Select rename from menu
    // 3. Enter new name
    // 4. Confirm
    // 5. Verify file is renamed in tree
  });
});
```

### Test Coverage Goals

- Unit tests: 90%+ coverage for business logic (validators, bloc logic)
- Widget tests: 80%+ coverage for UI components
- Integration tests: Cover all critical file operations
- E2E tests: Cover main user workflows

### Testing Tools

- **flutter_test**: Core testing framework
- **bloc_test**: Testing BLoC logic
- **mocktail**: Mocking dependencies
- **integration_test**: E2E testing

