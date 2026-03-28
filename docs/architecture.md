# Goox Architecture Guide

Goox is a Flutter + Rust editor stack. The simplest rule in the whole repo is:

- Rust owns the document data and the edit history.
- Flutter owns the shell, input handling, and visual composition.
- The SDK layer translates between the two.

This document explains the current architecture in the order you should learn it.

## Start Here

1. Read the layer map.
2. Read the startup flow.
3. Read the edit flow.
4. Read the core concepts.
5. Read the restructure plan.

## 1. Layer Map

| Layer | Responsibility | Main files |
| --- | --- | --- |
| `apps/goox_desktop` | Desktop shell, app state, file explorer, settings, layout composition | `lib/main.dart`, `lib/src/app/app.dart`, `lib/src/features/editor/views/editor_page.dart` |
| `packages/goox_editor_sdk` | Stable Dart API for the editor, state models, controller, repository, and service adapters | `lib/src/features/editor/controllers/goox_editor_controller.dart`, `lib/src/features/editor/services/rust_editor_core_client.dart`, `lib/src/features/editor/models/editor_models.dart` |
| `platform/flutter_bridge` | Generated FRB bindings, bootstrap logic, and raw bridge entry points | `lib/src/goox_rust_bootstrap.dart`, `lib/src/raw_bridge/*` |
| `core/engine` | Rust text buffer, viewport queries, revision clock, undo/redo, and extension registry | `src/lib.rs`, `src/api.rs`, `src/extensions.rs`, `src/terminal.rs` |
| `core/storage` | Future persistence layer for file I/O and workspace snapshots | `src/lib.rs` |
| `packages/goox_ui_shared` | Shared editor widgets and shell layout primitives | `lib/src/layout/goox_layout.dart`, `lib/src/editor/widgets/goox_editor_canvas.dart` |
| `examples/simple_editor` | Fast playground for validating the editor pipeline without the full desktop shell | `lib/main.dart` |

## 2. The Big Idea

Goox is not trying to ship the whole text buffer back and forth on every keystroke.

Instead, the long-term shape is:

- User input happens in Flutter.
- Flutter turns the raw UI event into an editor command.
- The command crosses the bridge as a small transaction.
- Rust mutates the canonical buffer.
- Rust returns a patch batch and a revision.
- Flutter refreshes only the state it needs to paint.

That division matters because it keeps the hot path deterministic and easier to scale.

## 3. Startup Flow

1. `apps/goox_desktop/lib/main.dart` calls `GooxEditorSdkBootstrap.ensureInitialized()`.
2. `GooxRustBootstrap` finds the compiled Rust library, or builds it in debug mode if needed.
3. FRB initializes the generated bridge layer.
4. The desktop shell starts with `GooxDesktop`.
5. `GooxDesktop` shows the startup splash, then opens `EditorPage`.
6. `EditorPage` creates a `GooxEditorController` and a `FocusNode`.
7. When a workspace file is selected, the page resolves the extension, loads the file text, and publishes the active language metadata.

The important concept here is separation of concerns:

- `main.dart` is only responsible for bootstrapping.
- `GooxDesktop` is only responsible for app-level shell state.
- `EditorPage` is only responsible for the editor workspace view.
- The controller hides the Rust bridge from the UI.

## 4. Edit Flow

The current editor is a hybrid editor:

- The visible typing surface is a Flutter `TextField`.
- The document content is still owned by Rust.
- Flutter uses the Rust result to stay in sync.

Step by step:

1. The user types, deletes, pastes, or moves the cursor in `GooxEditorCanvas`.
2. `GooxCodeController` detects the text delta and computes a compact change.
3. `GooxEditorCanvas` emits a `GooxEditorTextChange`.
4. `EditorPage` forwards that change to `GooxEditorController.replaceTextRange()`.
5. `GooxEditorController` forwards the request to `RustEditorCoreClient`.
6. `RustEditorCoreClient` converts the request into a Rust `BufferTransaction`.
7. `GooxEditorRepository` and `GooxBridgeClient` call the generated FRB functions.
8. Rust receives the transaction in `core/engine/src/lib.rs`.
9. `EditorBuffer` validates the range, mutates the rope, increments the revision, and stores undo data.
10. Rust returns a `BufferPatchBatch`.
11. The Dart client maps that batch into `EditorPatch` objects and rebuilds `EditorViewState`.
12. `GooxEditorCanvas` receives the new state, updates the `TextField`, the line numbers, and the status bar.

