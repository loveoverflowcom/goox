# Linux Platform Implementation

This folder contains the Linux-specific implementation of the `goox_terminal` plugin.

## Structure

- `CMakeLists.txt` - CMake build configuration
- `goox_terminal_plugin.cc` - C++ plugin implementation
- `include/goox_terminal/goox_terminal_plugin.h` - Plugin header file
- `.gitignore` - Git ignore rules for Linux build artifacts

## Overview

The goox_terminal package uses pure Dart implementation with `flutter_pty` for PTY management. No native Rust code compilation is required.

## Building

The plugin integrates seamlessly with Flutter's standard build process.

### Requirements

- Linux (Ubuntu 20.04+ or equivalent)
- CMake 3.10 or later
- GCC/Clang compiler
- GTK 3.0 development libraries

### Dependencies

Install required dependencies on Ubuntu/Debian:

```bash
sudo apt-get install libgtk-3-dev
```

### Build Process

Simply run:

```bash
flutter build linux
```

The plugin will be automatically included in your Flutter app build.

## Notes

- The plugin uses `flutter_pty` which handles PTY operations through Dart FFI
- No additional build configuration is needed
- The plugin is compatible with all Linux distributions that support Flutter
