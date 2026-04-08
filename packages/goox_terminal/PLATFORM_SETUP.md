# Platform Setup Guide

This document describes the platform-specific setup for the `goox_terminal` Flutter plugin.

## Overview

The `goox_terminal` plugin is a multi-platform Flutter plugin that provides terminal emulation with PTY (pseudo-terminal) support. It uses pure Dart implementation with `xterm` for terminal emulation and `flutter_pty` for PTY backend.

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
└── lib/                        # Dart API
    ├── src/
    │   ├── controllers/        # Terminal controllers
    │   ├── models/             # Data models
    │   ├── services/           # Shell detection, etc.
    │   └── ui/                 # UI widgets
    └── goox_terminal.dart      # Public API
```

## Dependencies

The plugin uses the following Dart packages:

- **xterm** (^4.0.0) - Terminal emulator with full VT100/xterm support
- **flutter_pty** (^0.4.2) - PTY backend for spawning shell processes

No native code compilation or build tools are required!

## Build System Integration

### macOS

**Setup:**
```bash
flutter build macos
```

The plugin integrates seamlessly with Flutter's standard build process. No additional configuration needed.

### Linux

**Setup:**
```bash
# Install Flutter dependencies (if not already installed)
sudo apt-get install libgtk-3-dev

# Build
flutter build linux
```

### Windows

**Setup:**
```bash
flutter build windows
```

Requires Windows 10 version 1809 or later for ConPTY support.

## Development Workflow

### 1. Add Dependency

Add to your `pubspec.yaml`:

```yaml
dependencies:
  goox_terminal: ^0.1.0
```

### 2. Import and Use

```dart
import 'package:goox_terminal/goox_terminal.dart';

// Use TerminalPanel widget
TerminalPanel(
  initialHeight: 300,
  visible: true,
  theme: TerminalTheme.dark(),
)

// Or manage sessions manually
final sessionManager = TerminalSessionManager.instance;
final controller = await sessionManager.createSession(
  shellConfig: ShellConfig.bash(),
  initialSize: PtySize(rows: 24, cols: 80),
);
```

### 3. Build for Target Platform

**macOS:**
```bash
flutter build macos
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
flutter test
```

The package includes comprehensive unit tests for:
- Terminal controller lifecycle
- Session manager operations
- Shell configuration validation
- PTY size validation
- Terminal status transitions

### Integration Tests

```bash
cd example
flutter run -d linux  # or macos, windows
```

## Troubleshooting

### macOS: Build Issues

**Solution:** Ensure you have Xcode Command Line Tools installed:
```bash
xcode-select --install
```

### Linux: GTK not found

**Solution:** Install GTK development libraries:
```bash
sudo apt-get install libgtk-3-dev
```

### Windows: ConPTY not available

**Solution:** Ensure you're running Windows 10 version 1809 or later:
```bash
winver
```

### All Platforms: flutter_pty issues

**Solution:** 
1. Check Flutter version is 3.0.0 or later
2. Run `flutter pub get` to ensure dependencies are installed
3. Check `flutter_pty` documentation for platform-specific requirements

## Platform-Specific Notes

### macOS
- Requires macOS 10.14 or later
- Supports both Intel (x86_64) and Apple Silicon (arm64)
- Default shell is zsh (macOS 10.15+) or bash (older versions)

### Linux
- Tested on Ubuntu 20.04+, Fedora 35+, Arch Linux
- Requires GTK 3.0 for Flutter integration
- Uses POSIX PTY APIs via flutter_pty
- Default shell is typically bash or zsh

### Windows
- Requires Windows 10 version 1809 or later for ConPTY support
- Supports both x64 and ARM64 architectures
- Uses Windows Pseudo Console API via flutter_pty
- Default shell is PowerShell or cmd

## Architecture

The plugin uses a pure Dart architecture:

```
App
 └─> TerminalPanel (UI)
      ├─> TerminalSessionManager (State)
      │    └─> TerminalController (Session)
      │         ├─> xterm Terminal (Emulator)
      │         └─> flutter_pty Pty (Backend)
      │              └─> OS PTY APIs
      └─> TerminalView (Rendering)
           └─> xterm TerminalView
```

## License

See [LICENSE](LICENSE) file for details.