## 5. Read Flow

Reading is the opposite direction:

1. Flutter asks for a snapshot, viewport, cursor position, or the full text.
2. The repository forwards that request through FRB.
3. Rust answers using the current canonical buffer.
4. The Dart client folds the response into `EditorViewState`.
5. Widgets rebuild from the updated state.

In the current code, the UI still keeps `documentText` in state because the `TextField` needs the full string.
That is acceptable for the current stage, but it is not the final low-latency target.

The eventual goal is to depend more on viewport snapshots and less on full-document shipping.

## 6. Core Concepts

### Rope Text Model

`core/engine` uses `ropey::Rope` as the document structure.

Why this matters:

- inserting in the middle of large text is cheaper than with a plain string
- slicing lines is easier
- the model fits editor-style workloads better than a single flat buffer

### Character Index vs Line and Column

Goox uses character indexes for mutation and line/column positions for display.

- Character indexes are best for insert and delete operations.
- Line and column positions are best for cursor display, status bars, and UI labels.
- Rust provides conversion helpers so Flutter does not have to guess.

### Transaction vs Operation

An operation is a single primitive change.

- Insert at a position
- Delete a range

A transaction is a batch of operations that should be applied together.

Why the split matters:

- a transaction can represent one user intent
- multiple low-level edits can still count as one undo step
- the bridge sends less chatter

### Patch Batch

A patch batch is the return value after Rust applies a transaction.

- It carries the new revision.
- It carries the label for debugging and UI logging.
- It carries the operations that actually changed the buffer.

That batch is what lets Flutter update its own view of the document without inventing a second source of truth.

### Revision Clock

Every successful mutation increments the revision.

Why it exists:

- it gives a stable ordering for edits
- it helps the UI know when state changed
- it gives future synchronization systems a monotonic anchor

### Viewport Rendering

Viewport rendering means asking for only the visible lines.

Even though the current demo still feeds the full `TextField`, the Rust core already exposes viewport queries because the final architecture should not depend on loading the entire document into the paint path.

### Mergeable Edits

Some edits are marked as mergeable.

That means sequential operations can be grouped into a single undo entry when the client decides they belong together.

This is the foundation for typing bursts, word-level grouping, and smarter undo behavior later.

### Extension Registry

`core/engine/src/extensions.rs` scans global and workspace extensions.

It already supports:

- filetype matching
- optional language IDs
- optional LSP executable metadata
- optional wasm plugin activation

This is the first place to look when you want file-specific behavior.

## 7. What Is Still Intentionally Lightweight

- `core/storage` is still a stub, so persistence is not fully implemented.
- The current UI still uses a `TextField` as the visible editor surface.
- Full custom painting is not the main path yet.
- Heavy features like search indexing, syntax analysis, and plugin work should move off the main input path later.

That is not a bug in the architecture. It is the natural state of a staged rewrite.

## 8. What To Learn In Order

1. Open `core/engine/src/lib.rs` and understand `EditorBuffer`.
2. Open `packages/goox_editor_sdk/lib/src/features/editor/services/rust_editor_core_client.dart`.
3. Open `packages/goox_editor_sdk/lib/src/features/editor/controllers/goox_editor_controller.dart`.
4. Open `apps/goox_desktop/lib/src/features/editor/views/editor_page.dart`.
5. Open `packages/goox_ui_shared/lib/src/editor/widgets/goox_editor_canvas.dart`.
6. Compare those files with the UML diagrams in this folder.

## 9. Diagram Index

- [system-context.puml](./system-context.puml)
- [editor-event-flow.puml](./editor-event-flow.puml)
- [buffer-ownership.puml](./buffer-ownership.puml)

## 10. Good Extension Points

- Add a new editor command in the controller layer first.
- Add the bridge function in FRB next.
- Add the Rust behavior in `core/engine` after that.
- Update the `EditorViewState` model last.

That order keeps the public API and the core data model aligned.
