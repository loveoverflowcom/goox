# Requirements Document

## Introduction

Refactor file `editor_layout_views.dart` để cải thiện hiệu suất render và khả năng bảo trì code. File hiện tại có 450+ dòng với các method build lớn và builder inline phức tạp, gây ra rebuild không cần thiết và khó bảo trì. Refactoring sẽ tách các component thành widget riêng biệt và sử dụng part/part of để tổ chức code tốt hơn.

## Glossary

- **EditorLayoutView**: Widget chính chứa toàn bộ layout của editor
- **Sidebar**: Thanh bên chứa các tab (Explorer, Search, Source Control, Extensions, Settings)
- **ResizeHandle**: Widget cho phép người dùng kéo để thay đổi kích thước sidebar
- **EditorArea**: Vùng chính hiển thị nội dung file đang chỉnh sửa
- **DestinationTab**: Một tab trong sidebar (ví dụ: Explorer, Search)
- **Widget**: Component UI trong Flutter
- **Rebuild**: Quá trình Flutter vẽ lại widget khi state thay đổi
- **Part/Part of**: Cơ chế của Dart để tách một file lớn thành nhiều file nhỏ hơn
- **Theme**: Đối tượng chứa thông tin về màu sắc và style của UI
- **EditorThemeExtension**: Extension chứa theme riêng cho editor

## Requirements

### Requirement 1: Tách Sidebar Widget

**User Story:** Là một developer, tôi muốn sidebar được tách thành widget riêng, để tối ưu rebuild performance và dễ bảo trì code hơn.

#### Acceptance Criteria

1. THE System SHALL tạo widget mới `_SidebarWidget` trong file riêng biệt sử dụng part/part of
2. WHEN sidebar width thay đổi, THE _SidebarWidget SHALL rebuild mà không ảnh hưởng đến EditorArea
3. THE _SidebarWidget SHALL nhận `width` và `contentWidth` qua constructor parameters
4. THE _SidebarWidget SHALL chứa toàn bộ logic hiện tại của method `_buildSidebar`
5. THE _SidebarWidget SHALL sử dụng `const` constructor khi có thể để tối ưu performance

### Requirement 2: Tách ResizeHandle Widget

**User Story:** Là một developer, tôi muốn resize handle được tách thành widget riêng, để code dễ đọc và tái sử dụng hơn.

#### Acceptance Criteria

1. THE System SHALL tạo widget mới `_ResizeHandleWidget` trong file riêng biệt sử dụng part/part of
2. THE _ResizeHandleWidget SHALL xử lý drag gesture để resize sidebar
3. THE _ResizeHandleWidget SHALL thay đổi cursor thành resize icon khi hover
4. THE _ResizeHandleWidget SHALL sử dụng `const` constructor
5. WHEN user kéo resize handle, THE _ResizeHandleWidget SHALL dispatch ResizeSidebarEvent đến EditorLayoutBloc

### Requirement 3: Tách EditorArea Widget

**User Story:** Là một developer, tôi muốn editor area được tách thành widget riêng, để tách biệt concerns và tối ưu rebuild.

#### Acceptance Criteria

1. THE System SHALL tạo widget mới `_EditorAreaWidget` trong file riêng biệt sử dụng part/part of
2. THE _EditorAreaWidget SHALL chứa TabBarWidget và TextEditorWidget
3. THE _EditorAreaWidget SHALL sử dụng `const` constructor
4. WHEN tab thay đổi, THE _EditorAreaWidget SHALL rebuild chỉ phần cần thiết
5. THE _EditorAreaWidget SHALL lấy theme một lần và truyền xuống children nếu cần

### Requirement 4: Tách Destination Tab Builders

**User Story:** Là một developer, tôi muốn mỗi destination tab (Explorer, Search, Source Control, Extensions, Settings) được tách thành widget riêng, để code dễ bảo trì và mở rộng.

#### Acceptance Criteria

