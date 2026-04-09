# Goox Terminal Troubleshooting

## Exit Code 255

### Nguyên nhân

Exit code 255 thường xảy ra khi:
1. Shell không tồn tại tại đường dẫn được chỉ định
2. Shell không có quyền execute
3. Shell arguments không hợp lệ
4. Environment variables thiếu hoặc không đúng

### Giải pháp

#### 1. Enable Debug Mode

Thêm `enableDebug: true` vào widget:

```dart
GooxTerminal(
  enableDebug: true, // Bật debug mode
  onTerminalReady: (controller) {
    // Terminal ready
  },
)
```

Debug mode sẽ in ra:
- Platform information
- Shell path được sử dụng
- Available shells trên hệ thống
- Chi tiết lỗi nếu có

#### 2. Kiểm tra Shell Path

Chạy trong terminal của hệ thống:

```bash
# Kiểm tra shell hiện tại
echo $SHELL

# Kiểm tra shell có tồn tại không
ls -la $SHELL

# Kiểm tra quyền execute
ls -l $SHELL
```

#### 3. Thử các Shell khác

Nếu shell mặc định không hoạt động, thử:

**macOS/Linux:**
```bash
# Thử bash
/bin/bash -l

# Thử zsh
/bin/zsh -l

# Thử sh
/bin/sh -l
```

**Sửa trong code** (tạm thời để test):

```dart
// Trong goox_terminal_controller.dart
_ShellInfo _getShellInfo() {
  if (Platform.isMacOS || Platform.isLinux) {
    return _ShellInfo(
      path: '/bin/bash', // Thử shell cụ thể
      arguments: [], // Thử không dùng -l
      environment: {
        'TERM': 'xterm-256color',
        ...Platform.environment,
      },
    );
  }
  // ...
}
```

#### 4. Kiểm tra Permissions

```bash
# Kiểm tra quyền của shell
ls -l /bin/bash
# Nên thấy: -rwxr-xr-x (có x = executable)

# Nếu không có quyền execute
sudo chmod +x /bin/bash
```

#### 5. Kiểm tra Environment Variables

```dart
// In ra environment variables
print('SHELL: ${Platform.environment['SHELL']}');
print('HOME: ${Platform.environment['HOME']}');
print('PATH: ${Platform.environment['PATH']}');
print('TERM: ${Platform.environment['TERM']}');
```

#### 6. Thử không dùng Login Shell

Argument `-l` (login shell) có thể gây vấn đề. Thử bỏ:

```dart
_ShellInfo(
  path: shellPath,
  arguments: [], // Bỏ -l
  environment: {...},
)
```

#### 7. Kiểm tra flutter_pty

Đảm bảo `flutter_pty` hoạt động:

```bash
# Trong terminal
cd packages/goox_terminal
flutter pub get
flutter test
```

## Các lỗi khác

### "Shell not found"

Shell không tồn tại tại path được chỉ định.

**Giải pháp:**
```bash
# Tìm shell có sẵn
which bash
which zsh
which sh

# Cập nhật path trong code
```

### "Permission denied"

Không có quyền execute shell.

**Giải pháp:**
```bash
sudo chmod +x /path/to/shell
```

### Terminal không hiển thị gì

PTY có thể chưa khởi động.

**Giải pháp:**
1. Kiểm tra console logs
2. Enable debug mode
3. Kiểm tra `onTerminalReady` callback có được gọi không

### Terminal bị freeze

Process có thể đang chờ input.

**Giải pháp:**
1. Thử gõ Enter
2. Thử Ctrl+C
3. Restart terminal

## Debug Checklist

- [ ] Enable debug mode (`enableDebug: true`)
- [ ] Kiểm tra console logs
- [ ] Kiểm tra shell path (`echo $SHELL`)
- [ ] Kiểm tra shell permissions (`ls -l $SHELL`)
- [ ] Thử shell khác (`/bin/bash`, `/bin/zsh`, `/bin/sh`)
- [ ] Thử bỏ login shell argument (bỏ `-l`)
- [ ] Kiểm tra environment variables
- [ ] Kiểm tra flutter_pty version

## Liên hệ

Nếu vẫn gặp vấn đề, tạo issue với:
1. Platform (macOS, Linux, Windows)
2. Shell đang dùng (`echo $SHELL`)
3. Debug output (với `enableDebug: true`)
4. Console logs
5. Steps to reproduce
