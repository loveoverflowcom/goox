# Design Document: VSCode-like Editor Layout

## Overview

Tài liệu này mô tả thiết kế kiến trúc và kỹ thuật cho tính năng VSCode-like Editor Layout trong ứng dụng Flutter goox. Thiết kế này áp dụng các nguyên tắc kiến trúc chuyên nghiệp tương tự như các dự án lớn (VSCode, IntelliJ IDEA) với focus vào scalability, maintainability, và testability.

### Design Goals

- **Modularity**: Các component độc lập, dễ dàng thay thế và mở rộng
- **Scalability**: Hỗ trợ thêm features mới mà không ảnh hưởng code hiện tại
- **Testability**: Separation of concerns cho phép unit test và integration test dễ dàng
- **Performance**: Xử lý hiệu quả với workspace lớn và nhiều file mở
- **Maintainability**: Code structure rõ ràng, dễ hiểu và maintain

### Technology Stack

- **Framework**: Flutter 3.11.3+
- **State Management**: flutter_bloc (BLoC pattern)
- **Dependency Injection**: get_it
- **File System**: dart:io với path package
- **Testing**: flutter_test, bloc_test, mocktail

## Architecture

### Layered Architecture

Ứng dụng được tổ chức theo kiến trúc phân tầng (Clean Architecture) với 3 layers chính:

```
┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                      │
│  (UI Widgets, BLoC, State Management)                   │
└─────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────┐
│                    Domain Layer                          │
│  (Business Logic, Use Cases, Entities)                  │
└─────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────┐
│                     Data Layer                           │
│  (Repositories, Data Sources, File System)              │
└─────────────────────────────────────────────────────────┘
```

#### Presentation Layer

Chịu trách nhiệm hiển thị UI và xử lý user interactions. Sử dụng BLoC pattern để quản lý state.

**Components:**
- **Widgets**: Stateless/Stateful widgets cho UI
- **BLoC**: Business Logic Components xử lý events và emit states
- **Pages**: Top-level screens của ứng dụng

**Responsibilities:**
- Render UI based on state
- Capture user input và dispatch events
- Navigate between screens
- Display error messages và loading states

#### Domain Layer

Chứa business logic thuần túy, không phụ thuộc vào Flutter framework hay external libraries.

**Components:**
- **Entities**: Core business objects (EditorTab, FileNode, WorkspaceConfig)
- **Use Cases**: Single-responsibility business operations
- **Repository Interfaces**: Abstract contracts cho data access

**Responsibilities:**
- Define business rules
- Coordinate data flow between layers
- Validate business logic
- Independent of UI và data sources

#### Data Layer

Xử lý data persistence và external data sources.

**Components:**
- **Repositories**: Implement domain repository interfaces
- **Data Sources**: File system access, local storage
- **Models**: Data transfer objects (DTOs)

**Responsibilities:**
- File system operations (read, write, watch)
- Data caching và persistence
- Error handling cho I/O operations
- Transform data models to domain entities

### State Management: BLoC Pattern

Sử dụng BLoC (Business Logic Component) pattern với flutter_bloc package.

**BLoC Flow:**
```
User Action → Event → BLoC → State → UI Update
```

**Key BLoCs:**

1. **EditorLayoutBloc**: Quản lý overall layout state
   - Events: ToggleSidebar, ResizeSidebar, UpdateLayout
   - States: EditorLayoutState (sidebarVisible, sidebarWidth, etc.)

2. **FileExplorerBloc**: Quản lý file tree và navigation
   - Events: LoadWorkspace, ExpandFolder, CollapseFolder, SelectFile
   - States: FileExplorerState (fileTree, selectedPath, loading, error)

3. **TabManagerBloc**: Quản lý open tabs
   - Events: OpenTab, CloseTab, ActivateTab, ReorderTabs
   - States: TabManagerState (tabs, activeTabId, tabOrder)

4. **EditorContentBloc**: Quản lý file content và editing
   - Events: LoadFileContent, UpdateContent, SaveFile, Undo, Redo
   - States: EditorContentState (content, cursorPosition, modified, etc.)

5. **StatusBarBloc**: Quản lý status bar information
   - Events: UpdateCursorPosition, UpdateFileInfo
   - States: StatusBarState (lineNumber, columnNumber, encoding, language)

**BLoC Communication:**
- BLoCs communicate via events (loosely coupled)
- Use BlocListener để react to state changes from other BLoCs
- Shared state through repository layer khi cần

### Dependency Injection

Sử dụng **get_it** package cho service locator pattern.

**Service Registration:**
```dart
// Data Layer
sl.registerLazySingleton<FileSystemDataSource>(() => FileSystemDataSourceImpl());
sl.registerLazySingleton<WorkspaceRepository>(() => WorkspaceRepositoryImpl(sl()));

// Domain Layer
sl.registerLazySingleton<LoadWorkspaceUseCase>(() => LoadWorkspaceUseCase(sl()));
sl.registerLazySingleton<OpenFileUseCase>(() => OpenFileUseCase(sl()));

// Presentation Layer
sl.registerFactory(() => FileExplorerBloc(loadWorkspace: sl()));
sl.registerFactory(() => TabManagerBloc(openFile: sl()));
```

## Components and Interfaces

