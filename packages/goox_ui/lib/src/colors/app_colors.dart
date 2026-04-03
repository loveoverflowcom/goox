import 'package:flutter/material.dart';

/// Color constants for the Goox editor theme matching VSCode dark theme.
final class AppColors {
  /// Private constructor to prevent instantiation.
  const AppColors._();

  // Dark theme colors matching VSCode
  /// Background color for the activity bar.
  static const Color activityBarBackground = Color(0xFF333333);

  /// Background color for the sidebar.
  static const Color sidebarBackground = Color(0xFF252526);

  /// Background color for the editor area.
  static const Color editorBackground = Color(0xFF1E1E1E);

  /// Background color for the tab bar.
  static const Color tabBarBackground = Color(0xFF2D2D2D);

  /// Background color for the status bar.
  static const Color statusBarBackground = Color(0xFF007ACC);

  /// Accent color for highlights and selections.
  static const Color accentColor = Color(0xFF007ACC);

  /// Primary text color.
  static const Color textColor = Color(0xFFCCCCCC);

  /// Dimmed text color for less important text.
  static const Color textColorDimmed = Color(0xFF858585);

  /// Background color for active tabs.
  static const Color activeTabBackground = Color(0xFF1E1E1E);

  /// Background color for inactive tabs.
  static const Color inactiveTabBackground = Color(0xFF2D2D2D);

  /// Hover color for interactive elements.
  static const Color hoverColor = Color(0xFF2A2D2E);

  /// Border color for separators.
  static const Color borderColor = Color(0xFF3E3E42);

  /// Background color for selected items.
  static const Color selectedItemColor = Color(0xFF094771);

  /// Color for modified file indicator.
  static const Color modifiedIndicator = Colors.white;

  /// Color for error messages.
  static const Color errorColor = Color(0xFFF48771);

  /// Color for warning messages.
  static const Color warningColor = Color(0xFFCCA700);
}
