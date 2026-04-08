# Goox Terminal Example

This app shows the `goox_terminal` package running end-to-end with xterm and flutter_pty.

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

- The example uses xterm for terminal emulation and flutter_pty for PTY management.
- The widget test uses a fake backend so it can run without native PTY support.