### Feature-Based Folder Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── editor_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── editor_colors.dart
│   │   └── editor_text_styles.dart
│   ├── utils/
│   │   ├── file_utils.dart
│   │   ├── keyboard_utils.dart
│   │   └── platform_utils.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   └── di/
│       └── injection_container.dart
│
├── features/
│   ├── editor_layout/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── layout_config_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── layout_preferences_local_data_source.dart
│   │   │   └── repositories/
│   │   │       └── layout_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── layout_config.dart
│   │   │   ├── repositories/
│   │   │   │   └── layout_repository.dart
│   │   │   └── usecases/
│   │   │       ├── toggle_sidebar_usecase.dart
│   │   │       ├── resize_sidebar_usecase.dart
│   │   │       └── save_layout_preferences_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── editor_layout_bloc.dart
│   │       │   ├── editor_layout_event.dart
│   │       │   └── editor_layout_state.dart
│   │       ├── widgets/
│   │       │   ├── resizable_sidebar.dart
│   │       │   └── sidebar_toggle_button.dart
│   │       └── pages/
│   │           └── editor_layout_page.dart
│   │
│   ├── file_explorer/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── file_node_model.dart
│   │   │   │   └── file_tree_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── file_system_data_source.dart
│   │   │   └── repositories/
│   │   │       └── workspace_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── file_node.dart
│   │   │   │   └── file_tree.dart
│   │   │   ├── repositories/
│   │   │   │   └── workspace_repository.dart
│   │   │   └── usecases/
│   │   │       ├── load_workspace_usecase.dart
│   │   │       ├── expand_folder_usecase.dart
│   │   │       ├── watch_file_changes_usecase.dart
│   │   │       └── get_file_icon_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── file_explorer_bloc.dart
│   │       │   ├── file_explorer_event.dart
│   │       │   └── file_explorer_state.dart
│   │       └── widgets/
│   │           ├── file_explorer_widget.dart
│   │           ├── file_tree_item.dart
│   │           └── file_icon.dart
│   │
│   ├── tab_manager/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── editor_tab_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── tab_state_local_data_source.dart
│   │   │   └── repositories/
│   │   │       └── tab_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── editor_tab.dart
│   │   │   ├── repositories/
│   │   │   │   └── tab_repository.dart
│   │   │   └── usecases/
│   │   │       ├── open_tab_usecase.dart
│   │   │       ├── close_tab_usecase.dart
│   │   │       ├── activate_tab_usecase.dart
│   │   │       └── reorder_tabs_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── tab_manager_bloc.dart
│   │       │   ├── tab_manager_event.dart
│   │       │   └── tab_manager_state.dart
│   │       └── widgets/
│   │           ├── tab_bar_widget.dart
│   │           ├── tab_item.dart
│   │           └── tab_close_button.dart
│   │
│   ├── editor_content/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── file_content_model.dart
│   │   │   │   └── cursor_position_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── file_content_data_source.dart
│   │   │   └── repositories/
│   │   │       └── file_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── file_content.dart
│   │   │   │   ├── cursor_position.dart
│   │   │   │   └── edit_history.dart
│   │   │   ├── repositories/
│   │   │   │   └── file_repository.dart
│   │   │   └── usecases/
│   │   │       ├── load_file_content_usecase.dart
│   │   │       ├── save_file_usecase.dart
│   │   │       ├── update_content_usecase.dart
│   │   │       ├── undo_usecase.dart
│   │   │       └── redo_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── editor_content_bloc.dart
│   │       │   ├── editor_content_event.dart
│   │       │   └── editor_content_state.dart
│   │       └── widgets/
│   │           ├── text_editor_widget.dart
│   │           ├── line_numbers.dart
│   │           ├── editor_scrollbar.dart
│   │           └── editor_header.dart
│   │
│   └── status_bar/
│       ├── domain/
│       │   ├── entities/
│       │   │   └── status_info.dart
│       │   └── usecases/
│       │       └── format_status_info_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── status_bar_bloc.dart
│           │   ├── status_bar_event.dart
│           │   └── status_bar_state.dart
│           └── widgets/
│               ├── status_bar_widget.dart
│               └── status_item.dart
│
└── main.dart
```

### Core Interfaces

#### WorkspaceRepository Interface

```dart
abstract class WorkspaceRepository {
  /// Load workspace directory structure
  Future<Either<Failure, FileTree>> loadWorkspace(String path);
  
  /// Watch for file system changes
  Stream<FileSystemEvent> watchWorkspace(String path);
  
  /// Get file metadata
  Future<Either<Failure, FileMetadata>> getFileMetadata(String path);
  
  /// Check if path exists
  Future<bool> pathExists(String path);
}
```

#### FileRepository Interface

```dart
abstract class FileRepository {
  /// Read file content
  Future<Either<Failure, FileContent>> readFile(String path);
  
  /// Write file content
  Future<Either<Failure, void>> writeFile(String path, String content);
  
  /// Check if file is modified
  Future<bool> isFileModified(String path, String content);
  
  /// Get file encoding
  Future<String> getFileEncoding(String path);
}
```

#### TabRepository Interface

```dart
abstract class TabRepository {
  /// Save tab state to local storage
  Future<void> saveTabState(List<EditorTab> tabs);
  
  /// Load tab state from local storage
  Future<List<EditorTab>> loadTabState();
  
  /// Clear tab state
  Future<void> clearTabState();
}
```

#### LayoutRepository Interface

```dart
abstract class LayoutRepository {
  /// Save layout preferences
  Future<void> saveLayoutPreferences(LayoutConfig config);
  
  /// Load layout preferences
  Future<LayoutConfig> loadLayoutPreferences();
  
  /// Reset to default layout
  Future<void> resetLayout();
}
```

### Key Widgets Architecture

#### EditorLayoutPage (Root Widget)

```dart
class EditorLayoutPage extends StatelessWidget {
  // Provides all BLoCs to widget tree
  // Coordinates layout of Sidebar, EditorArea, StatusBar
  // Handles keyboard shortcuts at app level
}
```

**Widget Tree:**
```
EditorLayoutPage
├── MultiBlocProvider
│   ├── EditorLayoutBloc
│   ├── FileExplorerBloc
│   ├── TabManagerBloc
│   ├── EditorContentBloc
│   └── StatusBarBloc
└── Column
    ├── Expanded (Main Content)
    │   └── Row
    │       ├── ResizableSidebar
    │       │   └── FileExplorerWidget
    │       └── Expanded (EditorArea)
    │           ├── TabBarWidget
    │           └── TextEditorWidget
    └── StatusBarWidget
```

#### ResizableSidebar Widget

```dart
class ResizableSidebar extends StatefulWidget {
  // Handles drag gestures for resizing
  // Enforces min/max width constraints
  // Animates show/hide transitions
}
```

#### FileExplorerWidget

```dart
class FileExplorerWidget extends StatelessWidget {
  // Displays file tree using BlocBuilder
  // Handles expand/collapse interactions
  // Shows file icons based on file type
  // Highlights selected file
}
```

#### TabBarWidget

```dart
class TabBarWidget extends StatelessWidget {
  // Displays horizontal list of tabs
  // Handles tab selection and closing
  // Shows active tab indicator
  // Supports horizontal scrolling
}
```

#### TextEditorWidget

```dart
class TextEditorWidget extends StatefulWidget {
  // Displays file content with syntax highlighting
  // Handles text input and editing
  // Shows line numbers
  // Manages cursor position
  // Supports undo/redo
}
```

## Data Models

### Domain Entities

#### FileNode Entity

```dart
class FileNode extends Equatable {
  final String name;
  final String path;
  final FileNodeType type; // file or directory
  final List<FileNode> children;
  final bool isExpanded;
  final DateTime? lastModified;
  final int? size;
  
  const FileNode({
    required this.name,
    required this.path,
    required this.type,
    this.children = const [],
    this.isExpanded = false,
    this.lastModified,
    this.size,
  });
  
  FileNode copyWith({...});
  
  @override
  List<Object?> get props => [name, path, type, children, isExpanded];
}

