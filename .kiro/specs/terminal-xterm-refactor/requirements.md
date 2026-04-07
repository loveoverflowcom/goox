# Requirements Document: Terminal XTerm Refactor

## Introduction

This document specifies the requirements for refactoring the terminal module from a Rust FFI-based architecture to a pure Dart implementation using xterm (terminal emulator) and flutter_pty (PTY backend). The refactor consolidates all terminal functionality into the goox_terminal package, making it a self-contained, reusable component. The main application's lib/features/terminal directory will be completely removed, and the app will import and use widgets from goox_terminal.

## Glossary

- **Terminal_Controller**: Component that manages the lifecycle of a single terminal session
- **Session_Manager**: Component that manages multiple terminal sessions and provides session registry
- **Terminal_Panel**: Main UI widget that displays terminal tabs and active terminal
- **PTY**: Pseudo-terminal, a pair of virtual devices that provide bidirectional communication
- **XTerm**: Terminal emulator library that renders terminal output and handles input
- **Flutter_PTY**: Dart package that provides PTY backend functionality
- **Shell_Config**: Configuration object specifying shell path, arguments, environment, and working directory
- **Terminal_Status**: Enumeration representing terminal lifecycle state (initializing, running, exited, error)
- **PTY_Size**: Data structure representing terminal dimensions in rows and columns
- **ANSI_Escape_Sequence**: Special character sequences that control terminal formatting and colors

## Requirements

### Requirement 1: Terminal Session Lifecycle Management

**User Story:** As a developer, I want to create and manage terminal sessions, so that I can interact with shell processes through the application.

#### Acceptance Criteria

1. WHEN a terminal session is created with valid shell configuration THEN THE Terminal_Controller SHALL initialize xterm terminal instance and start PTY process
2. WHEN PTY process outputs data THEN THE Terminal_Controller SHALL write the data to xterm terminal for rendering
3. WHEN user types in terminal THEN THE Terminal_Controller SHALL write the input to PTY process
4. WHEN terminal session is closed THEN THE Terminal_Controller SHALL terminate PTY process and dispose all resources
5. WHEN PTY process exits THEN THE Terminal_Controller SHALL update status to exited and capture exit code

### Requirement 2: Multiple Session Management

**User Story:** As a developer, I want to manage multiple terminal sessions simultaneously, so that I can work with different shells or directories concurrently.

#### Acceptance Criteria

1. WHEN user creates a new session THEN THE Session_Manager SHALL create Terminal_Controller and add it to session registry
2. WHEN session count reaches maximum limit THEN THE Session_Manager SHALL prevent creation of additional sessions
3. WHEN user closes a session THEN THE Session_Manager SHALL remove it from registry and clean up resources
4. WHEN user switches active session THEN THE Session_Manager SHALL update active session ID and notify listeners
5. THE Session_Manager SHALL enforce maximum of 10 concurrent sessions

### Requirement 3: Terminal Resize Handling

**User Story:** As a developer, I want terminal to resize correctly, so that output displays properly when I change panel dimensions.

#### Acceptance Criteria

1. WHEN terminal is resized with valid dimensions THEN THE Terminal_Controller SHALL update PTY size and xterm view dimensions
2. WHEN resize is requested with invalid dimensions THEN THE Terminal_Controller SHALL reject the operation with error
3. WHEN terminal is resized THEN THE Terminal_Controller SHALL preserve terminal content and cursor position
4. THE Terminal_Controller SHALL validate that rows are between 1 and 1000
5. THE Terminal_Controller SHALL validate that columns are between 1 and 1000

### Requirement 4: Shell Configuration and Detection

**User Story:** As a developer, I want the system to detect available shells, so that I can use my preferred shell without manual configuration.

#### Acceptance Criteria

1. WHEN application starts THEN THE Shell_Detector SHALL detect default shell from system environment
2. WHEN user requests available shells THEN THE Shell_Detector SHALL return list of valid shells found on system
3. WHEN shell configuration is validated THEN THE Shell_Config SHALL verify shell path exists and is absolute
4. WHEN working directory is specified THEN THE Shell_Config SHALL verify directory exists
5. WHEN environment variables are provided THEN THE Shell_Config SHALL validate keys and values are non-empty

### Requirement 5: Terminal UI Components

**User Story:** As a developer, I want a complete terminal UI, so that I can interact with terminals through tabs and visual interface.

#### Acceptance Criteria

1. WHEN Terminal_Panel is displayed THEN THE system SHALL show terminal tab bar and active terminal view
2. WHEN user clicks new terminal button THEN THE Terminal_Panel SHALL create new session if under limit
3. WHEN user clicks tab close button THEN THE Terminal_Panel SHALL close corresponding session
4. WHEN user clicks on tab THEN THE Terminal_Panel SHALL switch to that session as active
5. WHEN terminal status changes THEN THE Terminal_Panel SHALL update visual indicators in tab

