# Design Document: Theme and Terminal Layout

## Overview

This document describes the design for two new features in Goox Editor: Theme Selector and Terminal Layout. These features enhance the user experience by providing theme customization and preparing the UI for future terminal integration.

### Feature Summary

**Theme Selector**: Allows users to switch between Dark, Light, and System theme modes through a settings panel. The selected theme is persisted across application restarts and automatically responds to system theme changes when System mode is selected.

**Terminal Layout**: Provides a resizable terminal panel UI at the bottom of the editor area. This is a dummy implementation without PTY (pseudo-terminal) functionality, serving as the foundation for future terminal integration.

### Design Goals

1. **Consistency**: Maintain the existing BLoC architecture pattern used throughout the codebase
2. **Persistence**: Save user preferences (theme selection, terminal visibility, panel height) across sessions
3. **Responsiveness**: Provide smooth UI updates when theme or layout changes occur
4. **Extensibility**: Design the terminal panel structure to easily accommodate future PTY implementation
5. **Integration**: Seamlessly integrate with existing editor layout and theme system

## Architecture

### High-Level Structure

The implementation follows the existing feature-based architecture with BLoC pattern:

```
lib/features/
├── theme/
│   ├── data/
│   │   ├── models/
│   │   │   └── theme_mode.dart          # Theme mode enum and extensions
│   │   └── repositories/
│   │       ├── theme_repository.dart     # Abstract repository
│   │       └── theme_repository_impl.dart # SharedPreferences implementation
│   └── presentation/
│       ├── blocs/
│       │   ├── theme_bloc.dart
│       │   ├── theme_event.dart
│       │   └── theme_state.dart
│       └── widgets/
│           └── theme_selector_widget.dart
│
└── terminal/
    ├── data/
    │   ├── models/
    │   │   └── terminal_config.dart      # Terminal configuration model
    │   └── repositories/
    │       ├── terminal_repository.dart   # Abstract repository
    │       └── terminal_repository_impl.dart # SharedPreferences implementation
    └── presentation/
        ├── blocs/
        │   ├── terminal_bloc.dart
        │   ├── terminal_event.dart
        │   └── terminal_state.dart
        └── widgets/
            └── terminal_panel_widget.dart
```

### Integration Points

1. **Main App**: `MaterialApp` theme property will be bound to `ThemeBloc` state
2. **Editor Layout**: Terminal panel will be integrated into the existing `EditorLayoutView`
3. **Settings Panel**: Theme selector will be added to the Settings tab in the sidebar
4. **Theme System**: Extends the existing `goox_ui` package with light theme colors

## Components and Interfaces

### Theme Feature

#### ThemeMode Model

```dart
enum AppThemeMode {
  dark,
  light,
  system,
}

extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.system:
        return 'System';
    }
  }
  
  String get persistenceKey {
    switch (this) {
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.system:
        return 'system';
    }
  }
  
  static AppThemeMode fromPersistenceKey(String key) {
    switch (key) {
      case 'dark':
        return AppThemeMode.dark;
      case 'light':
        return AppThemeMode.light;
      case 'system':
        return AppThemeMode.system;
      default:
        return AppThemeMode.dark;
    }
  }
}
```

#### ThemeRepository Interface

```dart
abstract class ThemeRepository {
  /// Load the saved theme mode preference
  Future<AppThemeMode> loadThemeMode();
  
  /// Save the theme mode preference
  Future<void> saveThemeMode(AppThemeMode mode);
  
  /// Get the current system theme brightness
  Brightness getSystemBrightness();
}
```

#### ThemeBloc

**Events:**
- `LoadThemePreferenceEvent`: Load saved theme preference on app start
- `SelectThemeEvent(AppThemeMode mode)`: User selects a theme mode
- `SystemThemeChangedEvent(Brightness brightness)`: System theme changed (when in System mode)

**State:**
```dart
class ThemeState {
  final AppThemeMode themeMode;        // User's selected mode (dark/light/system)
  final Brightness resolvedBrightness; // Actual brightness to apply (dark/light)
  final ThemeStatus status;            // loading, loaded, error
  
  ThemeData get themeData => resolvedBrightness == Brightness.dark 
      ? AppTheme.dark 
      : AppTheme.light;
}
```

**Business Logic:**
- When `SelectThemeEvent` is received:
  1. Save the new mode to repository
  2. Resolve the actual brightness (if system mode, query system brightness)
  3. Emit new state with updated mode and brightness
  
- When `SystemThemeChangedEvent` is received (only relevant if current mode is system):
  1. Update resolved brightness based on system brightness
  2. Emit new state
  
