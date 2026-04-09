# Terminal Entitlements Configuration

## Overview

Để `goox_terminal` package hoạt động đúng trên các nền tảng khác nhau, cần cấu hình permissions/entitlements phù hợp.

## macOS

### Entitlements Required

Đã được cấu hình trong:
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

### Các quyền đã thêm:

```xml
<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<true/>
<key>com.apple.security.cs.disable-library-validation</key>
<true/>
```

### Giải thích:

1. **com.apple.security.cs.allow-unsigned-executable-memory**
   - Cho phép app chạy code động trong memory
   - Cần thiết cho PTY (Pseudo Terminal) operations
   - PTY cần allocate và execute code để emulate terminal behavior

2. **com.apple.security.cs.disable-library-validation**
   - Cho phép load libraries không được signed bởi cùng developer
   - Cần thiết vì flutter_pty có thể load system libraries
   - Shell executables (/bin/zsh, /bin/bash) cần access system libraries

3. **com.apple.security.files.user-selected.read-write** (đã có sẵn)
   - Cho phép đọc/ghi file trong user directory
   - Shell cần access filesystem để hoạt động

### Sandbox Status

- App sandbox vẫn được **enabled** (`com.apple.security.app-sandbox = true`)
- Chỉ thêm các quyền tối thiểu cần thiết cho terminal
- Đảm bảo security trong khi vẫn cho phép terminal hoạt động

### Nếu vẫn gặp vấn đề

Nếu terminal vẫn exit với code 255, có thể cần disable sandbox hoàn toàn (chỉ để development):

```xml
<key>com.apple.security.app-sandbox</key>
<false/>
```

**Lưu ý:** Disable sandbox sẽ khiến app không thể submit lên Mac App Store.

## Linux

### Configuration

Linux không có sandbox restrictions như macOS. Terminal sẽ hoạt động out-of-the-box.

### Requirements

- GTK 3.0+ (đã được cấu hình trong CMakeLists.txt)
- Standard Linux permissions (không cần config đặc biệt)

## Windows

### Configuration

Windows không có sandbox restrictions tương tự macOS. Terminal sẽ hoạt động với manifest hiện tại.

### Requirements

- Windows 10 hoặc mới hơn (đã được cấu hình trong manifest)
- Standard Windows permissions (không cần config đặc biệt)

## Testing

### Sau khi thay đổi entitlements:

```bash
# Clean build để đảm bảo entitlements được apply
flutter clean
flutter run
```

### Kiểm tra terminal hoạt động:

1. Mở terminal trong app
2. Chạy lệnh đơn giản: `echo "Hello"`
3. Kiểm tra shell prompt hiển thị đúng
4. Không thấy "exit code 255"

## Troubleshooting

### macOS: Exit code 255

**Nguyên nhân phổ biến:**

1. **Sandbox chặn việc spawn subprocess**
   - Giải pháp: Thêm entitlements (xem phần macOS ở trên)

2. **HOME environment variable bị redirect vào sandbox container**
   - Khi app chạy trong sandbox, macOS redirect HOME về:
     `/Users/username/Library/Containers/bundle.id/Data`
   - Shell (zsh/bash) không tìm thấy `.zshrc`/`.bashrc` và exit với code 255
   - Giải pháp: Package đã tự động fix HOME về `/Users/username`

**Cách verify:**

```bash
# Check Console.app để xem sandbox violation logs
# Hoặc enable debug mode trong terminal widget
GooxTerminal(
  enableDebug: true,
  // ...
)
```

**Giải pháp:**
1. Kiểm tra entitlements đã được apply (clean build)
2. Check Console.app để xem sandbox violation logs
3. Verify HOME environment được fix đúng (xem debug output)
4. Thử disable sandbox tạm thời để verify

### Linux: Permission denied

**Nguyên nhân:** Shell executable không có execute permission

**Giải pháp:**
```bash
chmod +x /bin/bash
# hoặc
chmod +x /bin/zsh
```

### Windows: cmd.exe not found

**Nguyên nhân:** PATH environment variable không đúng

**Giải pháp:**
- Đảm bảo `C:\Windows\System32` trong PATH
- Hoặc dùng full path: `C:\Windows\System32\cmd.exe`

## References

- [Apple Entitlements Documentation](https://developer.apple.com/documentation/bundleresources/entitlements)
- [flutter_pty Package](https://pub.dev/packages/flutter_pty)
- [xterm.dart Package](https://pub.dev/packages/xterm)
