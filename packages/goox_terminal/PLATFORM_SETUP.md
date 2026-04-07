# Platform Setup Guide

This document describes the platform-specific setup for the `goox_terminal` Flutter plugin.

## Overview

The `goox_terminal` plugin is a multi-platform Flutter plugin that provides terminal emulation with PTY (pseudo-terminal) support. It uses Rust for the core PTY implementation via FFI (Foreign Function Interface) and Cargokit for build integration.

## Supported Platforms

- ✅ **macOS** (10.14+)
- ✅ **Linux** (Ubuntu 20.04+ or equivalent)
- ✅ **Windows** (10 1809+)

## Platform Structure

```
goox_terminal/
├── macos/                      # macOS platform code
│   ├── Classes/
│   │   └── GooxTerminalPlugin.swift
│   ├── goox_terminal.podspec
│   └── README.md
├── linux/                      # Linux platform code
│   ├── include/
│   │   └── goox_terminal/
│   │       └── goox_terminal_plugin.h
│   ├── goox_terminal_plugin.cc
│   ├── CMakeLists.txt
│   └── README.md
├── windows/                    # Windows platform code
│   ├── include/
│   │   └── goox_terminal/
│   │       └── goox_terminal_plugin_c_api.h
│   ├── goox_terminal_plugin.cpp
│   ├── goox_terminal_plugin.h
│   ├── goox_terminal_plugin_c_api.cpp
│   ├── CMakeLists.txt
│   └── README.md
├── rust/                       # Rust FFI implementation
│   └── pty_core/
├── cargokit/                   # Build tool integration
└── lib/                        # Dart API
```

## Build System Integration

### macOS (CocoaPods)

The macOS platform uses CocoaPods for dependency management. The `goox_terminal.podspec` file includes a script phase that invokes Cargokit to build the Rust library:

```ruby
s.script_phase = {
  :name => 'Build Rust library',
  :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../rust goox_terminal',
  :execution_position => :before_compile,
}
```

**Setup:**
```bash
cd example/macos
pod install
```

### Linux (CMake)

The Linux platform uses CMake for build configuration. The `CMakeLists.txt` includes Cargokit integration:

```cmake
include(../cargokit/cmake/cargokit.cmake)
apply_cargokit(${PLUGIN_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/../rust goox_terminal)
```

**Setup:**
```bash
# Install dependencies
sudo apt-get install libgtk-3-dev

# Build
flutter build linux
```

### Windows (CMake + Visual Studio)

The Windows platform uses CMake with Visual Studio. The `CMakeLists.txt` includes Cargokit integration similar to Linux:

```cmake
include(../cargokit/cmake/cargokit.cmake)
apply_cargokit(${PLUGIN_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/../rust goox_terminal)
```

**Setup:**
```bash
# Build
flutter build windows
```

## Rust FFI Integration

The plugin uses `flutter_rust_bridge` for generating FFI bindings between Dart and Rust. The Rust code is located in the `rust/` directory.

### Building Rust Library

Cargokit automatically handles:
- Cross-compilation for target architectures
- Debug/Release build configurations
- Integration with platform build systems
- Proper linking with Flutter engine

### Requirements

All platforms require:
- Rust toolchain (install from https://rustup.rs/)
- Cargo (comes with Rust)

## Development Workflow

### 1. Modify Rust Code

Edit files in `rust/pty_core/src/`

### 2. Regenerate FFI Bindings (if needed)

```bash
flutter_rust_bridge_codegen generate
```

### 3. Build for Target Platform

**macOS:**
```bash
cd example/macos
pod install
open Runner.xcworkspace
# Build in Xcode
```

**Linux:**
```bash
flutter build linux
```

**Windows:**
```bash
flutter build windows
```

## Testing

### Unit Tests

```bash
# Dart tests
flutter test

# Rust tests
cd rust/pty_core
cargo test
```

### Integration Tests

```bash
cd example
flutter test integration_test/
```

## Troubleshooting

### macOS: "No podspec found"

**Solution:** Ensure `macos/goox_terminal.podspec` exists and run `pod install` in `example/macos/`

### Linux: "GTK not found"

**Solution:** Install GTK development libraries:
```bash
sudo apt-get install libgtk-3-dev
```

### Windows: "Rust library not found"

**Solution:** Ensure Rust toolchain is installed and in PATH:
```bash
rustc --version
cargo --version
```

### All Platforms: "Cargokit build failed"

**Solution:** 
1. Check Rust toolchain is installed
2. Verify `rust/` directory contains valid Cargo project
3. Check build logs for specific errors

## Platform-Specific Notes

### macOS
- Requires Xcode Command Line Tools
- Supports both Intel (x86_64) and Apple Silicon (arm64)
- Universal binaries are created automatically

### Linux
- Tested on Ubuntu 20.04+, Fedora 35+, Arch Linux
- Requires GTK 3.0 for Flutter integration
- Uses POSIX PTY APIs

### Windows
- Requires Windows 10 version 1809 or later for ConPTY support
- Supports both x64 and ARM64 architectures
- Uses Windows Pseudo Console API

## License

See [LICENSE](LICENSE) file for details.
