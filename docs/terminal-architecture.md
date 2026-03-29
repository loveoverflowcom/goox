# Terminal Architecture

Goox currently has two terminal-related layers:

- the live terminal UI in Flutter
- a Rust terminal session model in `core/engine/src/terminal.rs` that is not yet the live bridge path

This document explains both, because the split matters before we decide whether to keep the current UI implementation or move more of it into Rust.

## 1. What The Terminal Does

The terminal panel is a shell workspace inside the editor shell.

Its job is to:

- start a shell process
- send keyboard input to that shell
- read stdout and stderr from the shell
- interpret ANSI escape sequences
- keep a screen grid and cursor position
- render the result inside the bottom panel

## 2. Where It Lives

| Layer | File | Role |
| --- | --- | --- |
| Flutter shell | `packages/goox_ui_shared/lib/src/layout/goox_terminal_panel.dart` | Live terminal UI, tab management, input handling, ANSI parsing, and painting |
| Layout system | `packages/goox_ui_shared/lib/src/layout/goox_layout.dart` | Hosts the terminal as a bottom panel and lets the user toggle it |
| Rust core | `core/engine/src/terminal.rs` | Rust PTY session model and screen representation, currently not the live UI path |
| Rust crate entry | `core/engine/src/api.rs` | Exposes core editor APIs; terminal APIs are not exported yet |

## 3. Current Live Flow

The current terminal path is Flutter-first.

1. `EditorPage` adds `GooxTerminalPanelTab` to the bottom panel list through `GooxLayout`.
2. `GooxTerminalPanel` creates a `_TerminalTabsController`.
3. Each terminal tab owns a `TerminalController`.
4. `TerminalController` owns a `TerminalSession`.
5. `TerminalSession` starts a shell process with `Process.start`.
6. On macOS and Linux, the shell is wrapped with `script -q /dev/null ... -i` to behave more like an interactive PTY.
7. The shell output is read from `stdout` and `stderr`.
8. `_AnsiParser` converts raw bytes into a `TerminalScreenState`.
9. `TerminalView` paints the grid with `CustomPaint`.
10. Keyboard input is converted back into shell control bytes and written to `stdin`.

In short:

- shell output becomes screen state
- screen state becomes pixels
- keyboard events become input bytes

## 4. Live Runtime Data Model

The Flutter terminal model is organized as a small stack:

- `TerminalSession` owns the spawned process and the byte stream.
- `_AnsiParser` tracks the screen buffer, cursor, colors, and bold state.
- `TerminalController` exposes the latest `TerminalScreenState` to the widget tree.
- `TerminalView` turns the state into pixels and handles selection.
- `_TerminalTabsController` manages multiple terminal tabs.

This design keeps the visible UI reactive without blocking on the shell process.

## 5. Input Path

1. The user presses a key in `TerminalView`.
2. `Focus` and `onKeyEvent` map the key into terminal control bytes.
3. Common keys are translated into terminal conventions:
   - Enter -> `\r`
   - Backspace -> `\x7f`
   - Tab -> `\t`
   - Escape -> `\x1b`
   - Arrow keys -> ANSI cursor movement sequences
4. `TerminalController.sendInput()` forwards the bytes to `TerminalSession`.
5. `TerminalSession.sendInput()` writes them to the shell process stdin.

This is the core terminal abstraction:

- keys are not handled as editor commands
- they are handled as terminal input bytes
- the shell decides what happens next

## 6. Output Path

1. The shell writes bytes to stdout or stderr.
2. `TerminalSession._onData()` receives the raw bytes.
3. `_AnsiParser.process()` decodes UTF-8 and interprets escape sequences.
4. The parser updates the screen grid and cursor state.
5. The controller notifies listeners.
6. The widget tree rebuilds and the painter redraws the grid.

This is why the terminal can display colors, cursor movement, erase commands, and other shell behaviors without a separate text editor model.

## 7. ANSI And Screen Concepts

### PTY

The process is not a plain background process.

It behaves like a terminal because it is attached to a PTY-style session or a PTY-like shell wrapper.

Why this matters:

- shells change behavior when they think they are interactive
- command-line tools emit cursor and color control codes only in terminal mode
- the terminal UI needs that interactive behavior to work correctly

### ANSI Escape Sequences

ANSI escape sequences are control codes that tell the terminal to move the cursor, clear regions, or change colors.

The parser currently handles the most important ones:

- cursor movement
- clear screen
- clear line
- SGR color and bold styling
- carriage return, line feed, and backspace

### Screen Grid

The terminal is rendered as a 2D grid of cells.

Each cell stores:

- the character to draw
- foreground color
- background color
- bold state

That grid is the visual source of truth for the terminal panel.

### Selection

Selection is handled in Flutter, not by the shell.

- dragging on the terminal updates a row and column range
- the selected text can be copied to the clipboard
- selection is separate from the shell process itself

## 8. Why There Is Also A Rust Terminal Module

`core/engine/src/terminal.rs` implements a similar terminal model in Rust.

It uses:

- `portable-pty` to create and manage the shell side
- `vte` to parse terminal escape sequences
- an internal `Screen` model to track cells and cursor position
- an FRB opaque `GooxTerminalSession` wrapper with `send_input()` and `poll_update()`

But that module is not the live UI path yet.

The most likely reason it exists is to support a future migration where:

- shell process management moves closer to the Rust core
- screen snapshots can be bridged to Flutter
- terminal behavior becomes more deterministic and testable

Think of it as a foundation, not the current production path.

## 9. How The Two Layers Relate

Current state:

- Flutter owns the terminal process and painting loop.
- Rust owns an experimental or future-facing terminal model.

Future state:

- Rust could own the shell session and screen updates.
- Flutter could keep only rendering and interaction.

That future shape would match the editor architecture more closely:

- Rust owns the session state
- Flutter renders state
- Flutter sends input

## 10. Step-By-Step Reading Order

1. Read `packages/goox_ui_shared/lib/src/layout/goox_terminal_panel.dart`.
2. Read `packages/goox_ui_shared/lib/src/layout/goox_layout.dart`.
3. Read `core/engine/src/terminal.rs`.
4. Read `core/engine/src/api.rs` to confirm what is and is not exported.
5. Compare the live Flutter path with the future Rust path.

## 11. Future Improvements

- Move terminal session management into a single Rust-backed bridge.
- Expose terminal screen snapshots through FRB.
- Reduce duplicate parsing logic between Flutter and Rust.
- Add better resize handling and terminal mode negotiation.
- Make terminal history and clipboard behavior more explicit.

## 12. Practical Rule Of Thumb

- If you are changing shell input, start in Flutter.
- If you are changing ANSI interpretation or screen semantics, inspect both Flutter and Rust.
- If you are planning a migration to Rust ownership, use `core/engine/src/terminal.rs` as the target shape.
