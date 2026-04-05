# Bugfix Requirements Document

## Introduction

Các widget trong ứng dụng Goox editor hiện đang sử dụng `AppColors` trực tiếp (ví dụ: `AppColors.textColor`, `AppColors.editorBackground`) thay vì truy cập colors thông qua `Theme.of(context)`. Điều này vi phạm best practice của Flutter về theme management và làm cho việc thay đổi theme động (dark/light mode) trở nên khó khăn hoặc không hoạt động đúng cách.

Bug này ảnh hưởng đến 6 widget files với nhiều instances sử dụng AppColors trực tiếp:
- `lib/features/terminal/presentation/widgets/terminal_panel_widget.dart`
- `lib/features/status_bar/presentation/widgets/status_bar_widget.dart`
- `lib/features/theme/presentation/widgets/theme_selector_widget.dart`
- `lib/features/editor_layout/presentation/widgets/editor_layout_views.dart`
- `lib/features/file_explorer/presentation/widgets/file_explorer_widget.dart`
- `lib/features/editor_content/presentation/widgets/text_editor_widget.dart`
- `packages/goox_ui/lib/src/widgets/goox_navigation_rail.dart`

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN a widget needs to display a color (e.g., background, text, border) THEN the system uses `AppColors.xxx` directly (e.g., `AppColors.textColor`, `AppColors.editorBackground`)

1.2 WHEN the user switches between dark and light theme THEN the widgets do not automatically update their colors because they reference static color constants instead of theme-aware colors

1.3 WHEN a widget is built with a color property THEN the color value is hardcoded from `AppColors` class instead of being retrieved from the current theme context

1.4 WHEN the app initializes with a theme THEN widgets ignore the theme's ColorScheme and use AppColors static values directly

### Expected Behavior (Correct)

2.1 WHEN a widget needs to display a color THEN the system SHALL retrieve the color from `Theme.of(context).colorScheme` or a custom theme extension

2.2 WHEN the user switches between dark and light theme THEN the widgets SHALL automatically update their colors by reading from the current theme context

2.3 WHEN a widget is built with a color property THEN the color value SHALL be retrieved dynamically from `Theme.of(context)` to support theme changes

2.4 WHEN the app initializes with a theme THEN widgets SHALL respect the theme's ColorScheme and custom extensions, allowing proper theme management

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the app is running in dark mode THEN the system SHALL CONTINUE TO display the same dark color values as before (visual appearance unchanged)

3.2 WHEN the app is running in light mode THEN the system SHALL CONTINUE TO display the same light color values as before (visual appearance unchanged)

3.3 WHEN a widget renders its UI THEN the system SHALL CONTINUE TO maintain the same visual layout, spacing, and structure (only color access method changes)

3.4 WHEN the AppColors class is used in non-widget contexts (e.g., theme definition files) THEN the system SHALL CONTINUE TO allow direct AppColors usage where appropriate
