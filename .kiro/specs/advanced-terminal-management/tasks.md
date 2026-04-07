# Implementation Plan: Advanced Terminal Management

## Overview

This plan transforms the existing dummy terminal panel into a fully functional terminal system with PTY integration, multiple terminal instances, ANSI escape code support, and professional tab management. The implementation follows the BLoC pattern and builds upon the existing terminal infrastructure in the Goox Editor codebase.

**Note:** The terminal feature is embedded directly into the Goox Editor app at `lib/features/terminal/`. It is NOT a separate package with platform-specific folders (linux, windows, macos). All implementation will be done within the existing feature structure using Flutter's cross-platform capabilities and PTY packages.

## Tasks

- [ ] 1. Set up core data models and infrastructure
  - [x] 1.1 Create terminal instance and output models
    - Create `lib/features/terminal/data/models/terminal_instance.dart` with TerminalInstance class and TerminalStatus enum
    - Create `lib/features/terminal/data/models/terminal_output.dart` with TerminalOutput and TerminalLine classes
    - Create `lib/features/terminal/data/models/ansi_style.dart` with ANSIStyle class for text styling
    - Create `lib/features/terminal/data/models/shell_config.dart` with ShellConfig class and platform detection
    - _Requirements: 1.1, 1.3, 1.4, 6.1, 6.2, 12.1-12.4_

  - [x] 1.2 Write unit tests for data models
    - Test TerminalOutput.appendText() with newlines and line trimming
    - Test TerminalOutput scrollback buffer limit enforcement
    - Test ShellConfig.forPlatform() for Linux, macOS, and Windows
    - _Requirements: 1.1, 6.1, 12.1-12.4_

- [ ] 2. Implement ANSI parsing service
  - [x] 2.1 Create ANSI parser for escape code handling
    - Create `lib/features/terminal/data/services/ansi_parser.dart`
    - Implement parse() method to convert raw text with ANSI codes into TerminalLine objects
    - Support basic 16 colors (30-37, 40-47, 90-97, 100-107)
    - Support 256-color palette (38;5;n, 48;5;n)
    - Support RGB colors (38;2;r;g;b, 48;2;r;g;b)
    - Support text styles: bold (1), italic (3), underline (4)
    - Support reset codes (0, 22, 23, 24, 39, 49)
    - Handle invalid escape sequences gracefully by skipping them
    - _Requirements: 6.6, 7.2, 7.3, 7.4_

  - [x] 2.2 Write unit tests for ANSI parser
    - Test parsing basic 16 colors (foreground and background)
    - Test parsing 256-color palette codes
    - Test parsing RGB color codes
    - Test parsing text styles (bold, italic, underline)
    - Test reset codes clear styles correctly
    - Test invalid escape sequences are skipped
    - Test style state maintained across multiple lines
    - Test mixed styled and unstyled text
    - _Requirements: 7.2, 7.3, 7.4_

- [ ] 3. Implement shell detection service
  - [x] 3.1 Create shell detector for platform-specific shell selection
    - Create `lib/features/terminal/data/services/shell_detector.dart`
    - Implement detectShell() method that returns ShellConfig
    - Use Platform.isLinux, Platform.isMacOS, Platform.isWindows for detection
    - For Linux: detect bash, fallback to sh
    - For macOS: detect zsh, fallback to bash, then sh
    - For Windows: detect pwsh (PowerShell Core), fallback to powershell, then cmd
    - Check system PATH for shell availability using Process.run('which', [shell]) on Unix or 'where' on Windows
    - Add appropriate shell flags (-l for login shell on Unix)
    - _Requirements: 12.1-12.6_

  - [x] 3.2 Write unit tests for shell detector
    - Test detectShell() returns bash on Linux
    - Test detectShell() returns zsh on macOS
    - Test detectShell() returns PowerShell on Windows
    - Test fallback to sh when preferred shell not found (Unix)
    - Test fallback to cmd when PowerShell not found (Windows)
    - Test shell arguments include correct flags
    - _Requirements: 12.1-12.6_

