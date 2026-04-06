# Goox Terminal

A Flutter package that provides PTY (Pseudo-Terminal) support through Rust FFI, enabling cross-platform terminal functionality for desktop applications.

## Features

- ✅ **Cross-platform**: Works on macOS, Linux, and Windows
- ✅ **High Performance**: Low-latency I/O operations (< 10ms)
- ✅ **Type-safe API**: Dart-idiomatic API with proper null-safety
- ✅ **Async I/O**: Non-blocking operations with Streams
- ✅ **Multiple Sessions**: Support for concurrent PTY sessions
- ✅ **Terminal Control**: Resize, signals, and process management

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS    | ✅ Supported | macOS 10.13+ |
| Linux    | ✅ Supported | Kernel 3.10+ |
| Windows  | ✅ Supported | Windows 10+ (ConPTY) |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  goox_terminal: ^0.1.0
```

## Quick Start

```dart
import 'package:goox_terminal/goox_terminal.dart';

void main() async {
  // Create a PTY session
  final config = PtyConfig(
    shell: '/bin/bash',
    size: PtySize(rows: 24, cols: 80),
  );
  
  final sessionId = await PtyManager.instance.createSession(config);
  final session = PtyManager.instance.getSession(sessionId)!;
  
  // Listen to output
  session.outputStream.listen((data) {
    print(utf8.decode(data));
  });
  
  // Write input
  await session.write('echo "Hello, PTY!"\n');
  
  // Wait a bit for output
  await Future.delayed(Duration(seconds: 1));
  
  // Close session
  await session.close();
}
```

## Usage

### Creating a Session

```dart
final config = PtyConfig(
  shell: '/bin/bash',
  args: ['-l'],  // Login shell
  workingDirectory: '/home/user',
  environment: {'TERM': 'xterm-256color'},
  size: PtySize(rows: 24, cols: 80),
);

final sessionId = await PtyManager.instance.createSession(config);
```

### Reading Output

```dart
final session = PtyManager.instance.getSession(sessionId)!;

session.outputStream.listen(
  (data) {
    // Handle output data (Uint8List)
    final text = utf8.decode(data);
    print(text);
  },
  onError: (error) {
    print('Error: $error');
  },
  onDone: () {
    print('Session ended');
  },
);
```

### Writing Input

```dart
// Write string
await session.write('ls -la\n');

// Write binary data
await session.writeBytes(Uint8List.fromList([0x03])); // Ctrl+C
```

### Resizing Terminal

```dart
await session.resize(30, 100);  // 30 rows, 100 cols
```

### Sending Signals

```dart
// Send Ctrl+C
await session.sendSignal(PtySignal.sigint);

// Terminate process
await session.sendSignal(PtySignal.sigterm);
```

### Managing Sessions

```dart
// List all active sessions
final sessions = PtyManager.instance.listSessions();

// Check if session is running
final isRunning = PtyManager.instance.isSessionRunning(sessionId);

// Close a session
await PtyManager.instance.closeSession(sessionId);
```

## Architecture

```
Flutter Application
    ↓
Dart API Layer (goox_terminal)
    ↓
FFI Bridge (flutter_rust_bridge)
    ↓
Rust Core (pty_core)
    ↓
Platform PTY (portable-pty)
    ↓
OS PTY APIs
```

## Performance

- **I/O Latency**: < 10ms (p95)
- **Throughput**: > 10 MB/s
- **Memory**: < 10 MB per session
- **CPU**: < 5% when idle

## Requirements

### Development

- Flutter SDK >= 3.0.0
- Rust >= 1.70.0
- Platform-specific build tools:
  - macOS: Xcode Command Line Tools
  - Linux: build-essential
  - Windows: Visual Studio Build Tools

### Runtime

- macOS 10.13+
- Linux with kernel 3.10+
- Windows 10 1809+ (for ConPTY support)

## Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/goox_terminal.git
cd goox_terminal

# Build Rust library
cd rust/pty_core
cargo build --release

# Run tests
cd ../..
flutter test
```

## Examples

See the [example](example/) directory for a complete terminal emulator implementation.

## Troubleshooting

### Build Issues

**Problem**: Rust build fails
```bash
# Solution: Update Rust toolchain
rustup update stable
```

**Problem**: FFI bindings not generated
```bash
# Solution: Regenerate bindings
flutter_rust_bridge_codegen \
  --rust-input rust/pty_core/src/lib.rs \
  --dart-output lib/src/bridge_generated.dart
```

### Runtime Issues

**Problem**: Session creation fails on Windows
- Ensure Windows 10 version 1809 or later
- ConPTY requires Windows 10 build 17763+

**Problem**: Permission denied errors
- Check that the shell path is correct
- Verify execute permissions on the shell

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [portable-pty](https://github.com/wez/wezterm/tree/main/pty) - Cross-platform PTY implementation
- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge) - FFI bridge generator
- [tokio](https://tokio.rs/) - Async runtime for Rust

## Support

- 📖 [Documentation](https://pub.dev/documentation/goox_terminal/latest/)
- 🐛 [Issue Tracker](https://github.com/yourusername/goox_terminal/issues)
- 💬 [Discussions](https://github.com/yourusername/goox_terminal/discussions)
