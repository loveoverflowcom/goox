# macOS Platform Implementation

This folder contains the macOS-specific implementation of the `goox_terminal` plugin.

## Structure

- `goox_terminal.podspec` - CocoaPods specification file
- `Classes/GooxTerminalPlugin.swift` - Swift plugin implementation
- `.gitignore` - Git ignore rules for macOS build artifacts

## Overview

The goox_terminal package uses pure Dart implementation with `flutter_pty` for PTY management. No native Rust code compilation is required.

## Building

The plugin integrates seamlessly with Flutter's standard build process.

### Requirements

- macOS 10.14 or later
- Xcode 12.0 or later

### Build Process

Simply run:

```bash
flutter build macos
```

The plugin will be automatically included in your Flutter app build.

## Notes

- The plugin uses `flutter_pty` which handles PTY operations through Dart FFI
- No additional build configuration is needed
- The plugin supports both Intel (x86_64) and Apple Silicon (arm64) architectures