- [ ] 4. Implement PTY service
  - [x] 4.1 Create PTY service interface and implementation
    - Create `lib/features/terminal/data/services/pty_service.dart` with abstract PTYService class
    - Define PTYProcess class with pid, stdout/stderr streams, exitCode future
    - Define createPTY() method signature
    - Define write(), terminate(), and resize() method signatures
    - Create `lib/features/terminal/data/services/pty_service_impl.dart`
    - Add dependencies: `xterm: ^3.5.0` and `flutter_pty: ^0.3.0` (or similar PTY package) to pubspec.yaml
    - Integrate with the chosen PTY package for cross-platform support
    - Implement createPTY() to spawn shell process with PTY
    - Implement write() to send input to PTY
    - Implement terminate() with graceful shutdown (2 second timeout) and force kill
    - Implement resize() to update PTY dimensions
    - Set TERM environment variable to `xterm-256color`
    - The PTY package handles platform-specific implementations internally (no need for separate platform folders)
    - _Requirements: 6.1-6.7, 4.7_

  - [x] 4.2 Write integration tests for PTY service
    - Test createPTY() spawns real shell process
    - Test write() sends input to shell
    - Test stdout stream receives output from shell
    - Test terminate() kills shell process
    - Test graceful termination waits up to 2 seconds
    - Note: These tests will work cross-platform as the PTY package handles platform differences
    - _Requirements: 6.1-6.4, 4.7_

- [ ] 5. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Extend terminal repository for persistence
  - [x] 6.1 Add persistence methods to terminal repository
    - Open `lib/features/terminal/data/repositories/terminal_repository.dart`
    - Add loadHeight() and saveHeight() method signatures
    - Add loadTerminalCount() and saveTerminalCount() method signatures
    - Add loadWorkingDirectories() and saveWorkingDirectories() method signatures
    - Open `lib/features/terminal/data/repositories/terminal_repository_impl.dart`
    - Implement new methods using SharedPreferences
    - Use keys: `terminal_height`, `terminal_count`, `terminal_working_dirs`
    - Encode working directories as JSON array
    - _Requirements: 10.1-10.7_

  - [x] 6.2 Write unit tests for repository extensions
    - Test saveHeight() and loadHeight() persist correctly
    - Test saveTerminalCount() and loadTerminalCount() persist correctly
    - Test saveWorkingDirectories() and loadWorkingDirectories() persist correctly
    - Test working directories JSON encoding/decoding
    - _Requirements: 10.1-10.7_

