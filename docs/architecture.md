# Goox Architecture Skeleton

## Scope

This workspace intentionally builds only the core primitives for a low-latency editor:

- `crates/goox_core`: Rust buffer primitives, revision clock, patch batches, undo/redo, viewport extraction.
- `apps/goox_flutter`: Flutter shell that demonstrates the intended rendering and interaction pipeline.
- `docs/`: architecture notes and PlantUML diagrams.

The demo does **not** wire `flutter_rust_bridge` yet. Instead, Flutter talks to a local `EditorCoreClient` that mirrors the same patch-based protocol so the UI can run immediately while the Rust core stays focused on ownership and data flow.

## Core Decisions

### 1. Buffer model

- Canonical text ownership lives in Rust.
- Operations are transaction-based:
  - `Insert { char_index, text }`
  - `Delete { start, end }`
- Undo/redo stores inverse operations, not full document snapshots.
- Viewport extraction is a first-class primitive, so Flutter never needs the full document to paint.

### 2. Rendering model

- Flutter renders only visible lines through `CustomPaint`.
- The canvas receives a viewport model, not the full rope.
- Paragraph creation is cached per visible line to reflect the intended production path.
- Keyboard input is captured outside `TextField` so the demo follows the custom-editor direction.

### 3. Sync model

- Input events originate in Flutter.
- Rust applies operations and increments a monotonic revision.
- A patch batch crosses the bridge in-order.
- Flutter updates local presentation state from patches and repaints the viewport.

## Ownership

- Rust owns:
  - buffer text
  - revision IDs
  - undo/redo stacks
  - viewport queries
- Flutter owns:
  - focus
  - gestures
  - key dispatch
  - paragraph cache and paint scheduling
- Plugins should own:
  - isolated compute
  - async edit proposals

## Recommended Next Steps

1. Add `flutter_rust_bridge` codegen and replace the local `LocalEditorCoreClient`.
2. Move syntax highlighting, search, and plugins onto a worker pool in Rust.
3. Add a dedicated line index cache beside the rope before implementing folding or minimap features.
4. Introduce CRDT only after the single-player pipeline is stable and measurable.

## Trade-offs

- The Flutter demo uses an in-memory Dart buffer for runtime convenience. That keeps the demo runnable but means the FRB bridge is still a design boundary, not a finished integration.
- The Rust crate uses `ropey` now because the architecture already assumes rope semantics. That is the right foundation for editor-scale text, but line index caching is still the next likely hotspot.
- Undo merging is supported conceptually via `mergeable`, but the current demo does not yet perform time-window batching.
