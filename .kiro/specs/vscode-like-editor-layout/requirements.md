# Requirements Document

## Introduction

Tài liệu này mô tả các yêu cầu cho tính năng VSCode-like Editor Layout trong ứng dụng Flutter goox. Tính năng này cung cấp một giao diện editor tương tự VSCode với sidebar, editor area, tab system, và status bar, cho phép người dùng quản lý và chỉnh sửa nhiều file trong một workspace.

## Glossary

- **Editor_Layout**: Widget chính chứa toàn bộ layout của editor
- **Sidebar**: Panel bên trái hiển thị file explorer và các công cụ khác
- **File_Explorer**: Component trong Sidebar hiển thị cây thư mục và file
- **Editor_Area**: Vùng trung tâm hiển thị nội dung file đang được chỉnh sửa
- **Tab_Bar**: Component quản lý và hiển thị các tab của file đang mở
- **Tab**: Đại diện cho một file đang mở trong Editor_Area
- **Status_Bar**: Thanh trạng thái ở dưới cùng hiển thị thông tin về editor
- **Active_Tab**: Tab hiện đang được hiển thị trong Editor_Area
- **Workspace**: Thư mục gốc chứa các file và folder được hiển thị trong File_Explorer

## Requirements

### Requirement 1: Layout Structure

**User Story:** Là một developer, tôi muốn có một layout editor với các thành phần chính được sắp xếp hợp lý, để tôi có thể dễ dàng điều hướng và làm việc với code.

#### Acceptance Criteria

1. THE Editor_Layout SHALL contain a Sidebar on the left side
2. THE Editor_Layout SHALL contain an Editor_Area in the center
3. THE Editor_Layout SHALL contain a Status_Bar at the bottom
4. THE Sidebar SHALL have a minimum width of 200 pixels
5. THE Sidebar SHALL have a maximum width of 600 pixels
6. THE Editor_Area SHALL occupy all remaining horizontal space after Sidebar

### Requirement 2: Sidebar Resizing

**User Story:** Là một developer, tôi muốn thay đổi kích thước sidebar, để tôi có thể điều chỉnh không gian làm việc phù hợp với nhu cầu.

#### Acceptance Criteria

1. WHEN the user drags the Sidebar right edge, THE Editor_Layout SHALL resize the Sidebar width
2. WHILE resizing, THE Sidebar width SHALL remain between 200 and 600 pixels
3. WHEN the Sidebar is resized, THE Editor_Area SHALL adjust its width accordingly
4. THE Sidebar SHALL display a visual indicator on its right edge to show it is resizable

### Requirement 3: Sidebar Toggle

**User Story:** Là một developer, tôi muốn ẩn/hiện sidebar, để tôi có thể tối đa hóa không gian cho editor khi cần.

#### Acceptance Criteria

1. WHEN the user clicks the sidebar toggle button, THE Editor_Layout SHALL hide the Sidebar
2. WHEN the Sidebar is hidden and user clicks the toggle button, THE Editor_Layout SHALL show the Sidebar
3. WHEN the Sidebar is hidden, THE Editor_Area SHALL expand to use the full width
4. THE Editor_Layout SHALL preserve the Sidebar width when toggling visibility

### Requirement 4: File Explorer Display

**User Story:** Là một developer, tôi muốn xem cây thư mục và file trong workspace, để tôi có thể dễ dàng tìm và mở file cần chỉnh sửa.

#### Acceptance Criteria

1. THE File_Explorer SHALL display the Workspace directory structure as a tree
2. THE File_Explorer SHALL display folder names with a folder icon
3. THE File_Explorer SHALL display file names with appropriate file type icons
4. WHEN a folder is collapsed, THE File_Explorer SHALL hide its children
5. WHEN a folder is expanded, THE File_Explorer SHALL show its immediate children
6. THE File_Explorer SHALL sort items with folders first, then files alphabetically

### Requirement 5: File Explorer Interaction

**User Story:** Là một developer, tôi muốn tương tác với file explorer, để tôi có thể mở file và điều hướng trong cây thư mục.

#### Acceptance Criteria

1. WHEN the user clicks on a folder, THE File_Explorer SHALL toggle its expanded/collapsed state
2. WHEN the user clicks on a file, THE Editor_Layout SHALL open the file in a new Tab
3. WHEN a file is already open and user clicks on it, THE Editor_Layout SHALL activate its existing Tab
4. THE File_Explorer SHALL highlight the selected item
5. WHEN the user hovers over an item, THE File_Explorer SHALL show a hover effect

### Requirement 6: Tab Management

**User Story:** Là một developer, tôi muốn quản lý nhiều file đang mở qua tab system, để tôi có thể dễ dàng chuyển đổi giữa các file.

#### Acceptance Criteria

1. THE Tab_Bar SHALL display all open Tabs horizontally
2. WHEN a file is opened, THE Tab_Bar SHALL create a new Tab with the file name
3. WHEN a Tab is clicked, THE Editor_Layout SHALL set it as the Active_Tab
4. THE Tab_Bar SHALL visually distinguish the Active_Tab from other Tabs
5. WHEN a Tab is closed, THE Tab_Bar SHALL remove it from display
6. IF all Tabs are closed, THEN THE Editor_Area SHALL display a welcome message

### Requirement 7: Tab Closing

**User Story:** Là một developer, tôi muốn đóng các tab không cần thiết, để tôi có thể giữ workspace gọn gàng.

#### Acceptance Criteria