1. THE System SHALL tạo widget `_ExplorerTabContent` cho Explorer tab
2. THE System SHALL tạo widget `_SearchTabContent` cho Search tab
3. THE System SHALL tạo widget `_SourceControlTabContent` cho Source Control tab
4. THE System SHALL tạo widget `_ExtensionsTabContent` cho Extensions tab
5. THE System SHALL tạo widget `_SettingsTabContent` cho Settings tab
6. WHEN một tab được chọn, THE System SHALL chỉ build widget của tab đó
7. THE System SHALL đặt tất cả tab content widgets trong file riêng biệt sử dụng part/part of
8. WHERE tab content cần theme, THE widget SHALL nhận EditorThemeExtension qua parameter thay vì gọi Theme.of(context) nhiều lần

### Requirement 5: Tối Ưu Theme Access

**User Story:** Là một developer, tôi muốn theme được truy cập hiệu quả, để tránh rebuild không cần thiết khi theme không thay đổi.

#### Acceptance Criteria

1. THE System SHALL lấy EditorThemeExtension một lần ở widget cha
2. THE System SHALL truyền theme xuống children widgets qua constructor parameters
3. THE System SHALL tránh gọi `Theme.of(context).extension<EditorThemeExtension>()` nhiều lần trong cùng một widget tree
4. WHEN theme thay đổi, THE System SHALL rebuild chỉ các widget cần theme mới
5. THE System SHALL sử dụng Builder widget chỉ khi thực sự cần thiết để lấy context mới

### Requirement 6: Tổ Chức File Structure với Part/Part of

**User Story:** Là một developer, tôi muốn file lớn được tách thành nhiều file nhỏ sử dụng part/part of, để dễ navigate và bảo trì code.

#### Acceptance Criteria

1. THE System SHALL giữ file chính `editor_layout_views.dart` chứa EditorLayoutView và _EditorLayoutView
2. THE System SHALL tạo file `editor_layout_views_sidebar.dart` chứa _SidebarWidget
3. THE System SHALL tạo file `editor_layout_views_resize_handle.dart` chứa _ResizeHandleWidget
4. THE System SHALL tạo file `editor_layout_views_editor_area.dart` chứa _EditorAreaWidget
5. THE System SHALL tạo file `editor_layout_views_tab_contents.dart` chứa tất cả tab content widgets
6. THE System SHALL sử dụng `part 'filename.dart';` trong file chính
7. THE System SHALL sử dụng `part of 'editor_layout_views.dart';` trong các file part
8. THE System SHALL đảm bảo tất cả imports chỉ có trong file chính, không có trong các file part

### Requirement 7: Maintain Existing Functionality

**User Story:** Là một user, tôi muốn tất cả chức năng hiện tại hoạt động như cũ sau refactoring, để không bị gián đoạn workflow.

#### Acceptance Criteria

1. THE System SHALL giữ nguyên tất cả keyboard shortcuts (Ctrl+B, Ctrl+`, Ctrl+W, Ctrl+Tab, Ctrl+Shift+Tab)
2. THE System SHALL giữ nguyên chức năng resize sidebar bằng cách kéo handle
3. THE System SHALL giữ nguyên chức năng toggle sidebar visibility
4. THE System SHALL giữ nguyên chức năng mở file từ Explorer
5. THE System SHALL giữ nguyên chức năng sync modified state giữa EditorContentBloc và TabManagerBloc
6. THE System SHALL giữ nguyên chức năng load content khi active tab thay đổi
7. THE System SHALL giữ nguyên layout và visual appearance
8. WHEN refactoring hoàn tất, THE System SHALL compile và run không có errors

### Requirement 8: Performance Optimization

**User Story:** Là một user, tôi muốn UI render nhanh hơn và mượt mà hơn, để có trải nghiệm sử dụng tốt hơn.

#### Acceptance Criteria

1. WHEN sidebar width thay đổi, THE System SHALL chỉ rebuild _SidebarWidget và _ResizeHandleWidget, không rebuild _EditorAreaWidget
2. WHEN tab content thay đổi, THE System SHALL chỉ rebuild tab content widget đang active
3. WHEN theme được truy cập, THE System SHALL cache và reuse EditorThemeExtension instance trong cùng một build cycle
4. THE System SHALL sử dụng `const` constructor cho tất cả widgets có thể
5. THE System SHALL tránh tạo anonymous functions trong build methods (ví dụ: `(context) => Widget()`)

