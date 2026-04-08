# Implementation Plan: Terminal XTerm Refactor

## Overview

This implementation plan refactors the terminal module from Rust FFI-based architecture to pure Dart implementation using xterm and flutter_pty. The refactor consolidates all terminal functionality into the goox_terminal package, removes lib/features/terminal from the main app, and provides a clean migration path with backward compatibility during transition.

## Tasks

- [x] 1. Set up foundation and dependencies
  - Update goox_terminal package pubspec.yaml with xterm ^4.0.0 and flutter_pty ^0.4.2
  - Remove flutter_rust_bridge and ffi dependencies
  - Create directory structure for new components (models, controllers, services, ui)
  - _Requirements: 14.2, 14.3, 15.4_

- [x] 2. Implement core data models
  - [x] 2.1 Create TerminalStatus enum
    - Define enum values: initializing, running, exited, error
    - Add helper methods: isActive, canSendInput
    - _Requirements: 1.5, 10.1, 10.2_
  
  - [x] 2.2 Create PtySize model
    - Implement PtySize class with rows and cols properties
    - Add validation for dimensions (1-1000 range)
    - Add defaultSize constant (24x80)
    - _Requirements: 3.4, 3.5_
  
  - [x] 2.3 Create ShellConfig model
    - Implement ShellConfig class with shellPath, arguments, environment, workingDirectory
    - Add validation methods for shell path, working directory, environment variables
    - Add factory methods: bash(), zsh(), fish(), powershell(), cmd()
    - _Requirements: 4.3, 4.4, 4.5, 13.5, 20.1, 20.2, 20.3_
  
  - [x] 2.4 Create TerminalTheme model
    - Implement TerminalTheme class with all color properties
    - Add factory methods: dark(), light()
    - Add toXTermTheme() conversion method
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 3. Implement ShellDetector service
  - [x] 3.1 Create ShellDetector class
    - Implement detectDefaultShell() for platform-specific detection
    - Implement detectAvailableShells() to find all valid shells
    - Implement isShellAvailable() to check shell path validity
    - Add platform-specific logic for Linux, macOS, Windows
    - _Requirements: 4.1, 4.2, 13.1, 13.2, 13.3, 13.4_

- [x] 4. Implement TerminalController
  - [x] 4.1 Create TerminalController class structure
    - Define class with id, terminal, pty, status, title, pid, exitCode properties
    - Add constructor with required parameters
    - Add status stream and title notifier
    - _Requirements: 1.1, 16.5, 17.2, 19.5_
  
  - [x] 4.2 Implement initialize() method
    - Create xterm Terminal instance with maxLines: 1000
    - Start flutter_pty Pty process with shell configuration
    - Connect PTY output stream to terminal input
    - Connect terminal output callback to PTY input
    - Set status to running and capture PID
    - _Requirements: 1.1, 1.2, 1.3, 17.1, 18.3_
  
  - [x] 4.3 Implement write() method
    - Validate terminal status is running
    - Encode input as UTF-8
    - Write to PTY input
    - Throw StateError if not running
    - _Requirements: 7.1, 7.2, 7.4, 9.5_
  
  - [x] 4.4 Implement resize() method
    - Validate dimensions are in valid range (1-1000)
    - Resize PTY with new dimensions
    - Update terminal view dimensions
    - Update stored size property
    - Throw ArgumentError for invalid dimensions
    - _Requirements: 3.1, 3.2, 3.3, 9.4_
  
  - [x] 4.5 Implement dispose() method
    - Cancel output subscription
    - Kill PTY process
    - Dispose xterm terminal instance
    - Set status to exited
    - _Requirements: 1.4, 8.1, 8.2, 8.3, 10.2_
  
  - [x] 4.6 Implement restart() method
    - Dispose current PTY and terminal
    - Create new PTY with same ShellConfig
    - Create new xterm terminal instance
    - Update status to running on success, error on failure
    - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5_
  
  - [x] 4.7 Implement kill() method
    - Send signal to PTY process
    - Handle SIGTERM, SIGKILL signals
    - _Requirements: 1.4_
  
  - [x] 4.8 Implement status and title tracking
    - Handle PTY exit events and capture exit code
    - Parse title escape sequences from PTY output
    - Emit status changes on status stream
    - Notify title changes via ValueListenable
    - Handle PTY output stream errors
    - _Requirements: 1.5, 7.5, 9.2, 16.1, 16.2, 17.3, 17.4, 17.5, 19.1, 19.2, 19.3, 19.4_
  
  - [ ]* 4.9 Write unit tests for TerminalController
    - Test initialization with valid and invalid configs
    - Test write to running and closed terminals
    - Test resize with valid and invalid dimensions
    - Test dispose cleanup
    - Test status transitions
    - Test restart functionality
    - _Requirements: All Requirement 1, 3, 7, 8, 17, 18, 19_

