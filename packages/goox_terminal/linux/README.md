# Linux Platform Implementation

This folder contains the Linux-specific implementation of the `goox_terminal` plugin.

## Structure

- `CMakeLists.txt` - CMake build configuration
- `goox_terminal_plugin.cc` - C++ plugin implementation
- `include/goox_terminal/goox_terminal_plugin.h` - Plugin header file
- `.gitignore` - Git ignore rules for Linux build artifacts

## Building

The plugin uses Cargokit to build the Rust library. The build process is integrated into the CMake build.

### Requirements

- Linux (Ubuntu 20.04+ or equivalent)
- CMake 3.10 or later
- GCC/Clang compiler
- GTK 3.0 development libraries
- Rust toolchain (for building the native library)

### Dependencies

Install required dependencies on Ubuntu/Debian:

```bash
sudo apt-get install libgtk-3-dev
```

### Build Process

1. Run `flutter build linux` in your app directory
2. The Cargokit CMake integration will automatically build the Rust library
3. The compiled library will be linked with the Flutter app

## Integration with Rust

The Rust FFI library is built using Cargokit, which handles:
- Cross-compilation for different architectures
- Integration with CMake build system
- Proper linking with the Flutter engine

The Rust code is located in `../rust/` directory.
