# goox_desktop

Desktop shell for the Goox editor workspace.

## Responsibilities

- Compose `goox_editor_sdk` and `goox_ui_shared` into the full desktop UX.
- Own shell-specific layout, workspace navigation, and native app packaging.
- Avoid importing raw bridge bindings directly outside tests or dev-only helpers.

## Development

```bash
flutter analyze
flutter test
flutter run -d macos
```
