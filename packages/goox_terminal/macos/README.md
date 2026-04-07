# macOS Platform Implementation

This folder contains the macOS-specific implementation of the `goox_terminal` plugin.

## Structure

- `goox_terminal.podspec` - CocoaPods specification file
- `Classes/GooxTerminalPlugin.swift` - Swift plugin implementation
- `.gitignore` - Git ignore rules for macOS build artifacts

## Building

The plugin uses Cargokit to build the Rust library. The build process is integrated into the CocoaPods build via a script phase in the podspec.

### Requirements

- macOS 10.14 or later
- Xcode 12.0 or later
- Rust toolchain (for building the native library)

### Build Process

1. Run `pod install` in your app's `macos/` directory
2. The Cargokit script will automatically build the Rust library
3. The compiled library will be linked with the Flutter app

## Integration with Rust

The Rust FFI library is built using Cargokit, which handles:
- Cross-compilation for different architectures (x86_64, arm64)
- Universal binary creation
- Integration with Xcode build system

The Rust code is located in `../rust/` directory.