enum FileNodeType { file, directory }
```

#### EditorTab Entity

```dart
class EditorTab extends Equatable {
  final String id;
  final String filePath;
  final String fileName;
  final bool isModified;
  final bool isActive;
  final DateTime openedAt;
  
  const EditorTab({
    required this.id,
    required this.filePath,
    required this.fileName,
    this.isModified = false,
    this.isActive = false,
    required this.openedAt,
  });
  
  EditorTab copyWith({...});
  
  @override
  List<Object?> get props => [id, filePath, fileName, isModified, isActive];
}
```

#### FileContent Entity

```dart
class FileContent extends Equatable {
  final String path;
  final String content;
  final String encoding;
  final String language;
  final DateTime lastModified;
  
  const FileContent({
    required this.path,
    required this.content,
    required this.encoding,
    required this.language,
    required this.lastModified,
  });
  
  FileContent copyWith({...});
  
  @override
  List<Object?> get props => [path, content, encoding, language, lastModified];
}
```

#### CursorPosition Entity

```dart
class CursorPosition extends Equatable {
  final int line;
  final int column;
  final int offset;
  
  const CursorPosition({
    required this.line,
    required this.column,
    required this.offset,
  });
  
  CursorPosition copyWith({...});
  
  @override
  List<Object?> get props => [line, column, offset];
}
```

#### LayoutConfig Entity

```dart
class LayoutConfig extends Equatable {
  final bool sidebarVisible;
  final double sidebarWidth;
  final String workspacePath;
  
  const LayoutConfig({
    required this.sidebarVisible,
    required this.sidebarWidth,
    required this.workspacePath,
  });
  
  LayoutConfig copyWith({...});
  
  @override
  List<Object?> get props => [sidebarVisible, sidebarWidth, workspacePath];
}
```

#### EditHistory Entity

```dart
class EditHistory extends Equatable {
  final List<EditAction> undoStack;
  final List<EditAction> redoStack;
  final int maxHistorySize;
  
  const EditHistory({
    this.undoStack = const [],
    this.redoStack = const [],
    this.maxHistorySize = 100,
  });
  
  EditHistory copyWith({...});
  
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  
  @override
  List<Object?> get props => [undoStack, redoStack, maxHistorySize];
}

class EditAction extends Equatable {
  final String oldContent;
  final String newContent;
  final CursorPosition oldPosition;
  final CursorPosition newPosition;
  final DateTime timestamp;
  
  const EditAction({
    required this.oldContent,
    required this.newContent,
    required this.oldPosition,
    required this.newPosition,
    required this.timestamp,
  });
  
  @override
  List<Object?> get props => [oldContent, newContent, oldPosition, newPosition];
}
```

### Data Models (DTOs)

Data models extend domain entities và add serialization capabilities:

```dart
class FileNodeModel extends FileNode {
  const FileNodeModel({...}) : super(...);
  
  factory FileNodeModel.fromJson(Map<String, dynamic> json) {...}
  Map<String, dynamic> toJson() {...}
  
  factory FileNodeModel.fromEntity(FileNode entity) {...}
}
```

### State Models

#### EditorLayoutState

```dart
class EditorLayoutState extends Equatable {
  final bool sidebarVisible;
  final double sidebarWidth;
  final bool isResizing;
  final LayoutStatus status;
  
  const EditorLayoutState({
    required this.sidebarVisible,
    required this.sidebarWidth,
    this.isResizing = false,
    this.status = LayoutStatus.initial,
  });
  
  EditorLayoutState copyWith({...});
  
  @override
  List<Object?> get props => [sidebarVisible, sidebarWidth, isResizing, status];
}

enum LayoutStatus { initial, loading, loaded, error }
```

#### FileExplorerState

```dart
class FileExplorerState extends Equatable {
  final FileTree? fileTree;
  final String? selectedPath;
  final FileExplorerStatus status;
  final String? errorMessage;
  
  const FileExplorerState({
    this.fileTree,
    this.selectedPath,
    this.status = FileExplorerStatus.initial,
    this.errorMessage,
  });
  
  FileExplorerState copyWith({...});
  
  @override
  List<Object?> get props => [fileTree, selectedPath, status, errorMessage];
}

enum FileExplorerStatus { initial, loading, loaded, error }
```

#### TabManagerState

```dart
class TabManagerState extends Equatable {
  final List<EditorTab> tabs;
  final String? activeTabId;
  final TabManagerStatus status;
  
  const TabManagerState({
    this.tabs = const [],
    this.activeTabId,
    this.status = TabManagerStatus.initial,
  });
  
  TabManagerState copyWith({...});
  
  EditorTab? get activeTab => 
    tabs.firstWhereOrNull((tab) => tab.id == activeTabId);
  
  bool get hasOpenTabs => tabs.isNotEmpty;
  
  @override
  List<Object?> get props => [tabs, activeTabId, status];
}

enum TabManagerStatus { initial, loading, loaded, error }
```

#### EditorContentState

```dart
class EditorContentState extends Equatable {
  final FileContent? content;
  final CursorPosition cursorPosition;
  final EditHistory editHistory;
  final bool isModified;
  final EditorContentStatus status;
  final String? errorMessage;
  
  const EditorContentState({
    this.content,
    this.cursorPosition = const CursorPosition(line: 1, column: 1, offset: 0),
    this.editHistory = const EditHistory(),
    this.isModified = false,
    this.status = EditorContentStatus.initial,
    this.errorMessage,
  });
  
  EditorContentState copyWith({...});
  
  @override
  List<Object?> get props => [
    content, cursorPosition, editHistory, isModified, status, errorMessage
  ];
}

enum EditorContentStatus { initial, loading, loaded, saving, saved, error }
```

#### StatusBarState

```dart
class StatusBarState extends Equatable {
  final int lineNumber;
  final int columnNumber;
  final int totalLines;
  final String encoding;
  final String language;
  final String? message;
  
  const StatusBarState({
    this.lineNumber = 1,
    this.columnNumber = 1,
    this.totalLines = 0,
    this.encoding = 'UTF-8',
    this.language = 'Plain Text',
    this.message,
  });
  
  StatusBarState copyWith({...});
  
  @override
  List<Object?> get props => [
    lineNumber, columnNumber, totalLines, encoding, language, message
  ];
}
```


## Use Cases

### Core Use Cases

#### LoadWorkspaceUseCase

```dart
class LoadWorkspaceUseCase {
  final WorkspaceRepository repository;
  
  LoadWorkspaceUseCase(this.repository);
  
