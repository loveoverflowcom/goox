# goox_terminal

A simple terminal wrapper for Flutter using `xterm` and `flutter_pty`.

## Features

- Simple terminal widget wrapper
- Multi-terminal panel with tab management
- Cross-platform support (Linux, macOS, Windows)
- Copy/paste support with right-click
- Automatic shell detection
- Minimal dependencies

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  goox_terminal:
    path: packages/goox_terminal
```

## Usage

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:goox_terminal/goox_terminal.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: GooxTerminal(
          onTerminalReady: (controller) {
            print('Terminal ready!');
          },
        ),
      ),
    );
  }
}
```

### Custom Configuration

```dart
GooxTerminal(
  maxLines: 10000,
  autofocus: true,
  backgroundOpacity: 0.7,
  backgroundColor: Colors.black,
  onTerminalReady: (controller) {
    // Terminal is ready
    controller.write('Welcome to Goox Terminal!\n');
  },
)
```

### Multi-terminal Panel

```dart
GooxTerminalPanel(
  maxLines: 10000,
  enableDebug: false,
)
```

The panel keeps each terminal session alive in its own tab, and the `+`
button opens a new session while the `x` button closes the current one.

### Using Controller

```dart
class MyTerminal extends StatefulWidget {
  @override
  State<MyTerminal> createState() => _MyTerminalState();
}

class _MyTerminalState extends State<MyTerminal> {
  GooxTerminalController? _controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            _controller?.write('echo "Hello World"\n');
          },
          child: Text('Run Command'),
        ),
        Expanded(
          child: GooxTerminal(
            onTerminalReady: (controller) {
              _controller = controller;
            },
          ),
        ),
      ],
    );
  }
}
```

## Features

- Right-click to copy selected text or paste from clipboard
- Automatic shell detection (bash, zsh, cmd.exe)
- Login shell is disabled by default to avoid shell startup failures
- Terminal resize support
- Process exit handling

## Dependencies

- [xterm](https://pub.dev/packages/xterm) - Terminal emulator
- [flutter_pty](https://pub.dev/packages/flutter_pty) - PTY backend

## License

MIT