- [x] 5. Checkpoint - Ensure core controller tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implement TerminalSessionManager
  - [x] 6.1 Create TerminalSessionManager singleton class
    - Implement singleton pattern with instance getter
    - Add session registry (Map<String, TerminalController>)
    - Add activeSessionId property
    - Extend ChangeNotifier for reactive updates
    - _Requirements: 2.1, 2.4, 10.3, 10.4, 10.5_
  
  - [x] 6.2 Implement createSession() method
    - Validate session count < maxSessions (10)
    - Generate unique session ID
    - Create TerminalController with provided or default config
    - Add controller to registry
    - Increment session count
    - Set as active session if first session
    - Notify listeners
    - _Requirements: 2.1, 2.2, 2.5, 9.3, 20.4_
  
  - [x] 6.3 Implement closeSession() method
    - Get controller from registry
    - Call controller.dispose()
    - Remove from registry
    - Decrement session count
    - Update activeSessionId if closing active session
    - Notify listeners
    - _Requirements: 2.3, 8.4, 8.5_
  
  - [x] 6.4 Implement session lookup and management methods
    - Implement getSession(id) to retrieve controller
    - Implement allSessions getter
    - Implement sessionCount getter
    - Implement canCreateSession getter
    - Implement closeAllSessions() method
    - _Requirements: 2.3, 8.4_
  
  - [x] 6.5 Implement active session management
    - Implement activeSession getter
    - Implement activeSessionId setter with validation
    - Ensure active session exists in registry
    - Notify listeners on active session change
    - _Requirements: 2.4, 10.3_
  
  - [ ]* 6.6 Write unit tests for TerminalSessionManager
    - Test session creation and registry addition
    - Test session limit enforcement
    - Test session closure and cleanup
    - Test active session switching
    - Test session count consistency
    - Test closeAllSessions
    - _Requirements: All Requirement 2, 8, 10_

- [x] 7. Checkpoint - Ensure session manager tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Implement TerminalView widget
  - [x] 8.1 Create TerminalView StatefulWidget
    - Accept TerminalController and TerminalTheme parameters
    - Create state class with focus node
    - _Requirements: 5.1, 6.1_
  
  - [x] 8.2 Implement terminal rendering
    - Use xterm TerminalView widget
    - Apply theme to terminal
    - Handle terminal focus management
    - _Requirements: 5.1, 6.1, 11.5_
  
  - [x] 8.3 Implement keyboard input handling
    - Handle character input and send to controller
    - Handle special keys (Enter, Backspace, Ctrl+C, Ctrl+D)
    - Send appropriate escape sequences
    - _Requirements: 11.1, 11.2_
  
  - [x] 8.4 Implement mouse input handling
    - Handle mouse clicks for cursor positioning
    - Handle scroll events
    - _Requirements: 11.3, 11.4_
  
  - [x] 8.5 Implement auto-scroll behavior
    - Auto-scroll to bottom when at bottom and new output arrives
    - Disable auto-scroll when user scrolls up
    - Re-enable auto-scroll when user scrolls to bottom
    - _Requirements: 12.3, 12.4, 12.5_
  
  - [ ]* 8.6 Write widget tests for TerminalView
    - Test rendering with controller
    - Test theme application
    - Test keyboard input forwarding
    - Test focus management
    - _Requirements: All Requirement 11_

- [x] 9. Implement TerminalTabBar widget
  - [x] 9.1 Create TerminalTabBar StatelessWidget
    - Accept TerminalSessionManager and TerminalTheme parameters
    - Listen to session manager changes
    - _Requirements: 5.1_
  
  - [x] 9.2 Implement tab rendering
    - Display tab for each session
    - Show active tab indicator
    - Show terminal status indicators (running, exited, error)
    - Display terminal title in tab
    - _Requirements: 5.4, 5.5, 16.3_
  
  - [x] 9.3 Implement tab interactions
    - Handle tab click to switch active session
    - Handle close button click to close session
    - Handle new terminal button click to create session
    - Disable new terminal button when at limit
    - Show tooltip when at session limit
    - _Requirements: 5.2, 5.3, 5.4, 9.3_
  
  - [ ]* 9.4 Write widget tests for TerminalTabBar
    - Test tab rendering for multiple sessions
    - Test tab selection
    - Test tab close action
    - Test new terminal button
    - Test session limit UI
    - _Requirements: All Requirement 5_

