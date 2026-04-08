# Windows Platform Implementation

This folder contains the Windows-specific implementation of the `goox_terminal` plugin.

## Structure

- `CMakeLists.txt` - CMake build configuration
- `goox_terminal_plugin.cpp` - C++ plugin implementation
- `goox_terminal_plugin.h` - Plugin header file
- `goox_terminal_plugin_c_api.cpp` - C API wrapper
- `include/goox_terminal/goox_terminal_plugin_c_api.h` - C API header
- `.gitignore` - Git ignore rules for Windows build artifacts

## Overview

The goox_terminal package uses pure Dart implementation with `flutter_pty` for PTY management. No native Rust code compilation is required.

## Building

The plugin integrates seamlessly with Flutter's standard build process.

### Requirements

- Windows 10 version 1809 or later
- Visual Studio 2019 or later (with C++ desktop development workload)
- CMake 3.14 or later

### Build Process

Simply run:

```bash
flutter build windows
```

The plugin will be automatically included in your Flutter app build.

## Notes

- The plugin uses `flutter_pty` which handles PTY operations through Dart FFI
- Windows Pseudo Console (ConPTY) API is used for terminal emulation
- ConPTY requires Windows 10 version 1809 or later
- No additional build configuration is needed
