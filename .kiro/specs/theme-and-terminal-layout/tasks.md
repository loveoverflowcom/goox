# Implementation Plan: Theme and Terminal Layout

## Overview

This implementation plan covers two features: Theme Selector (allowing users to switch between Dark/Light/System themes) and Terminal Layout (a resizable dummy terminal panel UI). The implementation follows the existing BLoC architecture pattern and integrates with the current editor layout.

## Tasks

- [x] 1. Set up Theme feature structure and data layer
  - [x] 1.1 Create theme feature directory structure and barrel files
    - Create `lib/features/theme/` with subdirectories: `data/models/`, `data/repositories/`, `presentation/blocs/`, `presentation/widgets/`
    - Create barrel files: `data.dart`, `presentation.dart`, `theme.dart`
    - _Requirements: 5.1, 5.2_

  - [x] 1.2 Implement ThemeMode model with enum and extensions
    - Create `lib/features/theme/data/models/theme_mode.dart`
    - Define `AppThemeMode` enum with dark, light, system values
    - Add extensions for `displayName`, `persistenceKey`, and `fromPersistenceKey`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 5.6_

  - [x] 1.3 Implement ThemeRepository interface and implementation
    - Create `lib/features/theme/data/repositories/theme_repository.dart` (abstract class)
    - Create `lib/features/theme/data/repositories/theme_repository_impl.dart` (SharedPreferences implementation)
    - Implement methods: `loadThemeMode()`, `saveThemeMode()`, `getSystemBrightness()`
    - _Requirements: 1.7, 5.3_

  - [ ]* 1.4 Write unit tests for ThemeRepository
    - Test save and load operations
    - Test default value handling when no saved preference exists
    - Test error handling for SharedPreferences failures
    - _Requirements: 1.7, 5.3_

- [x] 2. Implement Theme BLoC and state management
  - [x] 2.1 Create ThemeBloc events
    - Create `lib/features/theme/presentation/blocs/theme_event.dart`
    - Define events: `LoadThemePreferenceEvent`, `SelectThemeEvent`, `SystemThemeChangedEvent`
    - _Requirements: 5.5_

  - [x] 2.2 Create ThemeBloc state
    - Create `lib/features/theme/presentation/blocs/theme_state.dart`
    - Define `ThemeState` with `themeMode`, `resolvedBrightness`, `status` fields
    - Add `themeData` getter that returns appropriate `ThemeData`
    - Use `Equatable` for value comparison
    - _Requirements: 5.6_

  - [x] 2.3 Implement ThemeBloc logic
    - Create `lib/features/theme/presentation/blocs/theme_bloc.dart`
    - Implement event handlers for all three events
    - Handle theme mode resolution (especially System mode)
    - Implement system theme change listener using `WidgetsBindingObserver`
    - _Requirements: 1.2, 1.3, 1.4, 1.5, 5.1, 5.2, 5.3, 5.4_

  - [ ]* 2.4 Write unit tests for ThemeBloc
    - Test initial state and `LoadThemePreferenceEvent`
    - Test `SelectThemeEvent` for all three theme modes
    - Test `SystemThemeChangedEvent` behavior in System mode vs other modes
    - Test error handling and fallback to defaults
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 3. Implement Theme Selector UI widget
  - [x] 3.1 Create ThemeSelectorWidget
    - Create `lib/features/theme/presentation/widgets/theme_selector_widget.dart`
    - Implement collapsible section with header "Theme"
    - Add radio buttons for Dark, Light, System options
    - Use `BlocBuilder<ThemeBloc, ThemeState>` to display current selection
    - Dispatch `SelectThemeEvent` when user selects an option
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [ ]* 3.2 Write widget tests for ThemeSelectorWidget
    - Test default collapsed state
    - Test expand/collapse toggle behavior
    - Test radio button rendering and selection
    - Test event dispatching on selection
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 4. Extend goox_ui package with light theme
  - [x] 4.1 Add light theme colors to AppColors
    - Open `packages/goox_ui/lib/src/theme/app_colors.dart`
    - Add light theme color constants (lightActivityBarBackground, lightSidebarBackground, etc.)
    - _Requirements: 7.4, 7.5, 7.7_

  - [x] 4.2 Add AppTheme.light getter
    - Open `packages/goox_ui/lib/src/theme/app_theme.dart`
    - Implement `light` getter returning `ThemeData.light()` with custom colors
    - _Requirements: 7.4, 7.5, 7.7_

- [x] 5. Checkpoint - Verify theme feature works independently
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Set up Terminal feature structure and data layer
  - [x] 6.1 Create terminal feature directory structure and barrel files
    - Create `lib/features/terminal/` with subdirectories: `data/models/`, `data/repositories/`, `presentation/blocs/`, `presentation/widgets/`
    - Create barrel files: `data.dart`, `presentation.dart`, `terminal.dart`
    - _Requirements: 6.1, 6.2_

  - [x] 6.2 Implement TerminalConfig model
    - Create `lib/features/terminal/data/models/terminal_config.dart`
    - Define `TerminalConfig` class with `isVisible` and `height` fields
    - Add constants: `defaultHeight`, `minHeight`, `maxHeightRatio`
    - _Requirements: 3.2, 4.6_

  - [x] 6.3 Implement TerminalRepository interface and implementation
    - Create `lib/features/terminal/data/repositories/terminal_repository.dart` (abstract class)
    - Create `lib/features/terminal/data/repositories/terminal_repository_impl.dart` (SharedPreferences implementation)
    - Implement methods: `loadVisibility()`, `saveVisibility()`, `loadHeight()`, `saveHeight()`
    - _Requirements: 4.5, 4.6, 6.4_

  - [ ]* 6.4 Write unit tests for TerminalRepository
    - Test save and load operations for visibility and height
    - Test default value handling
    - Test error handling
    - _Requirements: 4.5, 4.6, 6.4_

