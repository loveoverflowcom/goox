# Goox Terminal Migration Guide

## Tổng quan

Package `goox_terminal` đã được refactor hoàn toàn từ một hệ thống quản lý session phức tạp thành một wrapper đơn giản cho `xterm` và `flutter_pty`.

## Thay đổi chính

### Trước (v0.1.0)

```dart
// API phức tạp với session management
import 'package:goox_terminal/goox_terminal.dart';

BlocBuilder<ThemeBloc, ThemeState>(
  builder: (context, themeState) {
    final terminalTheme = themeState.resolvedBrightness == Brightness.dark
        ? TerminalTheme.dark()
        : TerminalTheme.light();
    
    return TerminalPanel(
      initialHeight: 300,
      theme: terminalTheme,
    );
  },
)
```

### Sau (v0.2.0)

```dart
// API đơn giản, trực tiếp
import 'package:goox_terminal/goox_terminal.dart';

SizedBox(
  height: 300,
  child: GooxTerminal(
    autofocus: false,
    backgroundOpacity: 0.9,
    onTerminalReady: (controller) {
      // Terminal is ready
    },
  ),
)
```

## API Changes

### Removed Classes

- `TerminalPanel` → Thay bằng `GooxTerminal`
- `TerminalSessionManager` → Không còn cần
- `TerminalTheme` → Không còn cần (xterm tự quản lý theme)
- `TerminalStatus` → Không còn cần
- `ShellConfig` → Tự động detect shell
- `PtySize` → Tự động quản lý
- `ShellDetector` → Tự động detect shell

### New Classes

- `GooxTerminal` - Widget chính để hiển thị terminal
- `GooxTerminalController` - Controller để điều khiển terminal

## Migration Steps

### 1. Cập nhật import

```dart
// Trước
import 'package:goox_terminal/goox_terminal.dart';
// Vẫn giữ nguyên

// Nhưng các class đã thay đổi
```

### 2. Thay thế TerminalPanel

```dart
// Trước
TerminalPanel(
  initialHeight: 300,
  theme: TerminalTheme.dark(),
)

// Sau
SizedBox(
  height: 300,
  child: GooxTerminal(
    autofocus: false,
    backgroundOpacity: 0.9,
  ),
)
```

### 3. Sử dụng Controller (nếu cần)

```dart
// Trước
final sessionManager = TerminalSessionManager.instance;
final controller = await sessionManager.createSession();
controller.write('echo "Hello"\n');

// Sau
GooxTerminalController? _controller;

GooxTerminal(
  onTerminalReady: (controller) {
    _controller = controller;
    _controller?.write('echo "Hello"\n');
  },
)
```

## Tính năng mới

1. **Đơn giản hơn**: Không cần quản lý session phức tạp
2. **Tự động**: Shell detection tự động
3. **Copy/Paste**: Right-click để copy/paste
4. **Cross-platform**: Hỗ trợ Linux, macOS, Windows

## Breaking Changes

- Không còn hỗ trợ multiple terminal tabs (có thể thêm lại nếu cần)
- Không còn custom theme (xterm tự quản lý)
- Không còn session lifecycle management
- Không còn shell configuration (tự động detect)

## Files Changed

### Package goox_terminal

- ✅ Refactored: `lib/goox_terminal.dart`
- ✅ Created: `lib/src/goox_terminal_widget.dart`
- ✅ Created: `lib/src/goox_terminal_controller.dart`
- ✅ Updated: `pubspec.yaml` (removed unnecessary dependencies)
- ✅ Updated: `README.md`
- ✅ Created: `CHANGELOG.md`
- ✅ Created: `INTEGRATION_GUIDE.md`
- ✅ Created: `example/main.dart`
- ❌ Removed: All old implementation files

### Main Project

- ✅ Updated: `lib/features/editor_layout/presentation/widgets/editor_layout_views.dart`
- ✅ Updated: `test/terminal_integration_test.dart`

## Testing

Chạy test để verify:

```bash
# Test package
cd packages/goox_terminal
flutter test

# Test main project
cd ../..
flutter test test/terminal_integration_test.dart
```

## Rollback (nếu cần)

Nếu cần rollback về version cũ:

```bash
git checkout HEAD~1 packages/goox_terminal
flutter pub get
```

## Next Steps

1. Test terminal trong app thực tế
2. Thêm tính năng nếu cần (multiple tabs, custom theme, etc.)
3. Cập nhật documentation nếu cần

## Support

Nếu có vấn đề, xem:
- `packages/goox_terminal/README.md`
- `packages/goox_terminal/INTEGRATION_GUIDE.md`
- `packages/goox_terminal/example/main.dart`