  Future<Either<Failure, FileTree>> call(String workspacePath) async {
    if (!await repository.pathExists(workspacePath)) {
      return Left(InvalidPathFailure());
    }
    return await repository.loadWorkspace(workspacePath);
  }
}
```

**Responsibility**: Load và validate workspace directory structure

#### OpenTabUseCase

```dart
class OpenTabUseCase {
  final FileRepository fileRepository;
  final TabRepository tabRepository;
  
  OpenTabUseCase(this.fileRepository, this.tabRepository);
  
  Future<Either<Failure, EditorTab>> call(String filePath) async {
    // Check if file exists
    final contentResult = await fileRepository.readFile(filePath);
    
    return contentResult.fold(
      (failure) => Left(failure),
      (content) {
        final tab = EditorTab(
          id: Uuid().v4(),
          filePath: filePath,
          fileName: path.basename(filePath),
          openedAt: DateTime.now(),
        );
        return Right(tab);
      },
    );
  }
}
```

**Responsibility**: Create new tab khi mở file

#### CloseTabUseCase

```dart
class CloseTabUseCase {
  final TabRepository repository;
  
  CloseTabUseCase(this.repository);
  
  Future<Either<Failure, String?>> call({
    required List<EditorTab> tabs,
    required String tabIdToClose,
  }) async {
    final tabToClose = tabs.firstWhereOrNull((t) => t.id == tabIdToClose);
    
    if (tabToClose == null) {
      return Left(TabNotFoundFailure());
    }
    
    if (tabToClose.isModified) {
      // Return tab ID to trigger save confirmation dialog
      return Right(tabIdToClose.id);
    }
    
    // Find next active tab
    final currentIndex = tabs.indexOf(tabToClose);
    String? nextActiveTabId;
    
    if (tabs.length > 1) {
      if (currentIndex < tabs.length - 1) {
        nextActiveTabId = tabs[currentIndex + 1].id;
      } else if (currentIndex > 0) {
        nextActiveTabId = tabs[currentIndex - 1].id;
      }
    }
    
    return Right(nextActiveTabId);
  }
}
```

**Responsibility**: Handle tab closing logic và determine next active tab

#### LoadFileContentUseCase

```dart
class LoadFileContentUseCase {
  final FileRepository repository;
  
  LoadFileContentUseCase(this.repository);
  
  Future<Either<Failure, FileContent>> call(String filePath) async {
    return await repository.readFile(filePath);
  }
}
```

**Responsibility**: Load file content for editing

#### SaveFileUseCase

```dart
class SaveFileUseCase {
  final FileRepository repository;
  
  SaveFileUseCase(this.repository);
  
  Future<Either<Failure, void>> call({
    required String filePath,
    required String content,
  }) async {
    return await repository.writeFile(filePath, content);
  }
}
```

**Responsibility**: Save file content to disk

#### UndoUseCase

```dart
class UndoUseCase {
  Future<Either<Failure, UndoResult>> call({
    required EditHistory history,
    required String currentContent,
  }) async {
    if (!history.canUndo) {
      return Left(NoUndoHistoryFailure());
    }
    
    final lastAction = history.undoStack.last;
    final newUndoStack = List<EditAction>.from(history.undoStack)..removeLast();
    final newRedoStack = List<EditAction>.from(history.redoStack)..add(
      EditAction(
        oldContent: currentContent,
        newContent: lastAction.oldContent,
        oldPosition: lastAction.newPosition,
        newPosition: lastAction.oldPosition,
        timestamp: DateTime.now(),
      ),
    );
    
    return Right(UndoResult(
      content: lastAction.oldContent,
      cursorPosition: lastAction.oldPosition,
      newHistory: EditHistory(
        undoStack: newUndoStack,
        redoStack: newRedoStack,
      ),
    ));
  }
}

class UndoResult {
  final String content;
  final CursorPosition cursorPosition;
  final EditHistory newHistory;
  
  UndoResult({
    required this.content,
    required this.cursorPosition,
    required this.newHistory,
  });
}
```

**Responsibility**: Perform undo operation và update edit history

#### RedoUseCase

```dart
class RedoUseCase {
  Future<Either<Failure, RedoResult>> call({
    required EditHistory history,
    required String currentContent,
  }) async {
    if (!history.canRedo) {
      return Left(NoRedoHistoryFailure());
    }
    
    final lastAction = history.redoStack.last;
    final newRedoStack = List<EditAction>.from(history.redoStack)..removeLast();
    final newUndoStack = List<EditAction>.from(history.undoStack)..add(
      EditAction(
        oldContent: currentContent,
        newContent: lastAction.newContent,
        oldPosition: lastAction.oldPosition,
        newPosition: lastAction.newPosition,
        timestamp: DateTime.now(),
      ),
    );
    
    return Right(RedoResult(
      content: lastAction.newContent,
      cursorPosition: lastAction.newPosition,
      newHistory: EditHistory(
        undoStack: newUndoStack,
        redoStack: newRedoStack,
      ),
    ));
  }
}

class RedoResult {
  final String content;
  final CursorPosition cursorPosition;
  final EditHistory newHistory;
  
  RedoResult({
    required this.content,
    required this.cursorPosition,
    required this.newHistory,
  });
}
```

**Responsibility**: Perform redo operation và update edit history

#### ToggleSidebarUseCase

```dart
class ToggleSidebarUseCase {
  final LayoutRepository repository;
  
  ToggleSidebarUseCase(this.repository);
  
  Future<Either<Failure, bool>> call(bool currentVisibility) async {
    final newVisibility = !currentVisibility;
    await repository.saveLayoutPreferences(
      LayoutConfig(
        sidebarVisible: newVisibility,
        sidebarWidth: 250, // default or current width
        workspacePath: '',
      ),
    );
    return Right(newVisibility);
  }
}
```

**Responsibility**: Toggle sidebar visibility và persist preference

#### ResizeSidebarUseCase

```dart
class ResizeSidebarUseCase {
  final LayoutRepository repository;
  
  ResizeSidebarUseCase(this.repository);
  
  Future<Either<Failure, double>> call({
    required double newWidth,
    required double minWidth,
    required double maxWidth,
  }) async {
    final constrainedWidth = newWidth.clamp(minWidth, maxWidth);
    
    await repository.saveLayoutPreferences(
      LayoutConfig(
        sidebarVisible: true,
        sidebarWidth: constrainedWidth,
        workspacePath: '',
      ),
    );
    
    return Right(constrainedWidth);
  }
}
```

**Responsibility**: Resize sidebar với constraints và persist preference

#### GetFileIconUseCase

```dart
class GetFileIconUseCase {
  IconData call(String fileName, FileNodeType type) {
    if (type == FileNodeType.directory) {
      return Icons.folder;
    }
    
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.dart':
        return Icons.code; // Or custom Dart icon
      case '.json':
        return Icons.data_object;
      case '.yaml':
      case '.yml':
        return Icons.settings;
      case '.md':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}
```

**Responsibility**: Determine appropriate icon for file type

#### WatchFileChangesUseCase

```dart
class WatchFileChangesUseCase {
  final WorkspaceRepository repository;
  