- [x] 7. Implement Terminal BLoC and state management
  - [x] 7.1 Create TerminalBloc events
    - Create `lib/features/terminal/presentation/blocs/terminal_event.dart`
    - Define events: `InitializeTerminalEvent`, `ToggleTerminalEvent`, `ResizeTerminalEvent`
    - _Requirements: 6.5_

  - [x] 7.2 Create TerminalBloc state
    - Create `lib/features/terminal/presentation/blocs/terminal_state.dart`
    - Define `TerminalState` with `isVisible`, `height`, `status` fields
    - Use `Equatable` for value comparison
    - _Requirements: 6.6_

  - [x] 7.3 Implement TerminalBloc logic
    - Create `lib/features/terminal/presentation/blocs/terminal_bloc.dart`
    - Implement event handlers for all three events
    - Add height constraint logic (min/max bounds)
    - _Requirements: 4.2, 4.3, 4.5, 4.6, 6.1, 6.2, 6.3, 6.4_

  - [ ]* 7.4 Write unit tests for TerminalBloc
    - Test initial state and `InitializeTerminalEvent`
    - Test `ToggleTerminalEvent` behavior
    - Test `ResizeTerminalEvent` with height constraints
    - Test persistence operations
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 8. Implement Terminal Panel UI widget
  - [x] 8.1 Create TerminalPanelWidget
    - Create `lib/features/terminal/presentation/widgets/terminal_panel_widget.dart`
    - Implement header bar with "TERMINAL" label
    - Add resize handle at top edge with drag gesture detection
    - Add content area with placeholder text and monospace font
    - Use `BlocBuilder<TerminalBloc, TerminalState>` for height
    - Use `BlocBuilder<ThemeBloc, ThemeState>` for theme colors
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

  - [ ]* 8.2 Write widget tests for TerminalPanelWidget
    - Test rendering with correct height
    - Test header and placeholder text display
    - Test resize handle drag behavior
    - Test height constraints during resize
    - Test theme color application
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [x] 9. Checkpoint - Verify terminal feature works independently
  - Ensure all tests pass, ask the user if questions arise.

- [x] 10. Integrate Theme feature into main app
  - [x] 10.1 Add ThemeBloc provider to main.dart
    - Open `lib/main.dart`
    - Add `BlocProvider<ThemeBloc>` to the provider tree
    - Initialize with `LoadThemePreferenceEvent`
    - _Requirements: 5.1, 5.3, 7.1_

  - [x] 10.2 Bind MaterialApp theme to ThemeBloc state
    - Wrap `MaterialApp` with `BlocBuilder<ThemeBloc, ThemeState>`
    - Set `theme` property to `themeState.themeData`
    - _Requirements: 7.1, 7.2, 7.3_

  - [x] 10.3 Add ThemeSelectorWidget to Settings panel
    - Open `lib/features/editor_layout/presentation/views/editor_layout_views.dart`
    - Replace placeholder "Settings" text with `ThemeSelectorWidget`
    - Add proper styling and layout
    - _Requirements: 2.1_

  - [ ]* 10.4 Write integration tests for theme switching
    - Test Dark theme selection updates entire UI
    - Test Light theme selection updates entire UI
    - Test System theme follows system brightness
    - Test theme persistence across app restarts
    - _Requirements: 1.2, 1.3, 1.4, 1.5, 1.7, 7.1, 7.2, 7.3_

- [x] 11. Integrate Terminal feature into editor layout
  - [x] 11.1 Add TerminalBloc provider to editor layout
    - Open `lib/features/editor_layout/presentation/views/editor_layout_views.dart`
    - Add `BlocProvider<TerminalBloc>` to the MultiBlocProvider
    - Initialize with `InitializeTerminalEvent`
    - _Requirements: 6.1, 6.4_

  - [x] 11.2 Add TerminalPanelWidget to layout structure
    - Update Column structure to include terminal panel below editor area
    - Use `BlocBuilder<TerminalBloc, TerminalState>` to conditionally render based on visibility
    - Ensure editor area uses `Expanded` to properly resize
    - _Requirements: 3.1, 4.3, 4.4_

  - [x] 11.3 Implement Ctrl+` keyboard shortcut for terminal toggle
    - Add keyboard event handler in editor layout
    - Detect Ctrl+` combination
    - Dispatch `ToggleTerminalEvent` to TerminalBloc
    - _Requirements: 4.1, 4.2_

  - [ ]* 11.4 Write integration tests for terminal panel
    - Test Ctrl+` toggles terminal visibility
    - Test editor area resizes when terminal appears/disappears
    - Test terminal height persistence
    - Test resize handle updates height in real-time
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 12. Final checkpoint and verification
  - [x] 12.1 Verify all features work together
    - Test theme switching with terminal visible and hidden
    - Test terminal panel applies correct theme colors
    - Verify all persistence works correctly
    - _Requirements: 3.7, 7.2, 7.3_

  - [x] 12.2 Ensure all tests pass
    - Run all unit tests
    - Run all widget tests
    - Run all integration tests
    - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The design uses Dart/Flutter, so all code will be in Dart
- Property-based testing is not applicable for this feature (UI rendering and simple state management)
- Testing focuses on unit tests for BLoC logic and widget tests for UI components
- Integration tests verify end-to-end flows