- When `LoadThemePreferenceEvent` is received:
  1. Load saved mode from repository
  2. Resolve brightness
  3. Emit loaded state

#### ThemeSelectorWidget

A collapsible section widget for the Settings panel:

```dart
class ThemeSelectorWidget extends StatefulWidget {
  // Displays:
  // - Section header "Theme" with expand/collapse icon
  // - When expanded: Radio buttons for Dark, Light, System
  // - Current selection highlighted
}
```

**UI Behavior:**
- Default state: collapsed
- Click header to toggle expansion
- Radio buttons trigger `SelectThemeEvent` on ThemeBloc
- Uses `BlocBuilder<ThemeBloc, ThemeState>` to display current selection

### Terminal Feature

#### TerminalConfig Model

```dart
class TerminalConfig {
  final bool isVisible;
  final double height;
  
  const TerminalConfig({
    required this.isVisible,
    required this.height,
  });
  
  // Default values
  static const double defaultHeight = 200.0;
  static const double minHeight = 100.0;
  static const double maxHeightRatio = 0.8; // 80% of window height
}
```

#### TerminalRepository Interface

```dart
abstract class TerminalRepository {
  /// Load saved terminal visibility state
  Future<bool> loadVisibility();
  
  /// Save terminal visibility state
  Future<void> saveVisibility(bool isVisible);
  
  /// Load saved terminal panel height
  Future<double> loadHeight();
  
  /// Save terminal panel height
  Future<void> saveHeight(double height);
}
```

#### TerminalBloc

**Events:**
- `InitializeTerminalEvent`: Load saved preferences on app start
- `ToggleTerminalEvent`: Toggle terminal visibility (Ctrl+`)
- `ResizeTerminalEvent(double newHeight)`: User drags resize handle

**State:**
```dart
class TerminalState {
  final bool isVisible;
  final double height;
  final TerminalStatus status; // initial, loaded
  
  const TerminalState({
    this.isVisible = false,
    this.height = TerminalConfig.defaultHeight,
    this.status = TerminalStatus.initial,
  });
}
```

**Business Logic:**
- When `InitializeTerminalEvent` is received:
  1. Load visibility and height from repository
  2. Emit loaded state with saved values
  
- When `ToggleTerminalEvent` is received:
  1. Toggle visibility
  2. Save new visibility to repository
  3. Emit new state
  
- When `ResizeTerminalEvent` is received:
  1. Constrain height to min/max bounds
  2. Save new height to repository
  3. Emit new state with updated height

#### TerminalPanelWidget

A resizable panel widget displayed below the editor area:

```dart
class TerminalPanelWidget extends StatelessWidget {
  // Displays:
  // - Header bar with "TERMINAL" label
  // - Resize handle at top edge
  // - Content area with placeholder text
  // - Monospace font styling
  // - Theme-aware colors
}
```

**UI Behavior:**
- Resize handle responds to vertical drag gestures
- Height constrained between min (100px) and max (80% of window height)
- Placeholder text: "Terminal (dummy version - PTY not implemented)"
- Uses `BlocBuilder<TerminalBloc, TerminalState>` for height
- Uses `BlocBuilder<ThemeBloc, ThemeState>` for colors

### goox_ui Package Extensions

#### AppTheme.light

Add light theme to existing `AppTheme` class:

```dart
static ThemeData get light {
  return ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppColors.lightEditorBackground,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightStatusBarBackground,
      surface: AppColors.lightEditorBackground,
      error: AppColors.errorColor,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        color: AppColors.lightTextColor,
        fontFamily: 'monospace',
      ),
    ),
  );
}
```

#### AppColors Light Theme Constants

Add light theme colors to `AppColors` class:

```dart
// Light theme colors
static const Color lightActivityBarBackground = Color(0xFFEEEEEE);
static const Color lightSidebarBackground = Color(0xFFF3F3F3);
static const Color lightEditorBackground = Color(0xFFFFFFFF);
static const Color lightTabBarBackground = Color(0xFFF3F3F3);
static const Color lightStatusBarBackground = Color(0xFF007ACC);
static const Color lightTextColor = Color(0xFF333333);
static const Color lightTextColorDimmed = Color(0xFF6C6C6C);
static const Color lightActiveTabBackground = Color(0xFFFFFFFF);
static const Color lightInactiveTabBackground = Color(0xFFECECEC);
static const Color lightHoverColor = Color(0xFFE8E8E8);
static const Color lightBorderColor = Color(0xFFDDDDDD);
static const Color lightSelectedItemColor = Color(0xFFE0E8F0);
```

## Data Models

### Theme Persistence

**Storage Key**: `theme_mode`
**Storage Format**: String (`'dark'`, `'light'`, `'system'`)
**Storage Mechanism**: `SharedPreferences`

### Terminal Persistence

**Storage Keys**:
- `terminal_visible`: Boolean
- `terminal_height`: Double

**Storage Mechanism**: `SharedPreferences`

### State Models

All state models use `Equatable` for value comparison (consistent with existing codebase):

```dart
class ThemeState extends Equatable {
  final AppThemeMode themeMode;
  final Brightness resolvedBrightness;
  final ThemeStatus status;
  
