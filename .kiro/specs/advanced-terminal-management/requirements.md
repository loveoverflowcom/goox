# Requirements Document

## Introduction

Tài liệu này mô tả yêu cầu cho tính năng Advanced Terminal Management trong Goox Editor. Tính năng này nâng cấp terminal panel hiện tại (dummy version) thành một hệ thống terminal chuyên nghiệp với khả năng quản lý nhiều terminal instances, tích hợp PTY (pseudo-terminal) để thực thi shell commands thực sự, và cung cấp trải nghiệm người dùng tương tự VSCode.

## Glossary

- **Goox_Editor**: Ứng dụng Flutter editor sử dụng kiến trúc BLoC pattern
- **Terminal_Panel**: Panel hiển thị terminal ở phía dưới editor area
- **Terminal_Instance**: Một phiên terminal độc lập với PTY process riêng
- **Terminal_Tab**: Tab UI đại diện cho một Terminal_Instance
- **Terminal_Tab_Bar**: Thanh chứa các Terminal_Tab và nút điều khiển
- **PTY**: Pseudo-terminal, cơ chế cho phép chạy shell process và tương tác I/O
- **Shell_Process**: Process của shell (bash, zsh, cmd, powershell) chạy trong PTY
- **Terminal_Output**: Dữ liệu text được ghi ra từ Shell_Process
- **Terminal_Input**: Dữ liệu text người dùng nhập vào để gửi tới Shell_Process
- **Active_Terminal**: Terminal_Instance hiện đang được hiển thị và nhận input
- **Terminal_Emulator**: Component render Terminal_Output và xử lý Terminal_Input
- **ANSI_Escape_Codes**: Mã điều khiển terminal cho màu sắc và formatting
- **Working_Directory**: Thư mục làm việc hiện tại của Shell_Process
- **Terminal_Bloc**: BLoC quản lý state và logic của terminal system
- **Terminal_Manager**: Service quản lý lifecycle của các Terminal_Instance

## Requirements

### Requirement 1: Multiple Terminal Instances

**User Story:** Là một developer, tôi muốn tạo và quản lý nhiều terminal instances, để tôi có thể chạy nhiều processes đồng thời trong các terminals riêng biệt.

#### Acceptance Criteria

1. THE Terminal_Panel SHALL support creating multiple Terminal_Instance objects
2. THE Terminal_Panel SHALL display a Terminal_Tab for each Terminal_Instance
3. WHEN a Terminal_Instance is created, THE Terminal_Panel SHALL assign it a unique identifier
4. THE Terminal_Panel SHALL maintain a list of all active Terminal_Instance objects
5. THE Terminal_Panel SHALL allow a maximum of 10 concurrent Terminal_Instance objects
6. WHEN the maximum number of terminals is reached, THE Terminal_Panel SHALL disable the create new terminal button
7. THE Terminal_Panel SHALL display Terminal_Tab objects in creation order from left to right

### Requirement 2: Terminal Tab UI

**User Story:** Là một developer, tôi muốn thấy các terminal tabs rõ ràng với thông tin hữu ích, để tôi có thể dễ dàng nhận biết và chuyển đổi giữa các terminals.

#### Acceptance Criteria

1. THE Terminal_Tab SHALL display the terminal title or shell name
2. THE Terminal_Tab SHALL display a close button (X icon) on hover
3. THE Terminal_Tab SHALL highlight the Active_Terminal with distinct background color
4. THE Terminal_Tab SHALL use dimmed styling for inactive terminals
5. WHEN a Terminal_Tab is clicked, THE Terminal_Panel SHALL set that terminal as Active_Terminal
6. THE Terminal_Tab SHALL truncate long titles with ellipsis when width is insufficient
7. THE Terminal_Tab SHALL display a minimum width of 120 pixels and maximum width of 200 pixels

### Requirement 3: Create New Terminal

**User Story:** Là một developer, tôi muốn tạo terminal mới nhanh chóng, để tôi có thể bắt đầu làm việc với shell process mới.

#### Acceptance Criteria