1. THE Tab SHALL display a close button when hovered
2. WHEN the user clicks the Tab close button, THE Tab_Bar SHALL close that Tab
3. WHEN a Tab is closed and it was the Active_Tab, THE Tab_Bar SHALL activate the nearest Tab
4. WHEN the last Tab is closed, THE Editor_Area SHALL clear its content
5. THE Tab_Bar SHALL support closing Tabs via middle mouse button click

### Requirement 8: Editor Content Display

**User Story:** Là một developer, tôi muốn xem nội dung file trong editor area, để tôi có thể đọc và chỉnh sửa code.

#### Acceptance Criteria

1. WHEN a Tab is active, THE Editor_Area SHALL display the file content
2. THE Editor_Area SHALL display text content with monospace font
3. THE Editor_Area SHALL display line numbers on the left side
4. THE Editor_Area SHALL support vertical scrolling for long files
5. THE Editor_Area SHALL support horizontal scrolling for long lines
6. THE Editor_Area SHALL display the file path in the editor header

### Requirement 9: Text Editing

**User Story:** Là một developer, tôi muốn chỉnh sửa nội dung file, để tôi có thể thực hiện các thay đổi code.

#### Acceptance Criteria

1. WHEN the user types in the Editor_Area, THE Editor_Area SHALL insert the typed characters at cursor position
2. THE Editor_Area SHALL support text selection via mouse drag
3. THE Editor_Area SHALL support text selection via keyboard shortcuts
4. THE Editor_Area SHALL support copy, cut, and paste operations
5. THE Editor_Area SHALL support undo and redo operations
6. WHEN file content is modified, THE Tab SHALL display a modified indicator

### Requirement 10: Status Bar Information

**User Story:** Là một developer, tôi muốn xem thông tin về trạng thái editor, để tôi có thể biết vị trí cursor và các thông tin khác.

#### Acceptance Criteria

1. THE Status_Bar SHALL display the current cursor line number
2. THE Status_Bar SHALL display the current cursor column number
3. THE Status_Bar SHALL display the total number of lines in the active file
4. THE Status_Bar SHALL display the file encoding
5. THE Status_Bar SHALL display the file type or language
6. WHEN no file is open, THE Status_Bar SHALL display default status information

### Requirement 11: Keyboard Navigation

**User Story:** Là một developer, tôi muốn sử dụng phím tắt để điều hướng, để tôi có thể làm việc hiệu quả hơn.

#### Acceptance Criteria

1. WHEN the user presses Ctrl+B (Cmd+B on macOS), THE Editor_Layout SHALL toggle Sidebar visibility
2. WHEN the user presses Ctrl+W (Cmd+W on macOS), THE Tab_Bar SHALL close the Active_Tab
3. WHEN the user presses Ctrl+Tab, THE Tab_Bar SHALL activate the next Tab
4. WHEN the user presses Ctrl+Shift+Tab, THE Tab_Bar SHALL activate the previous Tab
5. WHEN the user presses Ctrl+1 through Ctrl+9, THE Tab_Bar SHALL activate the corresponding Tab by index

### Requirement 12: Theme Support

**User Story:** Là một developer, tôi muốn editor có theme tối giống VSCode, để tôi có thể làm việc thoải mái trong môi trường ánh sáng yếu.

#### Acceptance Criteria

1. THE Editor_Layout SHALL use a dark color scheme by default
2. THE Sidebar SHALL have a dark background color (#252526)
3. THE Editor_Area SHALL have a slightly lighter background color (#1E1E1E)
4. THE Tab_Bar SHALL have a dark background color (#2D2D2D)
5. THE Status_Bar SHALL have a blue-purple background color (#007ACC)
6. THE Editor_Layout SHALL use light text color (#CCCCCC) for readability

### Requirement 13: Responsive Layout

**User Story:** Là một developer, tôi muốn layout hoạt động tốt trên các kích thước màn hình khác nhau, để tôi có thể sử dụng trên nhiều thiết bị.

#### Acceptance Criteria

1. WHEN the window width is less than 800 pixels, THE Sidebar SHALL automatically hide
2. WHEN the window is resized, THE Editor_Layout SHALL adjust all components proportionally
3. THE Tab_Bar SHALL support horizontal scrolling when Tabs exceed available width
4. THE Editor_Layout SHALL maintain minimum usable dimensions of 600x400 pixels
5. WHEN the window is maximized, THE Editor_Layout SHALL utilize the full available space

### Requirement 14: File Type Icons

**User Story:** Là một developer, tôi muốn thấy icon phù hợp cho mỗi loại file, để tôi có thể dễ dàng nhận diện file type.

#### Acceptance Criteria

1. THE File_Explorer SHALL display a Dart icon for .dart files
2. THE File_Explorer SHALL display a JSON icon for .json files
3. THE File_Explorer SHALL display a YAML icon for .yaml and .yml files
4. THE File_Explorer SHALL display a Markdown icon for .md files
5. THE File_Explorer SHALL display a generic file icon for unknown file types
6. THE File_Explorer SHALL display a folder icon for directories

### Requirement 15: Error Handling

**User Story:** Là một developer, tôi muốn được thông báo khi có lỗi xảy ra, để tôi có thể xử lý các tình huống bất thường.

#### Acceptance Criteria

1. IF a file cannot be read, THEN THE Editor_Area SHALL display an error message
2. IF a file path is invalid, THEN THE File_Explorer SHALL display an error indicator
3. IF the Workspace directory is not accessible, THEN THE File_Explorer SHALL display an error message
4. WHEN an error occurs, THE Status_Bar SHALL display the error description
5. THE Editor_Layout SHALL log errors to the console for debugging purposes
