# Project Layout

```text
goox/
├── Cargo.toml
├── apps/
│   └── goox_flutter/
│       └── lib/src/
│           ├── app/
│           ├── features/editor/
│           └── theme/
├── crates/
│   └── goox_core/
│       └── src/lib.rs
└── docs/
    ├── architecture.md
    ├── buffer-ownership.puml
    ├── editor-event-flow.puml
    └── system-context.puml
```

## Why this split

- `apps/goox_flutter` stays focused on shell concerns: input, layout, painting, and UX instrumentation.
- `crates/goox_core` holds stateful editor primitives that should remain platform-neutral.
- `docs` is kept at the repo root so the diagrams stay close to both implementations and can evolve with the architecture.
