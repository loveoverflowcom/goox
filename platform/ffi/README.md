# Platform FFI

This directory is reserved for low-level C-ABI exports and host integration code.

Current status:

- `goox_core.h` is a placeholder header for the future stable C interface.
- Flutter apps should not depend on this directory directly.
- Dart code should go through `platform/flutter_bridge` and then `packages/goox_editor_sdk`.