  WatchFileChangesUseCase(this.repository);
  
  Stream<FileSystemEvent> call(String workspacePath) {
    return repository.watchWorkspace(workspacePath);
  }
}
```

**Responsibility**: Watch for file system changes trong workspace

### Use Case Dependencies

```
┌─────────────────────────────────────────────────────────┐
│                      Use Cases                           │
├─────────────────────────────────────────────────────────┤
│  LoadWorkspaceUseCase                                   │
│  OpenTabUseCase                                         │
│  CloseTabUseCase                                        │
│  LoadFileContentUseCase                                 │
│  SaveFileUseCase                                        │
│  UndoUseCase / RedoUseCase                              │
│  ToggleSidebarUseCase                                   │
│  ResizeSidebarUseCase                                   │
│  GetFileIconUseCase                                     │
│  WatchFileChangesUseCase                                │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   Repositories                           │
├─────────────────────────────────────────────────────────┤
│  WorkspaceRepository                                    │
│  FileRepository                                         │
│  TabRepository                                          │
│  LayoutRepository                                       │
└─────────────────────────────────────────────────────────┘
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Editor Area Width Invariant

*For any* layout state with visible sidebar, the editor area width SHALL equal the total layout width minus the sidebar width.

**Validates: Requirements 1.6**

### Property 2: Sidebar Resize Bounds Invariant

*For any* resize operation on the sidebar, the resulting width SHALL remain between 200 and 600 pixels inclusive.

**Validates: Requirements 1.4, 1.5, 2.2**

### Property 3: Sidebar Resize Proportional Adjustment

*For any* change in sidebar width, the editor area width SHALL adjust by the same amount in the opposite direction, maintaining total layout width.

**Validates: Requirements 2.3**

### Property 4: Sidebar Toggle Round-Trip

*For any* sidebar state, toggling visibility twice (hide then show, or show then hide) SHALL return the sidebar to its original visibility state and preserve its width.

**Validates: Requirements 3.1, 3.2, 3.4**

### Property 5: Hidden Sidebar Full Width

*For any* layout state where sidebar is hidden, the editor area width SHALL equal the total layout width.

**Validates: Requirements 3.3**

### Property 6: File Tree Structure Preservation

*For any* directory structure in the file system, the file explorer tree SHALL accurately represent the same hierarchical structure with all folders and files.

**Validates: Requirements 4.1**

### Property 7: File Icon Mapping Correctness

*For any* file or folder node, the displayed icon SHALL match the correct icon type based on the file extension or node type (folder, .dart, .json, .yaml, .yml, .md, or generic).

**Validates: Requirements 4.2, 4.3, 14.1, 14.2, 14.3, 14.4, 14.5, 14.6**

### Property 8: Folder Collapse Hides Children

*For any* folder node in collapsed state, none of its children SHALL be visible in the file explorer display.

**Validates: Requirements 4.4**

### Property 9: Folder Expand Shows Immediate Children

*For any* folder node in expanded state, all of its immediate children (but not grandchildren of collapsed children) SHALL be visible in the file explorer display.

**Validates: Requirements 4.5**

### Property 10: File Explorer Sorting Invariant

*For any* list of file nodes at the same tree level, the display order SHALL have all folders first (sorted alphabetically), followed by all files (sorted alphabetically).

**Validates: Requirements 4.6**

### Property 11: Folder Click Toggle Round-Trip

*For any* folder node, clicking it twice SHALL return the folder to its original expanded/collapsed state.

**Validates: Requirements 5.1**

### Property 12: File Click Opens Tab

*For any* file that is not currently open, clicking it in the file explorer SHALL create a new tab with the file name and path.

**Validates: Requirements 5.2, 6.2**

### Property 13: File Click Idempotence

*For any* file that is already open in a tab, clicking it again SHALL activate the existing tab without creating a duplicate tab.

**Validates: Requirements 5.3**

### Property 14: Tab Click Activation

*For any* tab in the tab bar, clicking it SHALL set that tab as the active tab.

**Validates: Requirements 6.3**

### Property 15: Tab Close Removal

*For any* tab in the tab bar, closing it SHALL remove that tab from the displayed tab list.

**Validates: Requirements 6.5, 7.2**

### Property 16: Active Tab Close Activation Logic

*For any* active tab that is closed when other tabs exist, the tab bar SHALL activate the nearest tab (next tab if available, otherwise previous tab).

**Validates: Requirements 7.3**

### Property 17: Active Tab Content Display

*For any* active tab, the editor area SHALL display the file content associated with that tab's file path.

**Validates: Requirements 8.1**

### Property 18: Line Number Display Accuracy

*For any* file content displayed in the editor, the line numbers shown SHALL accurately correspond to the actual line numbers in the content (1-indexed).

**Validates: Requirements 8.3**

### Property 19: Text Insertion at Cursor

*For any* cursor position and any typed character, inserting the character SHALL place it at the exact cursor position and advance the cursor by one position.

**Validates: Requirements 9.1**

### Property 20: Clipboard Round-Trip

*For any* selected text, performing copy followed by paste SHALL insert an exact copy of the selected text at the paste location.

**Validates: Requirements 9.4**

### Property 21: Undo-Redo Round-Trip

*For any* editor state and any edit operation, performing the edit, then undo, then redo SHALL return the editor to the state immediately after the original edit (same content and cursor position).

**Validates: Requirements 9.5**

### Property 22: Modified Indicator Accuracy

*For any* file content that has been changed from its saved state, the corresponding tab SHALL display a modified indicator; conversely, unmodified files SHALL NOT display the indicator.

**Validates: Requirements 9.6**

### Property 23: Status Bar Cursor Position Accuracy

*For any* cursor position in the active editor, the status bar SHALL display the correct line number and column number corresponding to that cursor position.

**Validates: Requirements 10.1, 10.2**

### Property 24: Status Bar File Information Accuracy

*For any* active file, the status bar SHALL display the correct total line count, file encoding, and detected language/file type.

**Validates: Requirements 10.3, 10.4, 10.5**

### Property 25: Keyboard Shortcut Sidebar Toggle

*For any* layout state, pressing Ctrl+B (Cmd+B on macOS) SHALL toggle the sidebar visibility.

**Validates: Requirements 11.1**

### Property 26: Keyboard Shortcut Tab Close

*For any* active tab, pressing Ctrl+W (Cmd+W on macOS) SHALL close that tab.

**Validates: Requirements 11.2**

### Property 27: Keyboard Tab Navigation Cycle

*For any* tab position in a non-empty tab list, pressing Ctrl+Tab SHALL activate the next tab (wrapping to first if at end), and pressing Ctrl+Shift+Tab SHALL activate the previous tab (wrapping to last if at beginning).

**Validates: Requirements 11.3, 11.4**

### Property 28: Keyboard Tab Index Navigation

*For any* tab list with N tabs, pressing Ctrl+[1-9] SHALL activate the tab at that index position (1-indexed) if it exists, otherwise no change occurs.

**Validates: Requirements 11.5**

### Property 29: Responsive Sidebar Auto-Hide

*For any* window width less than 800 pixels, the sidebar SHALL automatically hide regardless of its previous visibility state.

**Validates: Requirements 13.1**

### Property 30: Responsive Layout Proportional Adjustment

*For any* window resize event, all layout components SHALL adjust their dimensions proportionally to maintain proper layout ratios and constraints.

**Validates: Requirements 13.2**

### Property 31: Tab Bar Horizontal Scrolling

*For any* tab list where the total width of all tabs exceeds the available tab bar width, the tab bar SHALL enable horizontal scrolling to access all tabs.

**Validates: Requirements 13.3**

### Property 32: Maximized Window Full Space Utilization

*For any* maximized window state, the editor layout SHALL expand to utilize the full available window dimensions.

**Validates: Requirements 13.5**

### Property 33: Error Handling Display

*For any* error condition (unreadable file, invalid path, inaccessible workspace), the appropriate UI component SHALL display an error message or indicator, and the status bar SHALL show the error description.

**Validates: Requirements 15.1, 15.2, 15.3, 15.4**

### Property 34: Error Logging

*For any* error that occurs in the editor layout, the error SHALL be logged to the console with sufficient detail for debugging.

**Validates: Requirements 15.5**


## Error Handling

### Error Types

#### Domain Errors (Failures)

```dart
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure([String message = 'File not found']) 
    : super(message);
}

class FileReadFailure extends Failure {
  const FileReadFailure([String message = 'Failed to read file']) 
    : super(message);
}

class FileWriteFailure extends Failure {
  const FileWriteFailure([String message = 'Failed to write file']) 
    : super(message);
}

class InvalidPathFailure extends Failure {
  const InvalidPathFailure([String message = 'Invalid file path']) 
    : super(message);
}

class WorkspaceNotAccessibleFailure extends Failure {
  const WorkspaceNotAccessibleFailure([String message = 'Workspace not accessible']) 
    : super(message);
}

class TabNotFoundFailure extends Failure {
  const TabNotFoundFailure([String message = 'Tab not found']) 
    : super(message);
}

class NoUndoHistoryFailure extends Failure {
  const NoUndoHistoryFailure([String message = 'No undo history available']) 
    : super(message);
}

class NoRedoHistoryFailure extends Failure {
  const NoRedoHistoryFailure([String message = 'No redo history available']) 
    : super(message);
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure([String message = 'Permission denied']) 
    : super(message);
}
```

#### Data Layer Exceptions

```dart
class FileSystemException implements Exception {
  final String message;
  final String? path;
  
  FileSystemException(this.message, [this.path]);
  
  @override
  String toString() => 'FileSystemException: $message${path != null ? ' (path: $path)' : ''}';
}

class EncodingException implements Exception {
  final String message;
  
  EncodingException(this.message);
  
  @override
  String toString() => 'EncodingException: $message';
}
```

### Error Handling Strategy

#### Repository Layer

Repositories catch exceptions và convert thành Failures:

```dart
@override
Future<Either<Failure, FileContent>> readFile(String path) async {
  try {
    final file = File(path);
    
    if (!await file.exists()) {
      return Left(FileNotFoundFailure('File does not exist: $path'));
    }
    
    final content = await file.readAsString();
    final encoding = await _detectEncoding(file);
    final language = _detectLanguage(path);
    final lastModified = await file.lastModified();
    
    return Right(FileContent(
      path: path,
      content: content,
      encoding: encoding,
      language: language,
      lastModified: lastModified,
    ));
  } on FileSystemException catch (e) {
    return Left(FileReadFailure('Failed to read file: ${e.message}'));
  } on Exception catch (e) {
    return Left(FileReadFailure('Unexpected error: $e'));
  }
}
```

#### BLoC Layer

BLoCs handle Failures và emit appropriate error states:

```dart
on<LoadFileContent>((event, emit) async {
  emit(state.copyWith(status: EditorContentStatus.loading));
  
  final result = await loadFileContentUseCase(event.filePath);
  
  result.fold(
    (failure) => emit(state.copyWith(
      status: EditorContentStatus.error,
      errorMessage: failure.message,
    )),
    (content) => emit(state.copyWith(
      status: EditorContentStatus.loaded,
      content: content,
      errorMessage: null,
    )),
  );
});
```

#### Presentation Layer

UI widgets display errors to users:

```dart
BlocBuilder<EditorContentBloc, EditorContentState>(
  builder: (context, state) {
    if (state.status == EditorContentStatus.error) {
      return ErrorDisplay(
        message: state.errorMessage ?? 'An error occurred',
        onRetry: () => context.read<EditorContentBloc>().add(
          LoadFileContent(filePath: state.content?.path ?? ''),
        ),
      );
    }
    
    if (state.status == EditorContentStatus.loading) {
      return LoadingIndicator();
    }
    
    return TextEditorWidget(content: state.content);
  },
)
```

### Error Recovery

#### Retry Mechanism

```dart
class RetryableOperation<T> {
  final Future<T> Function() operation;
  final int maxRetries;
  final Duration retryDelay;
  
  RetryableOperation({
    required this.operation,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });
  
  Future<T> execute() async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(retryDelay);
      }
    }
    
    throw Exception('Max retries exceeded');
  }
}
```

#### Graceful Degradation

- Nếu workspace không load được, hiển thị empty state với option để chọn workspace khác
- Nếu file không đọc được, hiển thị error message trong editor area nhưng vẫn giữ tab
- Nếu save thất bại, giữ modified state và cho phép retry
- Nếu file system watcher fails, fallback to manual refresh

### Logging Strategy

```dart
class EditorLogger {
  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'EditorLayout',
      error: error,
      stackTrace: stackTrace,
      level: Level.SEVERE.value,
    );
  }
  
  static void logWarning(String message) {
    developer.log(
      message,
      name: 'EditorLayout',
      level: Level.WARNING.value,
    );
  }
  
  static void logInfo(String message) {
    developer.log(
      message,
      name: 'EditorLayout',
      level: Level.INFO.value,
    );
  }
}
```

Usage trong repositories:

```dart
try {
  // operation
} catch (e, stackTrace) {
  EditorLogger.logError('Failed to read file: $path', e, stackTrace);
  return Left(FileReadFailure());
}
```

## Testing Strategy

### Testing Approach

Ứng dụng sử dụng dual testing approach kết hợp unit tests và property-based tests để đảm bảo comprehensive coverage:

- **Unit Tests**: Verify specific examples, edge cases, và error conditions
- **Property-Based Tests**: Verify universal properties across all inputs
- Both approaches are complementary và necessary for complete validation

### Unit Testing

Unit tests focus on:
- Specific examples demonstrating correct behavior
- Integration points between components
- Edge cases và boundary conditions
- Error handling scenarios

**Testing Layers:**

#### Domain Layer Testing

Test entities, use cases, và business logic:

```dart
// Example: Use Case Test
void main() {
  group('CloseTabUseCase', () {
    late CloseTabUseCase useCase;
    late MockTabRepository mockRepository;
    
    setUp(() {
      mockRepository = MockTabRepository();
      useCase = CloseTabUseCase(mockRepository);
    });
    
    test('should return next tab ID when closing middle tab', () async {
      // Arrange
      final tabs = [
        EditorTab(id: '1', filePath: '/a.dart', fileName: 'a.dart', openedAt: DateTime.now()),
        EditorTab(id: '2', filePath: '/b.dart', fileName: 'b.dart', openedAt: DateTime.now(), isActive: true),
        EditorTab(id: '3', filePath: '/c.dart', fileName: 'c.dart', openedAt: DateTime.now()),
      ];
      
      // Act
      final result = await useCase(tabs: tabs, tabIdToClose: '2');
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (nextTabId) => expect(nextTabId, '3'),
      );
    });
    
    test('should return previous tab ID when closing last tab', () async {
      // Arrange
      final tabs = [
        EditorTab(id: '1', filePath: '/a.dart', fileName: 'a.dart', openedAt: DateTime.now()),
        EditorTab(id: '2', filePath: '/b.dart', fileName: 'b.dart', openedAt: DateTime.now(), isActive: true),
      ];
      
      // Act
      final result = await useCase(tabs: tabs, tabIdToClose: '2');
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (nextTabId) => expect(nextTabId, '1'),
      );
    });
    
    test('should return null when closing the only tab', () async {
      // Arrange
      final tabs = [
        EditorTab(id: '1', filePath: '/a.dart', fileName: 'a.dart', openedAt: DateTime.now(), isActive: true),
      ];
      
      // Act
      final result = await useCase(tabs: tabs, tabIdToClose: '1');
      
      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (nextTabId) => expect(nextTabId, null),
      );
    });
  });
}
```

#### BLoC Testing

Test BLoC events và state transitions using bloc_test:

```dart
void main() {
  group('TabManagerBloc', () {
    late TabManagerBloc bloc;
    late MockOpenTabUseCase mockOpenTab;
    late MockCloseTabUseCase mockCloseTab;
    
    setUp(() {
      mockOpenTab = MockOpenTabUseCase();
      mockCloseTab = MockCloseTabUseCase();
      bloc = TabManagerBloc(
        openTab: mockOpenTab,
        closeTab: mockCloseTab,
      );
    });
    
    blocTest<TabManagerBloc, TabManagerState>(
      'emits [loading, loaded] when OpenTab succeeds',
      build: () {
        when(() => mockOpenTab(any())).thenAnswer(
          (_) async => Right(EditorTab(
            id: '1',
            filePath: '/test.dart',
            fileName: 'test.dart',
            openedAt: DateTime.now(),
          )),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(OpenTab(filePath: '/test.dart')),
      expect: () => [
        TabManagerState(status: TabManagerStatus.loading),
        TabManagerState(
          status: TabManagerStatus.loaded,
          tabs: [
            EditorTab(
              id: '1',
              filePath: '/test.dart',
              fileName: 'test.dart',
              openedAt: DateTime.now(),
            ),
          ],
          activeTabId: '1',
        ),
      ],
    );
    
    blocTest<TabManagerBloc, TabManagerState>(
      'emits [error] when OpenTab fails',
      build: () {
        when(() => mockOpenTab(any())).thenAnswer(
          (_) async => Left(FileNotFoundFailure()),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(OpenTab(filePath: '/nonexistent.dart')),
      expect: () => [
        TabManagerState(status: TabManagerStatus.loading),
        TabManagerState(
          status: TabManagerStatus.error,
          errorMessage: 'File not found',
        ),
      ],
    );
  });
}
```

#### Widget Testing

Test UI components và interactions:

```dart
void main() {
  group('TabBarWidget', () {
    testWidgets('displays all tabs', (tester) async {
      // Arrange
      final tabs = [
        EditorTab(id: '1', filePath: '/a.dart', fileName: 'a.dart', openedAt: DateTime.now()),
        EditorTab(id: '2', filePath: '/b.dart', fileName: 'b.dart', openedAt: DateTime.now()),
      ];
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: TabBarWidget(tabs: tabs, activeTabId: '1'),
        ),
      );
      
      // Assert
      expect(find.text('a.dart'), findsOneWidget);
      expect(find.text('b.dart'), findsOneWidget);
    });
    
    testWidgets('highlights active tab', (tester) async {
      // Arrange
      final tabs = [
        EditorTab(id: '1', filePath: '/a.dart', fileName: 'a.dart', openedAt: DateTime.now()),
        EditorTab(id: '2', filePath: '/b.dart', fileName: 'b.dart', openedAt: DateTime.now()),
      ];
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: TabBarWidget(tabs: tabs, activeTabId: '1'),
        ),
      );
      
      // Assert
      final activeTab = tester.widget<Container>(
        find.ancestor(
          of: find.text('a.dart'),
          matching: find.byType(Container),
        ).first,
      );
      
      expect(activeTab.decoration, isA<BoxDecoration>());
      // Verify active tab has distinct styling
    });
  });
}
```

### Property-Based Testing

Property-based tests verify universal properties across randomized inputs. Sử dụng **test** package với custom property testing utilities hoặc third-party packages như **glados**.

**Configuration:**
- Minimum 100 iterations per property test
- Each test references its design document property
- Tag format: `Feature: vscode-like-editor-layout, Property {number}: {property_text}`

**Example Property Tests:**

```dart
// Property 2: Sidebar Resize Bounds Invariant
void main() {
  group('Property Tests', () {
    test(
      'Property 2: Sidebar width remains between 200-600 pixels for any resize',
      () {
        // Feature: vscode-like-editor-layout, Property 2: Sidebar Resize Bounds Invariant
        
        final random = Random();
        
        for (int i = 0; i < 100; i++) {
          // Generate random resize attempt
          final attemptedWidth = random.nextDouble() * 1000; // 0-1000 pixels
          
          // Apply resize with constraints
          final actualWidth = attemptedWidth.clamp(200.0, 600.0);
          
          // Assert invariant holds
          expect(actualWidth, greaterThanOrEqualTo(200.0));
          expect(actualWidth, lessThanOrEqualTo(600.0));
        }
      },
    );
    
    // Property 4: Sidebar Toggle Round-Trip
    test(
      'Property 4: Toggle sidebar twice returns to original state',
      () {
        // Feature: vscode-like-editor-layout, Property 4: Sidebar Toggle Round-Trip
        
        final random = Random();
        
        for (int i = 0; i < 100; i++) {
          // Generate random initial state
          final initialVisible = random.nextBool();
          final initialWidth = 200.0 + random.nextDouble() * 400.0; // 200-600
          
          // Simulate toggle twice
          final afterFirstToggle = !initialVisible;
          final afterSecondToggle = !afterFirstToggle;
          
          // Assert round-trip property
          expect(afterSecondToggle, equals(initialVisible));
          // Width should be preserved
          expect(initialWidth, equals(initialWidth)); // Simplified for example
        }
      },
    );
    
    // Property 10: File Explorer Sorting Invariant
    test(
      'Property 10: Files are sorted with folders first, then alphabetically',
      () {
        // Feature: vscode-like-editor-layout, Property 10: File Explorer Sorting Invariant
        
        final random = Random();
        
        for (int i = 0; i < 100; i++) {
          // Generate random list of files and folders
          final nodes = <FileNode>[];
          final numNodes = 5 + random.nextInt(20); // 5-25 nodes
          
          for (int j = 0; j < numNodes; j++) {
            final isFolder = random.nextBool();
            final name = String.fromCharCodes(
              List.generate(5, (_) => 97 + random.nextInt(26)), // a-z
            );
            
            nodes.add(FileNode(
              name: name,
              path: '/$name',
              type: isFolder ? FileNodeType.directory : FileNodeType.file,
            ));
          }
          
          // Sort using the sorting logic
          final sorted = sortFileNodes(nodes);
          
          // Assert invariant: all folders come before all files
          int lastFolderIndex = -1;
          int firstFileIndex = sorted.length;
          
          for (int k = 0; k < sorted.length; k++) {
            if (sorted[k].type == FileNodeType.directory) {
              lastFolderIndex = k;
            } else {
              if (firstFileIndex == sorted.length) {
                firstFileIndex = k;
              }
            }
          }
          
          expect(lastFolderIndex < firstFileIndex || lastFolderIndex == -1 || firstFileIndex == sorted.length, true);
          
          // Assert alphabetical order within each group
          final folders = sorted.where((n) => n.type == FileNodeType.directory).toList();
          final files = sorted.where((n) => n.type == FileNodeType.file).toList();
          
          expect(isSortedAlphabetically(folders), true);
          expect(isSortedAlphabetically(files), true);
        }
      },
    );
    
    // Property 21: Undo-Redo Round-Trip
    test(
      'Property 21: Edit -> Undo -> Redo returns to post-edit state',
      () {
        // Feature: vscode-like-editor-layout, Property 21: Undo-Redo Round-Trip
        
        final random = Random();
        
        for (int i = 0; i < 100; i++) {
          // Generate random initial content
          final initialContent = generateRandomText(random, 100);
          final initialCursor = CursorPosition(
            line: 1 + random.nextInt(10),
            column: 1 + random.nextInt(50),
            offset: random.nextInt(100),
          );
          
          // Simulate edit
          final editedContent = initialContent + generateRandomText(random, 10);
          final editedCursor = CursorPosition(
            line: initialCursor.line,
            column: initialCursor.column + 10,
            offset: initialCursor.offset + 10,
          );
          
          // Create edit history
          final history = EditHistory(
            undoStack: [
              EditAction(
                oldContent: initialContent,
                newContent: editedContent,
                oldPosition: initialCursor,
                newPosition: editedCursor,
                timestamp: DateTime.now(),
              ),
            ],
          );
          
          // Simulate undo
          final undoResult = performUndo(history, editedContent);
          expect(undoResult.content, equals(initialContent));
          expect(undoResult.cursorPosition, equals(initialCursor));
          
          // Simulate redo
          final redoResult = performRedo(undoResult.newHistory, undoResult.content);
          expect(redoResult.content, equals(editedContent));
          expect(redoResult.cursorPosition, equals(editedCursor));
        }
      },
    );
  });
}

// Helper functions
List<FileNode> sortFileNodes(List<FileNode> nodes) {
  final folders = nodes.where((n) => n.type == FileNodeType.directory).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  final files = nodes.where((n) => n.type == FileNodeType.file).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return [...folders, ...files];
}

bool isSortedAlphabetically(List<FileNode> nodes) {
  for (int i = 0; i < nodes.length - 1; i++) {
    if (nodes[i].name.compareTo(nodes[i + 1].name) > 0) {
      return false;
    }
  }
  return true;
}

String generateRandomText(Random random, int length) {
  return String.fromCharCodes(
    List.generate(length, (_) => 32 + random.nextInt(95)), // printable ASCII
  );
}
```

### Integration Testing

Integration tests verify end-to-end workflows:

```dart
void main() {
  group('Editor Layout Integration Tests', () {
    testWidgets('complete file opening workflow', (tester) async {
      // Setup
      await tester.pumpWidget(MyApp());
      
      // Open file from explorer
      await tester.tap(find.text('test.dart'));
      await tester.pumpAndSettle();
      
      // Verify tab created
      expect(find.text('test.dart'), findsNWidgets(2)); // In explorer and tab
      
      // Verify content loaded
      expect(find.byType(TextEditorWidget), findsOneWidget);
      
      // Edit content
      await tester.enterText(find.byType(TextField), 'new content');
      await tester.pumpAndSettle();
      
      // Verify modified indicator
      expect(find.byIcon(Icons.circle), findsOneWidget); // Modified dot
      
      // Close tab
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      
      // Verify tab removed
      expect(find.text('test.dart'), findsOneWidget); // Only in explorer
    });
  });
}
```

### Test Coverage Goals

- **Unit Tests**: 80%+ code coverage
- **Property Tests**: All correctness properties implemented
- **Integration Tests**: All major user workflows covered
- **Widget Tests**: All UI components tested

### Continuous Testing

- Run unit tests on every commit
- Run property tests (with reduced iterations) in CI pipeline
- Run full property test suite (100+ iterations) nightly
- Run integration tests before releases

