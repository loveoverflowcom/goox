# Windows Platform Implementation

This folder contains the Windows-specific implementation of the `goox_terminal` plugin.

## Structure

- `CMakeLists.txt` - CMake build configuration
- `goox_terminal_plugin.cpp` - C++ plugin implementation
- `goox_terminal_plugin.h` - Plugin header file
- `goox_terminal_plugin_c_api.cpp` - C API wrapper
- `include/goox_terminal/goox_terminal_plugin_c_api.h` - C API header
- `.gitignore` - Git ignore rules for Windows build artifacts

## Building

The plugin uses Cargokit to build the Rust library. The build process is integrated into the CMake build.

### Requirements

- Windows 10 or later
- Visual Studio 2019 or later (with C++ desktop development workload)
- CMake 3.14 or later
- Rust toolchain (for building the native library)

### Build Process

1. Run `flutter build windows` in your app directory
2. The Cargokit CMake integration will automatically build the Rust library
3. The compiled library will be linked with the Flutter app

## Integration with Rust

The Rust FFI library is built using Cargokit, which handles:
- Cross-compilation for different architectures (x64, ARM64)
- Integration with Visual Studio build system
- Proper linking with the Flutter engine

The Rust code is located in `../rust/` directory.

## Notes

- The plugin uses Windows Pseudo Console (ConPTY) API for terminal emulation
- ConPTY requires Windows 10 version 1809 or later
- For older Windows versions, fallback mechanisms may be needed
