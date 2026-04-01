# goox_desktop

Flutter desktop shell for the Goox workspace.

Rendering for extension content uses `webview_all`, with the UI kept intentionally minimal so content stays centered.

The render layer is still abstracted so Windows and Linux can hook in a different engine later without changing editor callsites.

## Status

- This package is the active desktop app.
- The Rust runtime prototype remains in the repo for experimentation, but it is not the primary rendering path.
