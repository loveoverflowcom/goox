# webview_all_windows_smoke

Desktop smoke test for `webview_all` on Windows and macOS.

## Run

```bash
cd apps/webview_all_windows_smoke
flutter run -d windows
flutter run -d macos
```

## What it checks

- Local HTML loading via `WebViewController.loadFile`
- Message passing from the page to Flutter
- Message passing from Flutter to the page
- Basic desktop integration on Windows and macOS
