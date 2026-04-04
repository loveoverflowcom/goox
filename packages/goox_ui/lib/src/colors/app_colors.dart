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

  // Light theme colors
  /// Background color for the activity bar (light theme).
  static const Color lightActivityBarBackground = Color(0xFFEEEEEE);

  /// Background color for the sidebar (light theme).
  static const Color lightSidebarBackground = Color(0xFFF3F3F3);

  /// Background color for the editor area (light theme).
  static const Color lightEditorBackground = Color(0xFFFFFFFF);

  /// Background color for the tab bar (light theme).
  static const Color lightTabBarBackground = Color(0xFFF3F3F3);

  /// Background color for the status bar (light theme).
  static const Color lightStatusBarBackground = Color(0xFF007ACC);

  /// Primary text color (light theme).
  static const Color lightTextColor = Color(0xFF333333);

  /// Dimmed text color for less important text (light theme).
  static const Color lightTextColorDimmed = Color(0xFF6C6C6C);

  /// Background color for active tabs (light theme).
  static const Color lightActiveTabBackground = Color(0xFFFFFFFF);

  /// Background color for inactive tabs (light theme).
  static const Color lightInactiveTabBackground = Color(0xFFECECEC);

  /// Hover color for interactive elements (light theme).
  static const Color lightHoverColor = Color(0xFFE8E8E8);

  /// Border color for separators (light theme).
  static const Color lightBorderColor = Color(0xFFDDDDDD);

  /// Background color for selected items (light theme).
  static const Color lightSelectedItemColor = Color(0xFFE0E8F0);
}