- [x] 10. Implement TerminalPanel widget
  - [x] 10.1 Create TerminalPanel StatefulWidget
    - Accept optional sessionManager, theme, initialHeight, visible parameters
    - Create state class with panel height management
    - _Requirements: 5.1, 15.1_
  
  - [x] 10.2 Implement panel layout
    - Display TerminalTabBar at top
    - Display active TerminalView below tabs
    - Handle panel visibility toggle
    - Handle panel resize with drag handle
    - _Requirements: 5.1_
  
  - [x] 10.3 Implement keyboard shortcuts
    - Ctrl+Shift+` to create new terminal
    - Handle shortcuts via Shortcuts widget
    - _Requirements: 11.1, 11.2_
  
  - [x] 10.4 Wire up session manager
    - Use TerminalSessionManager.instance by default
    - Listen to active session changes
    - Update displayed terminal view when active session changes
    - _Requirements: 2.4, 5.1_
  
  - [ ]* 10.5 Write widget tests for TerminalPanel
    - Test panel rendering with tabs and terminal
    - Test panel visibility toggle
    - Test panel resize
    - Test keyboard shortcuts
    - _Requirements: All Requirement 5_

- [x] 11. Checkpoint - Ensure UI component tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Implement buffer management in TerminalController
  - [x] 12.1 Configure terminal buffer limits
    - Set maxLines to 1000 in Terminal constructor
    - Verify xterm handles line removal automatically
    - _Requirements: 12.1, 12.2_

- [x] 13. Implement UTF-8 handling
  - [x] 13.1 Add UTF-8 encoding/decoding
    - Decode PTY output with allowMalformed: true
    - Encode terminal input as UTF-8 before writing to PTY
    - _Requirements: 7.3, 7.4_

- [x] 14. Implement error handling
  - [x] 14.1 Add PtyCreationException class
    - Create custom exception for PTY creation failures
    - Include descriptive error messages
    - _Requirements: 9.1_
  
  - [x] 14.2 Add error handling in TerminalController
    - Wrap PTY.start in try-catch and throw PtyCreationException
    - Handle PTY output stream errors and set status to error
    - Validate inputs and throw ArgumentError/StateError appropriately
    - _Requirements: 9.1, 9.2, 9.4, 9.5_
  
  - [x] 14.3 Add error UI indicators
    - Show error indicator in terminal tab when status is error
    - Show "Restart Terminal" button in TerminalView when status is error
    - _Requirements: 9.2_

- [ ] 15. Create public API exports
  - [x] 15.1 Create goox_terminal.dart barrel file
    - Export TerminalPanel widget
    - Export TerminalSessionManager
    - Export TerminalController
    - Export all models (TerminalStatus, ShellConfig, PtySize, TerminalTheme)
    - Export ShellDetector
    - Do not export internal implementation details
    - _Requirements: 15.4_

- [x] 16. Remove Rust FFI code from goox_terminal package
  - [x] 16.1 Delete Rust FFI artifacts
    - Delete rust/ directory
    - Delete lib/src/rust/ generated bindings
    - Delete flutter_rust_bridge.yaml config
    - _Requirements: 14.1, 14.4_
  
  - [x] 16.2 Update package documentation
    - Update README.md to reflect new architecture
    - Remove Rust build instructions
    - Add xterm and flutter_pty usage documentation
    - _Requirements: 14.1_

- [x] 17. Remove lib/features/terminal from main app
  - [x] 17.1 Delete terminal feature directory
    - Delete lib/features/terminal/ directory completely
    - _Requirements: 14.5, 15.5_
  
  - [x] 17.2 Update main app imports
    - Replace all imports from lib/features/terminal with goox_terminal package imports
    - Update editor layout to use TerminalPanel from goox_terminal
    - _Requirements: 15.5_
  
  - [x] 17.3 Remove terminal-related blocs from main app
    - Remove terminal bloc if it exists in main app
    - Verify all terminal state is managed by goox_terminal
    - _Requirements: 15.2, 15.3_

- [x] 18. Integration and wiring
  - [x] 18.1 Integrate TerminalPanel into main app layout
    - Add TerminalPanel to editor layout
    - Configure initial height and visibility
    - Wire up theme from app theme
    - _Requirements: 5.1, 6.1_
  
  - [x] 18.2 Test end-to-end terminal functionality
    - Create terminal session from UI
    - Execute commands and verify output
    - Switch between multiple terminals
    - Close terminals
    - Verify resource cleanup
    - _Requirements: All requirements_
  
  - [ ]* 18.3 Write integration tests
    - Test end-to-end terminal session lifecycle
    - Test multiple session management
    - Test terminal panel UI interactions
    - Test keyboard shortcuts
    - Test theme application
    - _Requirements: All requirements_

- [x] 19. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- This is a large refactor - tasks are organized by layers (models → services → controllers → UI → integration)
- Migration removes all Rust FFI code and consolidates functionality into goox_terminal package
- Main app will only import from goox_terminal package after migration