1. THE Terminal_Tab_Bar SHALL display a "+" button to create new terminals
2. WHEN the "+" button is clicked, THE Terminal_Manager SHALL create a new Terminal_Instance
3. WHEN a new Terminal_Instance is created, THE Terminal_Manager SHALL initialize a new PTY with Shell_Process
4. WHEN a new Terminal_Instance is created, THE Terminal_Panel SHALL add a new Terminal_Tab
5. WHEN a new Terminal_Instance is created, THE Terminal_Panel SHALL set it as Active_Terminal
6. THE Terminal_Manager SHALL use the workspace root directory as Working_Directory for new terminals
7. THE Goox_Editor SHALL support keyboard shortcut Ctrl+Shift+` to create a new terminal

### Requirement 4: Close Terminal

**User Story:** Là một developer, tôi muốn đóng các terminals không cần thiết, để giữ workspace gọn gàng và giải phóng system resources.

#### Acceptance Criteria

1. WHEN the close button on a Terminal_Tab is clicked, THE Terminal_Manager SHALL terminate the associated Shell_Process
2. WHEN a Terminal_Instance is closed, THE Terminal_Manager SHALL cleanup the PTY resources
3. WHEN a Terminal_Instance is closed, THE Terminal_Panel SHALL remove the corresponding Terminal_Tab
4. WHEN the Active_Terminal is closed, THE Terminal_Panel SHALL set the previous terminal as Active_Terminal
5. WHEN the Active_Terminal is closed and it is the only terminal, THE Terminal_Panel SHALL create a new Terminal_Instance automatically
6. WHEN a Terminal_Instance is closed, THE Terminal_Panel SHALL animate the tab removal smoothly
7. THE Terminal_Manager SHALL wait up to 2 seconds for graceful Shell_Process termination before forcing kill

### Requirement 5: Terminal Tab Switching

**User Story:** Là một developer, tôi muốn chuyển đổi nhanh giữa các terminals, để tôi có thể làm việc hiệu quả với nhiều shell processes.

#### Acceptance Criteria

1. WHEN a Terminal_Tab is clicked, THE Terminal_Panel SHALL display the content of that Terminal_Instance
2. WHEN switching terminals, THE Terminal_Panel SHALL preserve the Terminal_Output of the previous Active_Terminal
3. WHEN switching terminals, THE Terminal_Emulator SHALL render the Terminal_Output of the new Active_Terminal
4. THE Goox_Editor SHALL support keyboard shortcuts Ctrl+PageUp and Ctrl+PageDown to cycle through terminals
5. WHEN Ctrl+PageUp is pressed, THE Terminal_Panel SHALL activate the previous Terminal_Tab
6. WHEN Ctrl+PageDown is pressed, THE Terminal_Panel SHALL activate the next Terminal_Tab
7. WHEN cycling past the last terminal, THE Terminal_Panel SHALL wrap to the first terminal

### Requirement 6: PTY Integration

**User Story:** Là một developer, tôi muốn terminal có khả năng chạy shell commands thực sự, để tôi có thể thực hiện các tác vụ development như build, test, và run scripts.

#### Acceptance Criteria

1. THE Terminal_Manager SHALL create a PTY for each Terminal_Instance using platform-appropriate APIs
2. THE Terminal_Manager SHALL spawn a Shell_Process in the PTY (bash on Linux/macOS, cmd or powershell on Windows)
3. THE PTY SHALL capture all Terminal_Output from the Shell_Process
4. THE PTY SHALL forward all Terminal_Input to the Shell_Process
5. WHEN the Shell_Process exits, THE Terminal_Manager SHALL detect the exit and display exit code
6. THE PTY SHALL support ANSI_Escape_Codes for text formatting and colors
7. THE PTY SHALL configure appropriate environment variables (TERM, PATH, HOME, etc.)

### Requirement 7: Terminal Output Rendering

**User Story:** Là một developer, tôi muốn thấy terminal output được hiển thị chính xác với colors và formatting, để tôi có thể đọc và hiểu output dễ dàng.

#### Acceptance Criteria

1. THE Terminal_Emulator SHALL render Terminal_Output as monospace text
2. THE Terminal_Emulator SHALL parse and apply ANSI_Escape_Codes for text colors
3. THE Terminal_Emulator SHALL parse and apply ANSI_Escape_Codes for text styles (bold, italic, underline)
4. THE Terminal_Emulator SHALL support 16 basic ANSI colors and 256-color palette
5. THE Terminal_Emulator SHALL auto-scroll to show the latest Terminal_Output
6. THE Terminal_Emulator SHALL support scrollback buffer of at least 1000 lines
7. WHEN Terminal_Output exceeds scrollback buffer limit, THE Terminal_Emulator SHALL remove oldest lines

### Requirement 8: Terminal Input Handling

**User Story:** Là một developer, tôi muốn nhập commands và tương tác với terminal, để tôi có thể điều khiển Shell_Process.

#### Acceptance Criteria

1. WHEN the Active_Terminal receives keyboard input, THE Terminal_Emulator SHALL send characters to the PTY
2. THE Terminal_Emulator SHALL support special keys (Enter, Backspace, Tab, Arrow keys, Ctrl combinations)
3. WHEN Enter key is pressed, THE Terminal_Emulator SHALL send newline character to PTY
4. WHEN Ctrl+C is pressed in terminal, THE Terminal_Emulator SHALL send SIGINT signal to Shell_Process
5. WHEN Ctrl+D is pressed in terminal, THE Terminal_Emulator SHALL send EOF to Shell_Process
6. THE Terminal_Emulator SHALL display a text cursor at the current input position
7. THE Terminal_Emulator SHALL prevent global keyboard shortcuts from interfering with terminal input

### Requirement 9: Terminal State Management

**User Story:** Là một developer, tôi muốn terminal state được quản lý đúng cách, để ứng dụng hoạt động ổn định và có thể mở rộng.

#### Acceptance Criteria

1. THE Terminal_Bloc SHALL manage state for all Terminal_Instance objects using BLoC pattern
2. THE Terminal_Bloc SHALL emit new state when a Terminal_Instance is created
3. THE Terminal_Bloc SHALL emit new state when a Terminal_Instance is closed
4. THE Terminal_Bloc SHALL emit new state when Active_Terminal changes
5. THE Terminal_Bloc SHALL emit new state when Terminal_Output is received
6. THE Terminal_Bloc SHALL provide events: CreateTerminalEvent, CloseTerminalEvent, SwitchTerminalEvent, TerminalOutputEvent, TerminalInputEvent
7. THE Terminal_Bloc SHALL provide state containing: list of Terminal_Instance objects, active terminal ID, terminal outputs

### Requirement 10: Terminal Persistence

**User Story:** Là một developer, tôi muốn terminal configuration được lưu lại, để tôi có trải nghiệm nhất quán khi khởi động lại ứng dụng.

#### Acceptance Criteria

1. THE Terminal_Manager SHALL persist the number of open terminals across application restarts
2. THE Terminal_Manager SHALL persist the Working_Directory of each terminal across application restarts
3. WHEN the application starts, THE Terminal_Manager SHALL restore the saved number of terminals
4. WHEN the application starts, THE Terminal_Manager SHALL restore each terminal with its saved Working_Directory
5. THE Terminal_Manager SHALL NOT persist Terminal_Output content (start with clean terminals)
6. THE Terminal_Manager SHALL persist terminal panel visibility state across application restarts
7. THE Terminal_Manager SHALL persist terminal panel height across application restarts

### Requirement 11: Terminal Keyboard Shortcuts

**User Story:** Là một developer, tôi muốn sử dụng keyboard shortcuts để điều khiển terminals, để tôi có thể làm việc nhanh hơn mà không cần dùng chuột.

#### Acceptance Criteria

1. THE Goox_Editor SHALL support Ctrl+` to toggle Terminal_Panel visibility
2. THE Goox_Editor SHALL support Ctrl+Shift+` to create a new Terminal_Instance
3. THE Goox_Editor SHALL support Ctrl+PageUp to switch to previous terminal
4. THE Goox_Editor SHALL support Ctrl+PageDown to switch to next terminal
5. THE Goox_Editor SHALL support Ctrl+Shift+W to close the Active_Terminal
6. WHEN Terminal_Panel is focused, THE Goox_Editor SHALL route all keyboard input to Terminal_Emulator except global shortcuts
7. THE Goox_Editor SHALL display keyboard shortcuts in tooltips for terminal UI buttons

### Requirement 12: Terminal Shell Selection

**User Story:** Là một developer, tôi muốn terminal tự động chọn shell phù hợp với platform, để tôi có trải nghiệm terminal tự nhiên trên mỗi hệ điều hành.

#### Acceptance Criteria

1. WHEN running on Linux, THE Terminal_Manager SHALL use bash as default shell
2. WHEN running on macOS, THE Terminal_Manager SHALL use zsh as default shell
3. WHEN running on Windows, THE Terminal_Manager SHALL use PowerShell as default shell
4. WHEN the default shell is not available, THE Terminal_Manager SHALL fallback to sh on Unix or cmd on Windows
5. THE Terminal_Manager SHALL detect shell availability by checking system PATH
6. THE Terminal_Manager SHALL pass appropriate shell initialization flags (-l for login shell on Unix)
7. THE Terminal_Instance SHALL display the shell name in the Terminal_Tab title

### Requirement 13: Terminal Error Handling

**User Story:** Là một developer, tôi muốn terminal xử lý lỗi một cách graceful, để ứng dụng không crash khi có vấn đề với shell process.

#### Acceptance Criteria

1. WHEN PTY creation fails, THE Terminal_Manager SHALL display an error message in the terminal content area
2. WHEN Shell_Process fails to start, THE Terminal_Manager SHALL display the error reason to the user
3. WHEN Shell_Process crashes unexpectedly, THE Terminal_Manager SHALL display exit code and allow creating a new shell
4. WHEN PTY I/O errors occur, THE Terminal_Manager SHALL log the error and attempt to recover
5. IF recovery fails, THE Terminal_Manager SHALL mark the Terminal_Instance as dead and disable input
6. THE Terminal_Manager SHALL provide a "Restart Terminal" button for dead Terminal_Instance objects
7. WHEN "Restart Terminal" is clicked, THE Terminal_Manager SHALL create a new PTY and Shell_Process for that terminal

### Requirement 14: Terminal Performance

**User Story:** Là một developer, tôi muốn terminal hoạt động mượt mà ngay cả với large output, để tôi có thể làm việc hiệu quả với các commands tạo nhiều output.

#### Acceptance Criteria

1. THE Terminal_Emulator SHALL render Terminal_Output updates at maximum 60 frames per second
2. THE Terminal_Emulator SHALL batch multiple Terminal_Output chunks received within 16ms into single render
3. THE Terminal_Emulator SHALL limit scrollback buffer to 1000 lines to prevent memory issues
4. THE Terminal_Emulator SHALL use efficient text rendering with Flutter's CustomPainter or similar
5. WHEN Terminal_Output rate exceeds rendering capacity, THE Terminal_Emulator SHALL drop intermediate frames
6. THE Terminal_Manager SHALL limit each Terminal_Instance memory usage to reasonable bounds
7. THE Terminal_Emulator SHALL render only visible lines plus small buffer (virtualized scrolling)

### Requirement 15: Terminal UI Polish

**User Story:** Là một developer, tôi muốn terminal có UI chuyên nghiệp và đẹp mắt, để tôi có trải nghiệm làm việc thoải mái.

#### Acceptance Criteria

1. THE Terminal_Tab_Bar SHALL use consistent styling with the rest of Goox_Editor theme
2. THE Terminal_Tab SHALL show smooth hover effects when mouse enters
3. THE Terminal_Tab close button SHALL only appear on hover to reduce visual clutter
4. THE Terminal_Emulator SHALL use a high-quality monospace font (Fira Code, JetBrains Mono, or Cascadia Code)
5. THE Terminal_Emulator SHALL apply appropriate line height for readability (1.2 to 1.4)
6. THE Terminal_Panel SHALL display a subtle shadow or border to separate from Editor_Area
7. THE Terminal_Tab_Bar SHALL display a dropdown menu with additional actions (split terminal, clear output) for future extensibility

