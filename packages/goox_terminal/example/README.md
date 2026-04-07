# Goox Terminal Example

This app shows the `goox_terminal` package running end-to-end with the Rust PTY backend.

## What It Demonstrates

- create multiple terminal sessions
- toggle terminal panels on and off
- send shell input
- resize a session
- close one session or all sessions
- display live session status and accumulated output

## Run It

From the package directory:

```bash
cd packages/goox_terminal/example
flutter run -d linux
```

Use `-d macos` or `-d windows` on the matching desktop platform.

## Notes

- The example uses the real Rust backend by default.
- The widget test uses a fake backend so it can run without native PTY support.
