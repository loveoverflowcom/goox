# Hướng dẫn sử dụng VSCode-like Editor (Clean Architecture + BLoC)

## Kiến trúc

Dự án được xây dựng theo Clean Architecture với BLoC pattern:

```
lib/
├── core/                           # Core utilities, theme, constants
│   ├── constants/
│   ├── theme/
│   ├── errors/
│   └── di/                         # Dependency Injection
├── features/                       # Feature modules
│   ├── editor_layout/              # Layout management
│   │   ├── domain/
│   │   ├── presentation/
│   │   │   ├── bloc/
│   │   │   ├── pages/
│   │   │   └── widgets/
│   ├── file_explorer/              # File tree navigation
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── tab_manager/                # Tab management
│   │   ├── domain/
│   │   └── presentation/
│   ├── editor_content/             # File editing
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── status_bar/                 # Status information
│       └── presentation/
└── main.dart
```

## Cài đặt và chạy

### Bước 1: Cài đặt dependencies

```bash
flutter pub get
```

### Bước 2: Cập nhật đường dẫn workspace

Mở file `lib/main.dart` và thay đổi đường dẫn workspace:

```dart
home: const EditorLayoutPage(
  workspacePath: '/Users/your-username/Documents/my-project',
),
```

### Bước 3: Chạy ứng dụng

```bash
flutter run
```

## Kiến trúc BLoC

### BLoCs chính

1. **EditorLayoutBloc**: Quản lý layout (sidebar visibility, width)
2. **FileExplorerBloc**: Quản lý file tree và navigation
3. **TabManagerBloc**: Quản lý tabs (open, close, activate)
4. **EditorContentBloc**: Quản lý file content và editing

### Data Flow

```
User Action → Event → BLoC → State → UI Update
```

### BLoC Communication

- EditorContentBloc ↔ TabManagerBloc: Sync modified state
- FileExplorerBloc → TabManagerBloc: Open file
- TabManagerBloc → EditorContentBloc: Load content

## Tính năng

### 1. File Explorer (Sidebar)
- Hiển thị cây thư mục
- Click folder để expand/collapse
- Click file để mở trong editor
- Icon theo loại file

### 2. Tab Management
- Mở nhiều file trong tabs
- Click tab để chuyển
- Close button khi hover
- Modified indicator (chấm trắng)

### 3. Text Editor
- Chỉnh sửa text
- Line numbers
- Scrolling
- Auto-sync với tab state

### 4. Status Bar
- Line/Column number
- File type
- Encoding
- Total lines
- Modified status

### 5. Phím tắt

| Phím tắt | Chức năng |
|----------|-----------|
| `Ctrl/Cmd + B` | Ẩn/hiện sidebar |
| `Ctrl/Cmd + W` | Đóng tab hiện tại |
| `Ctrl + Tab` | Tab tiếp theo |
| `Ctrl + Shift + Tab` | Tab trước |

### 6. Resize Sidebar
- Kéo viền phải sidebar để resize (200-600px)

## Dependencies

- **flutter_bloc**: State management
- **equatable**: Value equality
- **get_it**: Dependency injection
- **dartz**: Functional programming (Either)
- **path**: Path manipulation
- **uuid**: Unique IDs
- **shared_preferences**: Local storage

## Design Principles

1. **Separation of Concerns**: Domain, Data, Presentation layers
2. **Single Responsibility**: Mỗi BLoC có một nhiệm vụ rõ ràng
3. **Dependency Inversion**: Depend on abstractions (repositories)
4. **Testability**: BLoCs có thể test độc lập
5. **Scalability**: Dễ dàng thêm features mới

## Lưu ý

- Đường dẫn workspace phải tồn tại
- App cần quyền đọc/ghi file
- BLoCs được quản lý bởi GetIt (Dependency Injection)
- State được quản lý immutable với Equatable

## Troubleshooting

### Không thấy file trong explorer
- Kiểm tra đường dẫn workspace
- Kiểm tra quyền truy cập

### Tab không mở file
- Kiểm tra FileExplorerBloc và TabManagerBloc logs
- Đảm bảo file có quyền đọc

### Modified state không sync
- Kiểm tra BlocListener trong EditorLayoutPage
- Verify EditorContentBloc emits correct state