### Requirement 6: Terminal Theme Support

**User Story:** As a developer, I want to customize terminal appearance, so that terminal matches my preferred color scheme.

#### Acceptance Criteria

1. WHEN terminal theme is applied THEN THE Terminal_View SHALL update background, foreground, and cursor colors
2. WHEN terminal theme is applied THEN THE Terminal_View SHALL update all 16 ANSI colors (8 normal + 8 bright)
3. THE Terminal_Theme SHALL provide dark theme factory method
4. THE Terminal_Theme SHALL provide light theme factory method
5. WHEN theme is converted to xterm format THEN THE Terminal_Theme SHALL produce valid TerminalThemeData

### Requirement 7: Input and Output Handling

**User Story:** As a developer, I want reliable input/output handling, so that terminal behaves correctly during interaction.

#### Acceptance Criteria

1. WHEN terminal status is running THEN THE Terminal_Controller SHALL accept and process user input
2. WHEN terminal status is not running THEN THE Terminal_Controller SHALL reject input with state error
3. WHEN PTY outputs data THEN THE Terminal_Controller SHALL decode UTF-8 with malformed character handling
4. WHEN user input is sent THEN THE Terminal_Controller SHALL encode as UTF-8 before writing to PTY
5. WHEN output stream encounters error THEN THE Terminal_Controller SHALL update status to error and notify listeners

### Requirement 8: Resource Cleanup and Memory Management

**User Story:** As a developer, I want proper resource cleanup, so that application doesn't leak memory or file handles.

#### Acceptance Criteria

1. WHEN terminal session is disposed THEN THE Terminal_Controller SHALL cancel output subscription
2. WHEN terminal session is disposed THEN THE Terminal_Controller SHALL kill PTY process
3. WHEN terminal session is disposed THEN THE Terminal_Controller SHALL dispose xterm terminal instance
4. WHEN all sessions are closed THEN THE Session_Manager SHALL have zero sessions in registry
5. WHEN session is removed from registry THEN THE Session_Manager SHALL decrement session count

### Requirement 9: Error Handling and Recovery

**User Story:** As a developer, I want clear error handling, so that I can understand and recover from failures.

#### Acceptance Criteria

1. IF PTY creation fails THEN THE Terminal_Controller SHALL throw PtyCreationException with descriptive message
2. IF PTY output stream emits error THEN THE Terminal_Controller SHALL set status to error and display error indicator
3. IF session limit is reached THEN THE Session_Manager SHALL disable new terminal button and show tooltip
4. IF resize dimensions are invalid THEN THE Terminal_Controller SHALL throw ArgumentError
5. IF write is attempted on closed terminal THEN THE Terminal_Controller SHALL throw StateError

### Requirement 10: Session State Consistency

**User Story:** As a developer, I want consistent session state, so that application behavior is predictable.

#### Acceptance Criteria

1. WHEN session is in running status THEN THE Terminal_Controller SHALL have non-null PTY and terminal instances
2. WHEN session is in exited status THEN THE Terminal_Controller SHALL have null output subscription
3. WHEN active session ID is set THEN THE Session_Manager SHALL ensure session exists in registry
4. WHEN session is added to registry THEN THE Session_Manager SHALL ensure unique session ID
5. THE Session_Manager SHALL maintain session count equal to registry size

### Requirement 11: Keyboard and Mouse Input

**User Story:** As a developer, I want full keyboard and mouse support, so that I can interact naturally with terminal.

#### Acceptance Criteria

1. WHEN user types characters THEN THE Terminal_View SHALL send characters to terminal controller
2. WHEN user presses special keys THEN THE Terminal_View SHALL send appropriate escape sequences
3. WHEN user clicks in terminal THEN THE Terminal_View SHALL update cursor position
4. WHEN user scrolls THEN THE Terminal_View SHALL scroll terminal buffer
5. WHEN terminal receives focus THEN THE Terminal_View SHALL enable keyboard input

### Requirement 12: Terminal Buffer Management

**User Story:** As a developer, I want efficient buffer management, so that terminal performs well with large output.

#### Acceptance Criteria

1. THE Terminal_Controller SHALL limit terminal buffer to 1000 lines maximum
2. WHEN buffer exceeds maximum THEN THE xterm SHALL remove oldest lines
3. WHEN terminal outputs data THEN THE Terminal_View SHALL auto-scroll to bottom if at bottom
4. WHEN user scrolls up THEN THE Terminal_View SHALL disable auto-scroll
5. WHEN user scrolls to bottom THEN THE Terminal_View SHALL re-enable auto-scroll

