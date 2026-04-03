# Goox UI

UI components and theme for Goox editor.

## Features

- **Colors**: VSCode-inspired dark theme colors
- **Spacing**: Consistent spacing and sizing constants
- **Theme**: Pre-configured dark theme
- **Typography**: Text styles for editor components

## Usage

```dart
import 'package:goox_ui/goox_ui.dart';

// Use colors
Container(
  color: AppColors.editorBackground,
  child: Text(
    'Hello',
    style: AppTextStyles.editor,
  ),
);

// Use theme
MaterialApp(
  theme: AppTheme.dark,
  home: MyHomePage(),
);

// Use spacing
Container(
  width: AppSpacing.sidebarDefaultWidth,
  height: AppSpacing.tabHeight,
);
```
