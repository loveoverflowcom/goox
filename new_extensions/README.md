# Goox New Extensions

This directory contains extension sources that can be copied into a Goox workspace or imported through the app.

## Included Samples

- `dart`: language support sample
- `lua`: language support sample
- `windows-webview-sample`: renderer smoke test for `webview_all` on Windows

## Windows WebView Smoke Test

Use `windows-webview-sample` when you want a minimal renderer extension that exercises:

- `webview_all` loading
- HTML file loading from a local extension directory
- JavaScript bridge messages between the webview and Flutter
- file-content injection into the page

### Quick Start

1. Copy `new_extensions/windows-webview-sample` to your Goox extensions directory, or import it from the Extensions UI.
2. Open `sample.wvtest` in Goox.
3. Confirm the page loads and the bridge status updates when you click `Ping host`.

### Notes

- `config.json` is included for the current import flow in the desktop app.
- `extension.toml` is included for the newer manifest format used by the core loader.
