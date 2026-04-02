# webview_all_windows_smoke

Desktop smoke test for `webview_all` on Windows and macOS.

## Run

```bash
cd apps/webview_all_windows_smoke
flutter run -d windows
flutter run -d macos
```

## What it checks

- Remote URL loading via `WebViewController.loadRequest`
- Basic desktop integration on Windows and macOS
