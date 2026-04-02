# Windows WebView Sample

A minimal renderer extension for testing `webview_all` on Windows.

## What it tests

- WebView creation and page loading
- File injection from the Goox host
- Host-to-webview and webview-to-host message passing

## How to use

1. Copy this folder to your Goox extensions directory, or import it from the Extensions UI.
2. Open `sample.wvtest`.
3. Look for the "Ready" state and click `Ping host`.

## Expected result

- The page loads inside the extension renderer.
- The file metadata appears in the left panel.
- The file content appears in the preview panel.
- The bridge log shows messages from Flutter when the host sends input.