- [ ] 7. Refactor and extend TerminalBloc
  - [x] 7.1 Add new events to TerminalBloc
    - Open `lib/features/terminal/presentation/blocs/terminal_event.dart`
    - Add CreateTerminalEvent with optional workingDirectory field
    - Add CloseTerminalEvent with terminalId field
    - Add SwitchTerminalEvent with terminalId field
    - Add TerminalOutputEvent with terminalId and output fields
    - Add TerminalInputEvent with terminalId and input fields
    - Add TerminalExitedEvent with terminalId and exitCode fields
    - Add RestartTerminalEvent with terminalId field
    - Add CycleTerminalEvent with forward boolean field
    - _Requirements: 3.1-3.7, 4.1-4.5, 5.1-5.7, 8.1-8.7, 9.6_

  - [x] 7.2 Extend TerminalState to support multiple terminals
    - Open `lib/features/terminal/presentation/blocs/terminal_state.dart`
    - Add terminals field as List<TerminalInstance>
    - Add activeTerminalId field as String?
    - Add status field as TerminalStatus enum
    - Add errorMessage field as String?
    - Add activeTerminal getter that returns current TerminalInstance
    - Add terminalCount getter
    - Add canCreateTerminal getter (checks if count < 10)
    - _Requirements: 1.1-1.7, 9.1-9.7_

  - [x] 7.3 Implement terminal lifecycle logic in TerminalBloc
    - Open `lib/features/terminal/presentation/blocs/terminal_bloc.dart`
    - Inject PTYService, ShellDetector, ANSIParser, and TerminalRepository
    - Implement _onInitializeTerminal: load saved preferences, restore terminal count and working directories
    - Implement _onCreateTerminal: generate unique ID, detect shell, create PTY, subscribe to output stream, add to terminals list, set as active
    - Implement _onCloseTerminal: terminate PTY, unsubscribe streams, remove from list, activate previous terminal or create new if last
    - Implement _onSwitchTerminal: update activeTerminalId
    - Implement _onTerminalOutput: parse ANSI codes, append to terminal's output buffer, emit new state
    - Implement _onTerminalInput: write input to PTY via PTYService
    - Implement _onTerminalExited: update terminal status to exited, display exit code
    - Implement _onRestartTerminal: terminate old PTY, create new PTY with same working directory
    - Implement _onCycleTerminal: calculate next/previous index with wrapping, switch to it
    - _Requirements: 1.1-1.7, 3.1-3.7, 4.1-4.7, 5.1-5.7, 6.1-6.7, 8.1-8.7, 9.1-9.7, 13.1-13.7_

  - [x] 7.4 Write unit tests for TerminalBloc with mocked services
    - Test InitializeTerminalEvent creates initial terminal
    - Test CreateTerminalEvent adds new terminal and sets as active
    - Test CreateTerminalEvent respects max terminal limit (10)
    - Test CloseTerminalEvent removes terminal and activates previous
    - Test CloseTerminalEvent creates new terminal when closing last one
    - Test SwitchTerminalEvent updates activeTerminalId
    - Test CycleTerminalEvent wraps around terminal list
    - Test TerminalOutputEvent appends to correct terminal
    - Test TerminalInputEvent writes to PTY service
    - Test TerminalExitedEvent updates terminal status
    - Test tab cycling logic (forward, backward, wrapping)
    - _Requirements: 1.1-1.7, 3.1-3.7, 4.1-4.7, 5.1-5.7, 9.1-9.7_

- [x] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Create terminal tab bar widget
  - [x] 9.1 Implement TerminalTab widget
    - Create `lib/features/terminal/presentation/widgets/terminal_tab.dart`
    - Display terminal title with ellipsis for overflow
    - Show active styling (distinct background) when isActive is true
    - Show inactive/dimmed styling when isActive is false
    - Show close button (X icon) on hover only
    - Dispatch SwitchTerminalEvent on tab click
    - Dispatch CloseTerminalEvent on close button click
    - Apply min width 120px and max width 200px constraints
    - _Requirements: 2.1-2.7_

  - [x] 9.2 Implement TerminalTabBar widget
    - Create `lib/features/terminal/presentation/widgets/terminal_tab_bar.dart`
    - Render horizontal scrollable list of TerminalTab widgets
    - Render "+" button to create new terminal
    - Disable "+" button when terminal count >= 10
    - Dispatch CreateTerminalEvent on "+" button click
    - Add tooltip "New Terminal (Ctrl+Shift+`)" to "+" button
    - Apply consistent styling with Goox Editor theme
    - Height: 35px with bottom border
    - _Requirements: 1.1-1.7, 2.1-2.7, 3.1-3.7_

  - [x] 9.3 Write widget tests for terminal tabs
    - Test TerminalTab renders terminal title
    - Test TerminalTab shows active styling when active
    - Test TerminalTab shows close button on hover
    - Test TerminalTab dispatches SwitchTerminalEvent on click
    - Test TerminalTab dispatches CloseTerminalEvent on close click
    - Test TerminalTab truncates long titles
    - Test TerminalTabBar renders all terminal tabs
    - Test TerminalTabBar disables create button at max terminals
    - Test TerminalTabBar dispatches CreateTerminalEvent on "+" click
    - _Requirements: 2.1-2.7, 3.1-3.7_

