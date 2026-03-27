# Project Layout

```text
goox/
├── Cargo.toml
├── apps/
│   └── goox_desktop/
├── core/
│   ├── engine/
│   └── storage/
├── platform/
│   ├── flutter_bridge/
│   └── ffi/
├── packages/
│   ├── goox_editor_sdk/
│   └── goox_ui_shared/
├── examples/
│   └── simple_editor/
├── scripts/
│   ├── build_all.sh
│   ├── apply_patches.sh
│   └── sync_bridge.sh
└── docs/
    ├── architecture.md
    ├── project-layout.md
    └── restructure_plan.md
```

## Why this split

- `apps/goox_desktop` stays focused on shell concerns, workspace UX, and platform-specific desktop packaging.
- `core/engine` and `core/storage` keep Rust primitives separate from persistence concerns so the runtime can grow without crossing boundaries.
- `platform/flutter_bridge` isolates raw FRB codegen while `packages/goox_editor_sdk` gives Flutter apps a higher-level API surface.
- `packages/goox_ui_shared` and `examples/simple_editor` make it easier to reuse widgets and validate the editor pipeline outside the main shell.
- `docs` and `scripts` stay at the repo root so architecture notes and regeneration workflows remain discoverable.