  @override
  List<Object?> get props => [themeMode, resolvedBrightness, status];
}

class TerminalState extends Equatable {
  final bool isVisible;
  final double height;
  final TerminalStatus status;
  
  @override
  List<Object?> get props => [isVisible, height, status];
}
```

## Error Handling

### Theme Feature

**Error Scenarios:**
1. **SharedPreferences failure**: If loading/saving fails, use default values (dark theme)
2. **Invalid persisted value**: If stored value is corrupted, fallback to dark theme
3. **System theme query failure**: If system brightness cannot be determined, use dark

**Error Strategy:**
- Log errors for debugging
- Always provide a valid fallback state
- Never block UI rendering due to preference errors

### Terminal Feature

**Error Scenarios:**
1. **SharedPreferences failure**: Use default values (hidden, 200px height)
2. **Invalid height value**: Constrain to valid range or use default
3. **Window resize edge cases**: Ensure terminal height never exceeds max ratio

**Error Strategy:**
- Graceful degradation to defaults
- Validate all numeric inputs
- Log errors for debugging

## Testing Strategy

### Why Property-Based Testing Does NOT Apply

This feature is **not suitable for property-based testing** because:

1. **UI Rendering Focus**: The primary functionality is UI rendering and layout, which cannot be meaningfully tested with universal properties
2. **Simple State Transitions**: Theme selection is a simple enum choice (3 options), and terminal state is boolean + constrained number
3. **No Complex Algorithms**: No data transformations, parsers, or business logic that would benefit from randomized input testing
4. **Configuration Management**: Preference persistence is a simple key-value storage operation

**Appropriate Testing Approaches:**
- **Unit Tests**: Test BLoC logic with specific examples
- **Widget Tests**: Test UI components render correctly
- **Integration Tests**: Test end-to-end flows (select theme → UI updates)

### Unit Testing Strategy

**ThemeBloc Tests:**
- Initial state is correct (dark theme, loading status)
- `LoadThemePreferenceEvent` loads saved preference correctly
- `LoadThemePreferenceEvent` uses default when no saved preference
- `SelectThemeEvent` updates state and persists to repository
- `SelectThemeEvent` with System mode queries system brightness
- `SystemThemeChangedEvent` updates brightness when in System mode
- `SystemThemeChangedEvent` ignored when not in System mode
- Repository errors handled gracefully with fallback to defaults

**TerminalBloc Tests:**
- Initial state is correct (hidden, default height)
- `InitializeTerminalEvent` loads saved preferences
- `ToggleTerminalEvent` toggles visibility and persists
- `ResizeTerminalEvent` constrains height to min/max bounds
- `ResizeTerminalEvent` persists valid height
- Repository errors handled gracefully

**Repository Tests:**
- `ThemeRepositoryImpl` saves and loads theme mode correctly
- `ThemeRepositoryImpl` returns default when no saved value
- `TerminalRepositoryImpl` saves and loads visibility/height correctly
- `TerminalRepositoryImpl` returns defaults when no saved values

### Widget Testing Strategy

**ThemeSelectorWidget Tests:**
- Renders collapsed by default
- Expands when header clicked
- Displays all three theme options when expanded
- Current selection is highlighted
- Selecting an option dispatches `SelectThemeEvent`
- Collapses when header clicked again

**TerminalPanelWidget Tests:**
- Renders with correct height from state
- Displays header with "TERMINAL" label
- Displays placeholder text
- Resize handle responds to drag gestures
- Height constrained to valid range during resize
- Applies theme colors correctly

### Integration Testing Strategy

**Theme Integration Tests:**
- Selecting Dark theme updates entire app UI to dark colors
- Selecting Light theme updates entire app UI to light colors
- Selecting System theme matches system brightness
- Theme preference persists across app restarts
- System theme changes trigger UI update when in System mode

**Terminal Integration Tests:**
- Ctrl+` keyboard shortcut toggles terminal visibility
- Terminal panel appears/disappears smoothly
- Editor area resizes when terminal visibility changes
- Terminal height persists across app restarts
- Terminal visibility persists across app restarts
- Resize handle updates terminal height in real-time

### Test Coverage Goals

