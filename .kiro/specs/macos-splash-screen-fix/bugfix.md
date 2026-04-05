# Bugfix Requirements Document

## Introduction

Khi khởi động ứng dụng Flutter trên macOS, người dùng thấy một màn hình đen (black screen) xuất hiện trong khoảng thời gian ngắn trước khi giao diện chính của ứng dụng được hiển thị. Mặc dù đã có code triển khai splash screen native (sử dụng `native_splash_screen_macos` plugin) và các splash screen assets đã được cấu hình trong `Assets.xcassets`, splash screen vẫn không hiển thị đúng cách, dẫn đến trải nghiệm người dùng không mượt mà khi khởi động ứng dụng.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the macOS app is launched THEN the system displays a black screen before showing the main UI

1.2 WHEN the app initializes during launch THEN the configured splash screen (with logo/loading indicator) does not appear despite having splash screen implementation code and assets

1.3 WHEN the native splash screen should be displayed THEN the system shows a black window instead of the configured splash image from Assets.xcassets

### Expected Behavior (Correct)

2.1 WHEN the macOS app is launched THEN the system SHALL display a splash screen with the app logo or loading indicator immediately

2.2 WHEN the app initializes during launch THEN the system SHALL show the configured splash screen image from `Assets.xcassets/splash_screen_*.imageset` based on the build configuration (debug/profile/release)

2.3 WHEN the native splash screen is triggered in `AppDelegate.swift` THEN the system SHALL render the splash window with the correct image, dimensions (500x300), and animation settings as configured in `SimpleSplashConfig`

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the app finishes initialization and is ready to show the main UI THEN the system SHALL CONTINUE TO transition from splash screen to the main Flutter window

3.2 WHEN the app is built in different configurations (Debug, Profile, Release) THEN the system SHALL CONTINUE TO use the appropriate splash screen image for each build mode

3.3 WHEN the main Flutter window is displayed THEN the system SHALL CONTINUE TO use the dark background color (#1E1E1E) as configured in `AppDelegate.applicationDidFinishLaunching`

3.4 WHEN the app terminates after the last window is closed THEN the system SHALL CONTINUE TO exit properly as configured in `applicationShouldTerminateAfterLastWindowClosed`
