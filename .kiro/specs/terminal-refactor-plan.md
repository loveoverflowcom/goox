# Terminal Refactor Plan

## Objective
Simplify `lib/features/terminal` by delegating UI responsibilities to `goox_terminal` package. The feature should only manage:
1. Panel visibility and sizing
2. Multiple terminal instance lifecycle
3. Integration with goox_terminal package

## Current Structure Issues
- `features/terminal` contains too many responsibilities:
  - ANSI parsing (should be in goox_terminal)
  - PTY service (should be in goox_terminal)
  - Shell detection (should be in goox_terminal)
  - Terminal UI widgets (should be in goox_terminal)
  - Terminal emulator (should be in goox_terminal)

## Target Architecture

### goox_terminal package (already has UI)
```
packages/goox_terminal/
├── lib/
│   ├── src/
│   │   ├── ui/
│   │   │   ├── terminal_widget.dart          # Main terminal widget
│   │   │   ├── terminal_theme.dart           # Theme configuration
│   │   │   └── terminal_controller.dart      # NEW: Controller for terminal
│   │   ├── services/
│   │   │   ├── pty_service.dart             # MOVE from features/terminal
│   │   │   ├── ansi_parser.dart             # MOVE from features/terminal
│   │   │   └── shell_detector.dart          # MOVE from features/terminal
│   │   └── models/
│   │       ├── terminal_output.dart          # MOVE from features/terminal
│   │       ├── ansi_style.dart              # MOVE from features/terminal
│   │       └── shell_config.dart            # MOVE from features/terminal
│   └── goox_terminal.dart
```

### lib/features/terminal (simplified)
```
lib/features/terminal/
├── data/
│   ├── models/
│   │   ├── terminal_config.dart             # KEEP: Panel configuration
│   │   └── terminal_session.dart            # NEW: Lightweight session model
│   └── repositories/
│       ├── terminal_repository.dart          # KEEP: Persistence
│       └── terminal_repository_impl.dart     # KEEP: Persistence impl
├── presentation/
│   ├── blocs/
│   │   ├── terminal_panel_bloc.dart         # RENAME: Simplified panel management
│   │   ├── terminal_panel_event.dart        # RENAME: Panel events only
│   │   └── terminal_panel_state.dart        # RENAME: Panel state only
│   └── widgets/
│       └── terminal_panel_widget.dart        # KEEP: Panel container only
```

## Refactor Steps

### Step 1: Move services to goox_terminal
- [ ] Move `ansi_parser.dart` to `packages/goox_terminal/lib/src/services/`
- [ ] Move `pty_service.dart` and `pty_service_impl.dart` to `packages/goox_terminal/lib/src/services/`
- [ ] Move `shell_detector.dart` to `packages/goox_terminal/lib/src/services/`
- [ ] Update exports in `packages/goox_terminal/lib/goox_terminal.dart`

### Step 2: Move models to goox_terminal
- [ ] Move `terminal_output.dart` to `packages/goox_terminal/lib/src/models/`
- [ ] Move `ansi_style.dart` to `packages/goox_terminal/lib/src/models/`
- [ ] Move `shell_config.dart` to `packages/goox_terminal/lib/src/models/`
- [ ] Update exports in `packages/goox_terminal/lib/goox_terminal.dart`

### Step 3: Create TerminalController in goox_terminal
- [ ] Create `packages/goox_terminal/lib/src/ui/terminal_controller.dart`
- [ ] Controller manages single terminal instance (PTY, output, input)
- [ ] Expose streams for output and status changes
- [ ] Provide methods: `start()`, `stop()`, `restart()`, `write()`

### Step 4: Move UI widgets to goox_terminal
- [ ] Move `terminal_tab.dart` to `packages/goox_terminal/lib/src/ui/`
- [ ] Move `terminal_tab_bar.dart` to `packages/goox_terminal/lib/src/ui/`
- [ ] Move `terminal_emulator.dart` to `packages/goox_terminal/lib/src/ui/`
- [ ] Update to use TerminalController instead of BLoC
- [ ] Export from `packages/goox_terminal/lib/src/ui/ui.dart`

### Step 5: Simplify features/terminal
- [ ] Delete `lib/features/terminal/data/services/` (moved to goox_terminal)
- [ ] Delete `lib/features/terminal/data/models/terminal_instance.dart` (use TerminalController)
- [ ] Delete `lib/features/terminal/data/models/terminal_output.dart` (moved to goox_terminal)
- [ ] Delete `lib/features/terminal/data/models/ansi_style.dart` (moved to goox_terminal)
- [ ] Delete `lib/features/terminal/data/models/shell_config.dart` (moved to goox_terminal)
- [ ] Delete `lib/features/terminal/presentation/widgets/terminal_tab.dart` (moved to goox_terminal)
- [ ] Delete `lib/features/terminal/presentation/widgets/terminal_tab_bar.dart` (moved to goox_terminal)
- [ ] Delete `lib/features/terminal/presentation/widgets/terminal_emulator.dart` (moved to goox_terminal)

### Step 6: Create simplified TerminalSession model
```dart
// lib/features/terminal/data/models/terminal_session.dart
class TerminalSession {
  final String id;
  final String workingDirectory;
  final TerminalController controller; // from goox_terminal
  final DateTime createdAt;
}
```

### Step 7: Simplify TerminalPanelBloc
- [ ] Rename to `TerminalPanelBloc`
- [ ] Remove ANSI parsing logic (handled by goox_terminal)
- [ ] Remove PTY management logic (handled by TerminalController)
- [ ] Keep only:
  - Panel visibility toggle
  - Panel height/resize
  - Session list management (create, close, switch)
  - Persistence of panel state

### Step 8: Update TerminalPanelWidget
- [ ] Use `TerminalWidget` from goox_terminal package
- [ ] Use `TerminalTabBar` from goox_terminal package
- [ ] Pass TerminalController to widgets
- [ ] Remove direct PTY/output handling

### Step 9: Update tests
- [ ] Move service tests to goox_terminal package
- [ ] Move widget tests to goox_terminal package
- [ ] Simplify BLoC tests to focus on panel management only
- [ ] Update integration tests

### Step 10: Update documentation
- [ ] Update spec documents to reflect new architecture
- [ ] Update README in goox_terminal package
- [ ] Document the simplified features/terminal module

## Benefits

1. **Separation of Concerns**:
   - goox_terminal: Reusable terminal UI and PTY management
   - features/terminal: App-specific panel and session management

2. **Reusability**:
   - goox_terminal can be used in other Flutter apps
   - Terminal UI is self-contained

3. **Simplicity**:
   - features/terminal has fewer responsibilities
   - Easier to maintain and test

4. **Clear Boundaries**:
   - UI logic in goox_terminal
   - App integration logic in features/terminal

## Migration Notes

- Existing tests will need updates
- BLoC events/state will be simplified
- No breaking changes to external API (keyboard shortcuts, etc.)
