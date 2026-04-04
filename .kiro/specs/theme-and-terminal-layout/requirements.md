# Requirements Document

## Introduction

Tài liệu này mô tả yêu cầu cho 2 tính năng mới của Goox Editor: Theme Selector và Terminal Layout. Theme Selector cho phép người dùng chuyển đổi giữa các chế độ giao diện (dark, light, system), trong khi Terminal Layout cung cấp UI layout cơ bản cho terminal (phiên bản dummy không có PTY implementation).

## Glossary

- **Goox_Editor**: Ứng dụng Flutter editor sử dụng kiến trúc BLoC pattern
- **Theme_Selector**: Component cho phép người dùng chọn theme (dark/light/system)
- **Terminal_Layout**: Component hiển thị UI layout của terminal panel
- **Theme_Bloc**: BLoC quản lý state và logic của theme
- **Terminal_Bloc**: BLoC quản lý state và logic của terminal panel
- **Settings_Panel**: Panel trong sidebar chứa các tùy chọn cấu hình
- **System_Theme**: Theme mode tự động theo cài đặt hệ thống của người dùng
- **Dark_Theme**: Theme mode với màu nền tối
- **Light_Theme**: Theme mode với màu nền sáng
- **Terminal_Panel**: Panel hiển thị terminal ở phía dưới editor area
- **Editor_Area**: Vùng chính hiển thị nội dung file đang chỉnh sửa

## Requirements

### Requirement 1: Theme Selection

**User Story:** Là một developer, tôi muốn chọn theme cho editor, để tôi có thể làm việc trong môi trường phù hợp với sở thích và điều kiện ánh sáng.

#### Acceptance Criteria

1. THE Settings_Panel SHALL display a Theme_Selector with three options: Dark, Light, and System
2. WHEN a user selects Dark theme, THE Goox_Editor SHALL apply the dark color scheme to all UI components
3. WHEN a user selects Light theme, THE Goox_Editor SHALL apply the light color scheme to all UI components
4. WHEN a user selects System theme, THE Goox_Editor SHALL apply the theme matching the operating system's theme setting
5. WHEN the operating system theme changes, WHILE System theme is selected, THE Goox_Editor SHALL update the UI to match the new system theme
6. THE Theme_Selector SHALL display the currently selected theme option
7. THE Theme_Bloc SHALL persist the selected theme preference across application restarts

### Requirement 2: Theme Selector UI

**User Story:** Là một developer, tôi muốn Theme Selector có UI rõ ràng và dễ sử dụng, để tôi có thể nhanh chóng thay đổi theme khi cần.

#### Acceptance Criteria

1. THE Theme_Selector SHALL be displayed in the Settings_Panel of the sidebar
2. THE Theme_Selector SHALL use an expandable/collapsible section with default state collapsed
3. WHEN the Theme_Selector section is collapsed, THE Settings_Panel SHALL display only the section header
4. WHEN a user clicks the Theme_Selector section header, THE Settings_Panel SHALL toggle between expanded and collapsed states
5. WHEN the Theme_Selector section is expanded, THE Settings_Panel SHALL display all three theme options with radio buttons or similar selection UI
6. THE Theme_Selector SHALL use clear labels: "Dark", "Light", and "System"

### Requirement 3: Terminal Layout UI

**User Story:** Là một developer, tôi muốn có terminal panel trong editor, để tôi có thể xem và chuẩn bị cho tính năng terminal tương lai.

#### Acceptance Criteria

1. THE Goox_Editor SHALL display a Terminal_Panel below the Editor_Area
2. THE Terminal_Panel SHALL have a resizable height with minimum height of 100 pixels and maximum height of 80% of window height
3. WHEN a user drags the Terminal_Panel resize handle, THE Goox_Editor SHALL update the Terminal_Panel height in real-time
4. THE Terminal_Panel SHALL display a header with the label "TERMINAL"
5. THE Terminal_Panel SHALL display placeholder text indicating this is a dummy version
6. THE Terminal_Panel SHALL use a monospace font for content area
7. THE Terminal_Panel SHALL apply the current theme colors to its background and text

### Requirement 4: Terminal Panel Toggle

**User Story:** Là một developer, tôi muốn ẩn/hiện terminal panel, để tôi có thể tối đa hóa không gian làm việc khi không cần terminal.

#### Acceptance Criteria

1. THE Goox_Editor SHALL provide a keyboard shortcut Ctrl+` (backtick) to toggle Terminal_Panel visibility
2. WHEN a user presses Ctrl+`, THE Goox_Editor SHALL toggle the Terminal_Panel between visible and hidden states
3. WHEN the Terminal_Panel is hidden, THE Editor_Area SHALL expand to use the full available vertical space
4. WHEN the Terminal_Panel is shown, THE Editor_Area SHALL shrink to accommodate the Terminal_Panel
5. THE Terminal_Bloc SHALL persist the Terminal_Panel visibility state across application restarts
6. THE Terminal_Bloc SHALL persist the Terminal_Panel height across application restarts

### Requirement 5: Theme State Management

**User Story:** Là một developer, tôi muốn theme được quản lý đúng cách trong kiến trúc BLoC, để ứng dụng duy trì tính nhất quán và dễ bảo trì.

#### Acceptance Criteria

1. THE Theme_Bloc SHALL manage theme state using BLoC pattern
2. THE Theme_Bloc SHALL emit new state when theme selection changes
3. THE Theme_Bloc SHALL load persisted theme preference on initialization
4. WHEN System theme is selected, THE Theme_Bloc SHALL listen to system theme changes
5. THE Theme_Bloc SHALL provide events: SelectThemeEvent, LoadThemePreferenceEvent, SystemThemeChangedEvent
6. THE Theme_Bloc SHALL provide states containing: current theme mode (dark/light/system), resolved theme (dark/light)

### Requirement 6: Terminal State Management

**User Story:** Là một developer, tôi muốn terminal panel được quản lý đúng cách trong kiến trúc BLoC, để ứng dụng duy trì tính nhất quán và dễ bảo trì.

#### Acceptance Criteria

1. THE Terminal_Bloc SHALL manage terminal panel state using BLoC pattern
2. THE Terminal_Bloc SHALL emit new state when panel visibility changes
3. THE Terminal_Bloc SHALL emit new state when panel height changes
4. THE Terminal_Bloc SHALL load persisted panel preferences on initialization
5. THE Terminal_Bloc SHALL provide events: ToggleTerminalEvent, ResizeTerminalEvent, InitializeTerminalEvent
6. THE Terminal_Bloc SHALL provide states containing: visibility status, panel height

### Requirement 7: Theme Integration

**User Story:** Là một developer, tôi muốn theme được áp dụng nhất quán cho toàn bộ ứng dụng, để giao diện có tính thống nhất cao.

#### Acceptance Criteria

1. THE Goox_Editor SHALL update MaterialApp theme when Theme_Bloc emits new state
2. THE Goox_Editor SHALL apply theme colors to: sidebar, editor area, status bar, tab bar, and Terminal_Panel
3. WHEN theme changes, THE Goox_Editor SHALL rebuild all UI components with new theme colors
4. THE Light_Theme SHALL use light background colors and dark text colors
5. THE Dark_Theme SHALL use dark background colors and light text colors
6. THE Goox_Editor SHALL maintain existing AppTheme.dark color scheme for Dark_Theme
7. THE Goox_Editor SHALL create a new AppTheme.light color scheme for Light_Theme with appropriate light colors