- **Unit Tests**: 90%+ coverage for BLoC logic and repositories
- **Widget Tests**: All custom widgets tested for rendering and interaction
- **Integration Tests**: Critical user flows covered (theme selection, terminal toggle)

### Testing Tools

- `flutter_test`: Core testing framework
- `bloc_test`: BLoC-specific testing utilities
- `mocktail`: Mocking dependencies (repositories, SharedPreferences)

## Implementation Notes

### Integration with Existing Code

**main.dart Changes:**
```dart
// Add ThemeBloc provider
BlocProvider<ThemeBloc>(
  create: (context) => ThemeBloc(
    repository: ThemeRepositoryImpl(),
  )..add(const LoadThemePreferenceEvent()),
),

// Bind MaterialApp theme to ThemeBloc
BlocBuilder<ThemeBloc, ThemeState>(
  builder: (context, themeState) {
    return MaterialApp(
      theme: themeState.themeData,
      // ... rest of MaterialApp config
    );
  },
),
```

**editor_layout_views.dart Changes:**
```dart
// Add TerminalBloc provider to MultiBlocProvider
BlocProvider<TerminalBloc>(
  create: (context) => TerminalBloc(
    repository: TerminalRepositoryImpl(),
  )..add(const InitializeTerminalEvent()),
),

// Update Column structure to include terminal
Column(
  children: [
    Expanded(
      child: Row(/* existing sidebar + editor */),
    ),
    // Add terminal panel
    BlocBuilder<TerminalBloc, TerminalState>(
      builder: (context, terminalState) {
        if (!terminalState.isVisible) return const SizedBox.shrink();
        return TerminalPanelWidget(height: terminalState.height);
      },
    ),
    const StatusBarWidget(),
  ],
),

// Add Ctrl+` keyboard shortcut handler
if (isCtrl && event.logicalKey == LogicalKeyboardKey.backquote) {
  context.read<TerminalBloc>().add(const ToggleTerminalEvent());
  return KeyEventResult.handled;
}
```

**Settings Tab Update:**
```dart
// Replace placeholder "Settings" text with ThemeSelectorWidget
GooxDestinationTab(
  id: 'settings',
  title: 'Settings',
  icon: Icons.settings_outlined,
  alignment: GooxTabAlignment.bottom,
  builder: (context) => Container(
    width: contentWidth,
    decoration: const BoxDecoration(
      color: AppColors.sidebarBackground,
      border: Border(
        right: BorderSide(color: AppColors.borderColor),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: const Text(
            'SETTINGS',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const ThemeSelectorWidget(),
      ],
    ),
  ),
),
```

### System Theme Listening

Use `WidgetsBindingObserver` to listen for system theme changes:

```dart
class _ThemeObserver extends WidgetsBindingObserver {
  _ThemeObserver(this.onBrightnessChanged);
  
  final void Function(Brightness) onBrightnessChanged;
  
  @override
  void didChangePlatformBrightness() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    onBrightnessChanged(brightness);
  }
}

// In ThemeBloc initialization:
final observer = _ThemeObserver((brightness) {
  add(SystemThemeChangedEvent(brightness));
});
WidgetsBinding.instance.addObserver(observer);
```

### Performance Considerations

1. **Theme Switching**: Rebuilding the entire app tree is acceptable for theme changes (infrequent operation)
2. **Terminal Resize**: Use `GestureDetector.onVerticalDragUpdate` for smooth real-time updates
3. **Persistence**: Save preferences asynchronously to avoid blocking UI
4. **State Updates**: Use `copyWith` pattern for immutable state updates (consistent with existing code)

### Accessibility

1. **Theme Selector**: Ensure radio buttons are keyboard navigable and screen reader friendly
2. **Terminal Panel**: Provide semantic labels for resize handle
3. **Keyboard Shortcuts**: Document Ctrl+` shortcut for terminal toggle
4. **Color Contrast**: Ensure light theme colors meet WCAG AA standards

### Future Extensibility

**Terminal Feature:**
- Current design uses placeholder content area
- Future PTY implementation can replace placeholder with actual terminal emulator
- `TerminalBloc` can be extended with additional events (input, output, process management)
- `TerminalPanelWidget` structure supports adding tabs for multiple terminal instances

**Theme Feature:**
- Additional theme modes can be added to `AppThemeMode` enum
- Custom theme colors can be supported by extending repository interface
- Per-component theme overrides can be added to state if needed

## Summary

This design provides a solid foundation for theme customization and terminal UI in Goox Editor. The implementation follows established patterns in the codebase (BLoC architecture, feature-based structure, SharedPreferences persistence) and integrates seamlessly with existing components. The terminal panel is designed as a dummy implementation that can easily accommodate future PTY integration without architectural changes.