- [ ] 10. Create terminal emulator widget
  - [x] 10.1 Implement TerminalEmulator widget for rendering and input
    - Create `lib/features/terminal/presentation/widgets/terminal_emulator.dart`
    - Use ListView.builder to render TerminalLine objects from terminal output
    - Apply monospace font (Fira Code, JetBrains Mono, or Cascadia Code)
    - Set font size to 13px and line height to 1.3
    - Implement _buildTerminalLine() to render plain text or styled TextSpan
    - Implement _buildStyledSpans() to apply ANSIStyle colors and text styles
    - Add ScrollController for auto-scroll to bottom on new output
    - Add FocusNode for keyboard input handling
    - Implement _handleKeyEvent() for keyboard input processing
    - Handle Enter key: send '\n'
    - Handle Backspace: send '\x7f'
    - Handle Ctrl+C: send '\x03' (SIGINT)
    - Handle Ctrl+D: send '\x04' (EOF)
    - Handle regular character input: send character to PTY
    - Dispatch TerminalInputEvent for all input
    - Focus terminal on tap
    - _Requirements: 7.1-7.7, 8.1-8.7, 14.7_

  - [x] 10.2 Write widget tests for terminal emulator
    - Test TerminalEmulator renders terminal lines
    - Test TerminalEmulator applies ANSI styles correctly
    - Test TerminalEmulator auto-scrolls to bottom on new output
    - Test TerminalEmulator handles Enter key
    - Test TerminalEmulator handles Ctrl+C
    - Test TerminalEmulator handles Ctrl+D
    - Test TerminalEmulator focuses on tap
    - _Requirements: 7.1-7.7, 8.1-8.7_

- [x] 11. Refactor TerminalPanelWidget to integrate new components
  - [x] 11.1 Update TerminalPanelWidget with tab bar and emulator
    - Open `lib/features/terminal/presentation/widgets/terminal_panel_widget.dart`
    - Replace dummy content with Column containing: ResizeHandle, TerminalTabBar, Expanded(TerminalEmulator)
    - Use BlocBuilder to access TerminalState
    - Pass state.terminals and state.activeTerminalId to TerminalTabBar
    - Pass state.activeTerminal to TerminalEmulator
    - Show EmptyTerminalView when no active terminal
    - Apply terminal panel height from state.height
    - Add subtle shadow or border to separate from editor area
    - _Requirements: 1.1-1.7, 2.1-2.7, 7.1-7.7, 15.6_

  - [x] 11.2 Write widget tests for TerminalPanelWidget integration
    - Test TerminalPanelWidget renders TerminalTabBar
    - Test TerminalPanelWidget renders TerminalEmulator with active terminal
    - Test TerminalPanelWidget shows EmptyTerminalView when no terminals
    - Test TerminalPanelWidget hides when isVisible is false
    - _Requirements: 1.1-1.7, 2.1-2.7_

- [x] 12. Implement keyboard shortcuts
  - [x] 12.1 Add global keyboard shortcuts for terminal control
    - Open main keyboard handler (likely in `lib/features/editor_layout/` or main app)
    - Add Ctrl+` shortcut to dispatch ToggleTerminalEvent
    - Add Ctrl+Shift+` shortcut to dispatch CreateTerminalEvent
    - Add Ctrl+PageUp shortcut to dispatch CycleTerminalEvent(forward: false)
    - Add Ctrl+PageDown shortcut to dispatch CycleTerminalEvent(forward: true)
    - Add Ctrl+Shift+W shortcut to dispatch CloseTerminalEvent for active terminal
    - Ensure terminal-focused input bypasses global shortcuts (except the above)
    - Add keyboard shortcut hints to button tooltips
    - _Requirements: 8.7, 11.1-11.7_

  - [x] 12.2 Write integration tests for keyboard shortcuts
    - Test Ctrl+` toggles terminal visibility
    - Test Ctrl+Shift+` creates new terminal
    - Test Ctrl+PageUp cycles to previous terminal
    - Test Ctrl+PageDown cycles to next terminal
    - Test Ctrl+Shift+W closes active terminal
    - Test terminal input bypasses global shortcuts
    - _Requirements: 11.1-11.7_

