# Native Splash Screen Implementation

## Overview
Đã triển khai native splash screen cho các nền tảng desktop (macOS, Windows, Linux) với cả native background color và Flutter splash screen widget.

## Lý do
Package `flutter_native_splash` chưa hỗ trợ đầy đủ cho desktop platforms, nên chúng ta phải implement thủ công ở native code.

## Thay đổi

### 1. pubspec.yaml
- Giữ lại cấu hình `flutter_native_splash` cơ bản (cho tương lai)
- Thêm comment giải thích rằng desktop platforms được implement thủ công

### 2. macOS (macos/Runner/MainFlutterWindow.swift)
```swift
// Set background color to match splash screen (#1E1E1E)
// Using CGFloat for proper color conversion
self.backgroundColor = NSColor(
  red: CGFloat(0x1E) / 255.0,
  green: CGFloat(0x1E) / 255.0,
  blue: CGFloat(0x1E) / 255.0,
  alpha: 1.0
)
```
- Đặt màu nền của window chính thành #1E1E1E (AppColors.editorBackground)
- Sử dụng CGFloat để đảm bảo chuyển đổi màu chính xác

### 3. Windows (windows/runner/win32_window.cpp)
```cpp
// Set background color to match splash screen (#1E1E1E)
window_class.hbrBackground = CreateSolidBrush(RGB(0x1E, 0x1E, 0x1E));
```
- Tạo solid brush với màu #1E1E1E cho window class
- Màu này sẽ hiển thị khi window được tạo, trước khi Flutter render

### 4. Linux (linux/runner/my_application.cc)
```cpp
// Set background color to match splash screen (#1E1E1E)
gdk_rgba_parse(&background_color, "#1E1E1E");
```
- Đặt màu nền của FlView thành #1E1E1E

### 5. Flutter Splash Screen (lib/main.dart)
```dart
final class _AppInitializer extends StatefulWidget {
  // Shows SplashScreen widget for 1.5 seconds
  // Then navigates to EditorLayoutView
}
```
- Thêm `_AppInitializer` widget để hiển thị splash screen
- Delay 1.5 giây để người dùng thấy splash screen
- Sau đó navigate sang EditorLayoutView

### 6. Splash Screen Widget (lib/features/splash/splash_screen.dart)
- Hiển thị logo, tên app, tagline
- CircularProgressIndicator để chỉ báo đang loading
- Màu nền #1E1E1E khớp với native background

## Kết quả
- Khi app khởi động, người dùng thấy màu nền tối (#1E1E1E) ngay lập tức từ native
- Flutter splash screen widget hiển thị với logo và loading indicator
- Sau 1.5 giây, app navigate sang editor layout
- Tạo trải nghiệm mượt mà, không có flash màu trắng hoặc đen khi khởi động

## Testing
Để test splash screen:
1. Build app cho platform tương ứng:
   - macOS: `flutter build macos`
   - Windows: `flutter build windows`
   - Linux: `flutter build linux`
2. Chạy app từ build output
3. Quan sát:
   - Native background color (#1E1E1E) hiển thị ngay lập tức
   - Flutter splash screen với logo và loading indicator
   - Sau 1.5 giây chuyển sang editor

## Notes
- Màu #1E1E1E được định nghĩa trong `packages/goox_ui/lib/src/colors/app_colors.dart` là `AppColors.editorBackground`
- Nếu thay đổi màu splash screen trong Flutter, cần update màu ở cả 3 native platforms
- Có thể điều chỉnh thời gian delay trong `_AppInitializer._initialize()` (hiện tại là 1500ms)
- Logo splash screen nằm ở `launch_assets/splash_logo.png`

