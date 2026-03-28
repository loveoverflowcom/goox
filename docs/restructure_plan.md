# Restructure Plan

This plan is for the current state of Goox, not for a hypothetical rewrite.

The repo already has the right boundary shape. The next step is to tighten the contracts, remove demo shortcuts where they matter, and move expensive work out of the input path.

## Goals

- Keep Rust as the single source of truth for text and history.
- Keep Flutter responsible for interaction and composition.
- Keep the SDK as the stable public API for editor commands and state.
- Keep the bridge surface small and explicit.
- Delay heavy features until the single-user editor path is stable.

## Phase 1: Freeze The Core Contract

| Item | What to do | Done when |
| --- | --- | --- |
| Buffer API | Keep `BufferTransaction`, `BufferPatchBatch`, `BufferSnapshot`, and viewport types stable | The UI can keep working without knowing about internal Rust changes |
| Editor state | Keep `EditorViewState` predictable and documented | Widgets can render from the state without special-case logic |
| Bridge surface | Avoid adding ad-hoc FRB calls from the app shell | All editor actions go through the SDK layer |

Why this comes first:

- it prevents the app from depending on unstable internals
- it makes the bridge easier to test
- it keeps refactors local

## Phase 2: Separate Render State From Document State

Current code still keeps a full `documentText` in Flutter state because the `TextField` needs it.

The long-term split should be:

- document state for the canonical text and revision
- viewport state for visible lines and cursor position
- UI state for selection, focus, scroll, and shell chrome

Suggested steps:

1. Keep the existing state working.
2. Introduce explicit sub-models in the SDK.
3. Make the canvas consume the smallest state it can.
4. Remove any accidental reliance on whole-document redraws.

## Phase 3: Improve The Edit Pipeline

The current edit path already works, but it can be made cleaner.

Suggested steps:

1. Normalize all text edits into one command type.
2. Keep insert, delete, and replace as variants of the same intent.
3. Use mergeable transactions for typing bursts.
4. Make undo and redo read from the revisioned history only.
5. Add tests that prove cursor movement stays correct after each edit.

## Phase 4: Implement Persistence In `core/storage`

`core/storage` is intentionally a stub today.

What should live there:

- load document by path
- save document by path
- persist dirty state
- future workspace metadata

Suggested order:

1. Implement document load.
2. Implement document save.
3. Wire save into the desktop shell.
4. Add autosave only after manual save is stable.

## Phase 5: Move Heavy Work Off The Input Path

These are good candidates for Rust workers or background tasks:

- syntax validation
- search indexing
- line indexing
- tokenization
- plugin execution

Why:

- the editor should feel immediate even on large files
- the bridge should not become a bottleneck
- UI jank is easier to avoid than to remove later

## Phase 6: Harden Extensions And Plugins

`core/engine/src/extensions.rs` already supports extension discovery and wasm activation.

Next improvements:

- define a stricter plugin contract
- validate commands before activation
- separate discovery from execution
- log plugin failures in a predictable way

Important rule:

- do not push collaboration or CRDT into the system before the single-user pipeline is stable and measurable

## Phase 7: Prepare For Advanced Editing Features

After the basics are stable, the next wave can include:

- better line indexing
- folding
- minimap
- search
- syntax highlighting with real token data
- language server integration
- collaborative editing

These features should be added after the data flow is clean, not before.

## Recommended Refactor Order

1. Stabilize the SDK and buffer contracts.
2. Clean up the render state split.
3. Finish persistence.
4. Move expensive work to background workers.
5. Tighten plugin behavior.
6. Only then add advanced editor features.

## What Not To Do Yet

- Do not replace the whole bridge layer in one shot.
- Do not move from `TextField` to a custom renderer before the state split is clear.
- Do not add collaborative editing before single-user undo, redo, and persistence are reliable.
- Do not let app code call Rust internals directly.

## Success Criteria

This refactor is healthy when:

- the app shell and the editor core can evolve independently
- the bridge API remains small
- the buffer behavior stays covered by tests
- the UI has fewer assumptions about where the data came from
- large-file behavior becomes easier to reason about