- [x] 13. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 14. Implement error handling and recovery
  - [x] 14.1 Add error handling for PTY and shell failures
    - Update TerminalBloc to catch PTY creation errors
    - Display error message in terminal content area when PTY creation fails
    - Display shell process start errors with reason
    - Handle shell process crashes: display exit code and mark terminal as dead
    - Handle PTY I/O errors: log error, attempt recovery, mark as dead if recovery fails
    - Add "Restart Terminal" button for dead terminals
    - Implement restart logic: create new PTY with same working directory
    - _Requirements: 13.1-13.7_

  - [x] 14.2 Write tests for error handling
    - Test PTY creation failure displays error message
    - Test shell process crash displays exit code
    - Test dead terminal shows "Restart Terminal" button
    - Test restart creates new PTY with same working directory
    - _Requirements: 13.1-13.7_

- [ ] 15. Implement performance optimizations
  - [~] 15.1 Add output batching and frame rate limiting
    - Update TerminalBloc to batch output events within 16ms window
    - Limit state emissions to max 60 FPS for terminal output
    - Implement virtualized scrolling in TerminalEmulator (render only visible lines + buffer)
    - Ensure scrollback buffer trimming works correctly (max 1000 lines)
    - Add line length limit (max 10,000 characters per line)
    - _Requirements: 14.1-14.7_

  - [~] 15.2 Write performance tests
    - Test output batching combines multiple chunks
    - Test scrollback buffer trims to 1000 lines
    - Test line length limit truncates long lines
    - Test memory usage stays within bounds with long-running terminals
    - _Requirements: 14.1-14.7_

- [x] 16. Add UI polish and theming
  - [x] 16.1 Apply final styling and visual improvements
    - Ensure TerminalTabBar uses consistent Goox Editor theme colors
    - Add smooth hover effects to TerminalTab
    - Ensure close button only appears on hover
    - Apply high-quality monospace font to TerminalEmulator
    - Set appropriate line height (1.2-1.4) for readability
    - Add status icons for terminal state (running, exited, error)
    - Add tooltips to all interactive elements
    - Ensure ANSI colors meet WCAG AA contrast standards
    - _Requirements: 15.1-15.7_

- [x] 17. Final checkpoint and integration testing
  - [x] 17.1 Run full integration tests
    - Test complete terminal lifecycle: create, use, switch, close
    - Test multiple terminals running simultaneously
    - Test persistence: restart app and verify terminals restored
    - Test keyboard shortcuts work end-to-end
    - Test error scenarios: shell not found, process crash, PTY failure
    - Test performance with high-volume output
    - Test on all supported platforms (Linux, macOS, Windows) - the PTY package handles platform differences
    - _Requirements: All requirements_

  - [x] 17.2 Final checkpoint - Ensure all tests pass
    - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- The terminal feature is embedded in the app at `lib/features/terminal/`, not a separate package
- PTY integration uses cross-platform Flutter packages (e.g., `xterm`, `flutter_pty`) that handle platform-specific implementations internally
- No need to create separate platform folders (linux, windows, macos) - the PTY packages handle this
- Platform detection is done using `dart:io` Platform class (Platform.isLinux, Platform.isMacOS, Platform.isWindows)
- Shell detection uses standard Dart Process APIs to check for shell availability
- ANSI parser is critical for proper terminal emulation - ensure comprehensive testing
- Performance optimizations are essential for handling high-volume output
- Error handling should be robust to prevent app crashes from shell process issues