### Requirement 13: Platform-Specific Shell Defaults

**User Story:** As a developer, I want platform-appropriate defaults, so that terminal works correctly on each operating system.

#### Acceptance Criteria

1. WHEN running on Linux THEN THE Shell_Detector SHALL default to bash or zsh
2. WHEN running on macOS THEN THE Shell_Detector SHALL default to zsh
3. WHEN running on Windows THEN THE Shell_Detector SHALL default to PowerShell or cmd
4. WHEN default shell is not found THEN THE Shell_Detector SHALL provide platform-specific fallback
5. THE Shell_Config SHALL provide factory methods for bash, zsh, fish, PowerShell, and cmd

### Requirement 14: Migration from Rust FFI

**User Story:** As a developer, I want clean migration from Rust FFI, so that old implementation is completely removed.

#### Acceptance Criteria

1. THE goox_terminal package SHALL remove rust/ directory
2. THE goox_terminal package SHALL remove flutter_rust_bridge dependency
3. THE goox_terminal package SHALL remove ffi dependency
4. THE goox_terminal package SHALL remove generated Rust bindings from lib/src/rust/
5. THE main application SHALL remove lib/features/terminal directory completely

### Requirement 15: Package Self-Containment

**User Story:** As a developer, I want goox_terminal to be self-contained, so that it can be reused in other projects.

#### Acceptance Criteria

1. THE goox_terminal package SHALL include all UI components for terminal display
2. THE goox_terminal package SHALL include all state management for sessions
3. THE goox_terminal package SHALL include all PTY lifecycle handling
4. THE goox_terminal package SHALL export public API through single entry point
5. THE main application SHALL only import from goox_terminal package for terminal functionality

### Requirement 16: Terminal Title Management

**User Story:** As a developer, I want terminal titles to update automatically, so that I can identify terminals by their current context.

#### Acceptance Criteria

1. WHEN PTY process sets title via escape sequence THEN THE Terminal_Controller SHALL update title property
2. WHEN title changes THEN THE Terminal_Controller SHALL notify title listeners
3. WHEN terminal tab is displayed THEN THE Terminal_Tab_Bar SHALL show current title
4. WHEN title is not set THEN THE Terminal_Controller SHALL use default title format
5. THE Terminal_Controller SHALL expose title as ValueListenable for reactive updates

### Requirement 17: Process ID Tracking

**User Story:** As a developer, I want to track process IDs, so that I can monitor and manage shell processes.

#### Acceptance Criteria

1. WHEN PTY process starts THEN THE Terminal_Controller SHALL capture process ID
2. WHEN terminal is running THEN THE Terminal_Controller SHALL expose PID via getter
3. WHEN PTY process exits THEN THE Terminal_Controller SHALL capture exit code
4. WHEN terminal is exited THEN THE Terminal_Controller SHALL expose exit code via getter
5. THE Terminal_Controller SHALL provide null PID when process is not running

### Requirement 18: Terminal Restart Capability

**User Story:** As a developer, I want to restart terminals, so that I can recover from errors or reset state.

#### Acceptance Criteria

1. WHEN restart is requested THEN THE Terminal_Controller SHALL dispose current PTY and terminal
2. WHEN restart is requested THEN THE Terminal_Controller SHALL create new PTY with same configuration
3. WHEN restart is requested THEN THE Terminal_Controller SHALL create new xterm terminal instance
4. WHEN restart completes THEN THE Terminal_Controller SHALL update status to running
5. WHEN restart fails THEN THE Terminal_Controller SHALL update status to error

### Requirement 19: Status Stream Notifications

**User Story:** As a developer, I want to observe status changes, so that I can react to terminal lifecycle events.

#### Acceptance Criteria

1. WHEN terminal status changes THEN THE Terminal_Controller SHALL emit new status on status stream
2. WHEN listener subscribes to status stream THEN THE listener SHALL receive current status immediately
3. WHEN terminal transitions to error THEN THE status stream SHALL emit error status
4. WHEN terminal transitions to exited THEN THE status stream SHALL emit exited status
5. THE Terminal_Controller SHALL provide status stream as broadcast stream

### Requirement 20: Security and Validation

**User Story:** As a developer, I want secure terminal operations, so that malicious input cannot compromise the system.

#### Acceptance Criteria

1. WHEN shell arguments are provided THEN THE Terminal_Controller SHALL pass them as list not concatenated string
2. WHEN environment variables are set THEN THE Shell_Config SHALL validate keys and values
3. WHEN working directory is set THEN THE Shell_Config SHALL verify user has read permission
4. THE Session_Manager SHALL enforce resource limits to prevent exhaustion
5. THE xterm library SHALL handle ANSI escape sequences safely without exploitation risk
