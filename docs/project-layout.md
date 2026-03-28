# Project Layout

This repo is organized as a monorepo with clear boundaries between app code, reusable Flutter packages, bridge code, and Rust cores.

## Top-Level Map

| Path | Role | Notes |
| --- | --- | --- |
| `apps/` | End-user Flutter applications | Contains the desktop shell and any future app-specific shells |
| `packages/` | Reusable Flutter packages | Shared editor SDK and shared UI primitives |
| `core/` | Rust crates that own editor logic | Buffer, storage, terminal, and extension logic |
| `platform/` | Native and bridge-facing code | FRB bindings, FFI headers, and bootstrap helpers |
| `examples/` | Small playground apps | Fast way to test editor behavior in isolation |
| `docs/` | Architecture notes and diagrams | The files you are reading now |
| `scripts/` | Build and sync helpers | Bridge sync, patch application, and build automation |

## What Each Folder Means

### `apps/goox_desktop`

This is the desktop shell.

- `lib/main.dart` starts Flutter and initializes the Rust bridge.
- `lib/src/app/app.dart` defines the root app widget and startup splash.
- `lib/src/features/editor/views/editor_page.dart` wires the editor page to the controller, file picker, and status bar.
- `lib/src/state/*` holds app-level state such as open files, theme, and persistence.

Use this folder when you want to change:

- window behavior
- sidebar layout
- shell navigation
- desktop-specific file handling
- app-wide settings

### `packages/goox_editor_sdk`

This is the public Dart API for editor behavior.

- `lib/src/features/editor/models/editor_models.dart` defines the data that Flutter widgets consume.
- `lib/src/features/editor/controllers/goox_editor_controller.dart` exposes the app-facing editor controller.
- `lib/src/features/editor/services/editor_core_client.dart` defines the service contract.
- `lib/src/features/editor/services/rust_editor_core_client.dart` implements the Rust-backed version.
- `lib/src/data/*` wraps the bridge and bootstrap lifecycle.

Use this folder when you want to change:

- how Flutter talks to Rust
- editor state shape
- commands like insert, delete, undo, redo, and viewport movement
- test doubles or mock bridge behavior

### `packages/goox_ui_shared`

This package contains reusable editor and shell widgets.

- `lib/src/layout/goox_layout.dart` owns the activity bar, sidebar, editor area, and bottom panel arrangement.
- `lib/src/editor/widgets/goox_editor_canvas.dart` is the current text editing surface.
- `lib/src/editor/widgets/status/goox_status_bar.dart` renders editor status information.

Use this folder when you want to change:

- shared layout behavior
- editor widget styling
- line numbers, typography, and canvas behavior
- UI composition that should be reused across apps

### `core/engine`

This is the Rust editor core.

- `src/lib.rs` defines the buffer, transactions, revisions, viewport snapshots, and undo/redo behavior.
- `src/extensions.rs` handles extension discovery and wasm plugin activation.
- `src/terminal.rs` owns terminal-related behavior.
- `src/api.rs` is the bridge surface exported to Flutter.

Use this folder when you want to change:

- text mutation rules
- revision handling
- viewport extraction
- undo/redo semantics
- extension discovery or plugin validation

### `core/storage`

This is the future persistence crate.

- `src/lib.rs` currently contains a stub implementation.
- The current code makes it clear that file loading and saving will live here later.

Use this folder when you want to change:

- file save and load behavior
- workspace snapshot persistence
- autosave strategy

### `platform/flutter_bridge`

This is the raw FRB boundary.

- `lib/src/goox_rust_bootstrap.dart` locates the Rust dynamic library and initializes the bridge.
- `lib/src/raw_bridge/*` contains generated bindings and low-level bridge types.
- `lib/goox_flutter_bridge.dart` exposes the public bridge package.

Use this folder when you want to change:

- bridge generation
- native library bootstrapping
- platform-specific loading behavior
- raw type mapping

### `platform/ffi`

This folder is reserved for FFI-facing native headers and related platform interop experiments.

Use it when you need:

- non-FRB native integration
- C header surfaces
- lower-level host integration

### `examples/simple_editor`

This is the fastest place to test a small editor loop.

- It is intentionally lighter than the desktop app.
- It is useful for verifying behavior before wiring it into the full shell.

Use this folder when you want to:

- prototype editor interactions
- validate a UI idea quickly
- isolate a bug without the full desktop state machine

### `docs`

The docs folder contains the architecture explanation and diagrams.

- `architecture.md` explains the end-to-end system.
- `project-layout.md` explains the folder map.
- `restructure_plan.md` explains the next refactor phases.
- `system-context.puml`, `editor-event-flow.puml`, and `buffer-ownership.puml` show the system visually.

## Where To Edit Common Features

| If you want to change... | Start here |
| --- | --- |
| The editor typing behavior | `packages/goox_ui_shared/lib/src/editor/widgets/goox_editor_canvas.dart` |
| The command pipeline | `packages/goox_editor_sdk/lib/src/features/editor/controllers/goox_editor_controller.dart` |
| The Rust mutation rules | `core/engine/src/lib.rs` |
| File loading and saving | `core/storage/src/lib.rs` |
| The shell layout | `packages/goox_ui_shared/lib/src/layout/goox_layout.dart` |
| Extension detection | `core/engine/src/extensions.rs` |
| Bridge startup | `platform/flutter_bridge/lib/src/goox_rust_bootstrap.dart` |

## Practical Reading Order

1. Open `apps/goox_desktop/lib/main.dart`.
2. Follow into `apps/goox_desktop/lib/src/app/app.dart`.
3. Open `apps/goox_desktop/lib/src/features/editor/views/editor_page.dart`.
4. Open `packages/goox_ui_shared/lib/src/editor/widgets/goox_editor_canvas.dart`.
5. Open `packages/goox_editor_sdk/lib/src/features/editor/controllers/goox_editor_controller.dart`.
6. Open `packages/goox_editor_sdk/lib/src/features/editor/services/rust_editor_core_client.dart`.
7. Open `core/engine/src/lib.rs`.

That path shows you the real data flow from the desktop shell down to the Rust core and back again.
