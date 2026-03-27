# Goox Architecture Skeleton

## Scope

This workspace intentionally builds only the core primitives for a low-latency editor:

- `core/engine`: Rust buffer primitives, revision clock, patch batches, undo/redo, and viewport extraction.
- `core/storage`: persistence-facing Rust crate reserved for file I/O and workspace state.
- `platform/flutter_bridge`: raw `flutter_rust_bridge` bindings and low-level bootstrap code.
- `packages/goox_editor_sdk`: high-level Dart API and controller/state surface for Flutter apps.
- `packages/goox_ui_shared`: reusable editor widgets and shared visual primitives.
- `apps/goox_desktop`: desktop shell that composes the SDK and shared UI packages.
- `examples/simple_editor`: lightweight playground used to validate the editor path quickly.

The repo now wires FRB into the Rust engine through a dedicated platform boundary. Flutter apps are expected to talk to `goox_editor_sdk`, not to generated bindings directly.

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

- Input events originate in Flutter UI layers.
- `goox_editor_sdk` translates those events into bridge calls and exposes editor state back to the app.
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
- SDK owns:
  - editor session lifecycle
  - bridge bootstrapping and translation to Dart models
  - state exposure for app and shared widgets
- Plugins should own:
  - isolated compute
  - async edit proposals

## Recommended Next Steps

1. Flesh out `core/storage` so the new crate split becomes operational, not just structural.
2. Expand `goox_editor_sdk` mocks and adapters so UI packages can test richer behaviors without native Rust.
3. Move syntax highlighting, search, and plugins onto a worker pool in Rust.
4. Add a dedicated line index cache beside the rope before implementing folding or minimap features.
5. Introduce CRDT only after the single-player pipeline is stable and measurable.

## Trade-offs

- The repo now has the right boundaries, but `core/storage`, `platform/ffi`, and some platform metadata are still intentionally lightweight until the runtime surface stabilizes.
- The Rust engine uses `ropey` because the architecture already assumes rope semantics. That is the right foundation for editor-scale text, but line index caching is still the next likely hotspot.
- Undo merging is supported conceptually via `mergeable`, but the current demo does not yet perform time-window batching.
