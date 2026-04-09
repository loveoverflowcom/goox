# Hướng dẫn tích hợp Goox Terminal vào project chính

## 1. Thêm dependency vào project chính

Trong file `pubspec.yaml` của project `goox`, thêm:

```yaml
dependencies:
  goox_terminal:
    path: packages/goox_terminal
```

Sau đó chạy:
```bash
flutter pub get
```

## 2. Import package

```dart
import 'package:goox_terminal/goox_terminal.dart';
```

## 3. Sử dụng trong UI

### Cách 1: Sử dụng đơn giản

```dart
class MyEditorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: EditorArea(), // Editor của bạn
        ),
        Expanded(
          flex: 3,
          child: GooxTerminal(
            onTerminalReady: (controller) {
              print('Terminal sẵn sàng!');
            },
          ),
        ),
      ],
    );
  }
}
```

### Cách 2: Với controller để điều khiển

```dart
class MyEditorScreen extends StatefulWidget {
  @override
  State<MyEditorScreen> createState() => _MyEditorScreenState();
}

class _MyEditorScreenState extends State<MyEditorScreen> {
  GooxTerminalController? _terminalController;

  void _runCommand(String command) {
    _terminalController?.write('$command\n');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar với nút chạy lệnh
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _runCommand('flutter run'),
              child: Text('Run'),
            ),
            ElevatedButton(
              onPressed: () => _runCommand('flutter build'),
              child: Text('Build'),
            ),
          ],
        ),
        
        // Editor
        Expanded(
          flex: 7,
          child: EditorArea(),
        ),
        
        // Terminal
        Expanded(
          flex: 3,
          child: GooxTerminal(
            maxLines: 10000,
            autofocus: false,
            backgroundOpacity: 0.9,
            onTerminalReady: (controller) {
              setState(() {
                _terminalController = controller;
              });
            },
          ),
        ),
      ],
    );
  }
}
```

### Cách 3: Terminal có thể ẩn/hiện

```dart
class MyEditorScreen extends StatefulWidget {
  @override
  State<MyEditorScreen> createState() => _MyEditorScreenState();
}

class _MyEditorScreenState extends State<MyEditorScreen> {
  bool _showTerminal = true;
  GooxTerminalController? _terminalController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Row(
          children: [
            IconButton(
              icon: Icon(_showTerminal ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showTerminal = !_showTerminal;
                });
              },
              tooltip: 'Toggle Terminal',
            ),
          ],
        ),
        
        // Editor
        Expanded(
          child: EditorArea(),
        ),
        
        // Terminal (có thể ẩn/hiện)
        if (_showTerminal)
          SizedBox(
            height: 300,
            child: GooxTerminal(
              onTerminalReady: (controller) {
                _terminalController = controller;
              },
            ),
          ),
      ],
    );
  }
}
```

## 4. Tính năng

- **Copy/Paste**: Click phải để copy text đã chọn hoặc paste từ clipboard
- **Auto shell detection**: Tự động phát hiện shell (bash, zsh, cmd.exe)
- **Resize**: Terminal tự động resize khi thay đổi kích thước
- **Process exit**: Hiển thị thông báo khi process kết thúc

## 5. API Reference

### GooxTerminal Widget

```dart
GooxTerminal({
  int maxLines = 10000,           // Số dòng tối đa trong buffer
  bool autofocus = true,           // Tự động focus vào terminal
  double backgroundOpacity = 0.7,  // Độ trong suốt background
  Color backgroundColor = Colors.transparent,
  void Function(GooxTerminalController)? onTerminalReady,
})
```

### GooxTerminalController

```dart
// Viết text vào terminal
controller.write('Hello World\n');

// Paste text
controller.paste('some text');

// Lấy text đã chọn
String? selectedText = controller.getSelectedText();

// Xóa selection
controller.clearSelection();

// Dispose (tự động gọi khi widget dispose)
controller.dispose();
```

## 6. Lưu ý

- Terminal sẽ tự động khởi động khi widget được mount
- Nhớ dispose controller khi không dùng nữa (widget tự động làm điều này)
- Hỗ trợ đầy đủ ANSI colors và escape sequences
- Cross-platform: Linux, macOS, Windows
