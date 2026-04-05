import 'package:flutter/material.dart';
import 'package:goox_ui/src/colors/app_colors.dart';

/// Theme extension for editor-specific colors.
///
/// This extension provides access to editor-specific colors through the theme system,
/// allowing widgets to retrieve colors via Theme.of(context).extension<EditorThemeExtension>()
/// instead of directly accessing AppColors static constants.
final class EditorThemeExtension extends ThemeExtension<EditorThemeExtension> {
  /// Background color for the activity bar.
  final Color activityBarBackground;

  /// Background color for the sidebar.
  final Color sidebarBackground;

  /// Background color for the editor area.
  final Color editorBackground;

  /// Background color for the tab bar.
  final Color tabBarBackground;

  /// Background color for the status bar.
  final Color statusBarBackground;

  /// Primary text color.
  final Color textColor;

  /// Dimmed text color for less important text.
  final Color textColorDimmed;

  /// Hover color for interactive elements.
  final Color hoverColor;

  /// Border color for separators.
  final Color borderColor;

  /// Background color for selected items.
  final Color selectedItemColor;

  /// Color for modified file indicator.
  final Color modifiedIndicator;

  /// Creates an editor theme extension with the specified colors.
  const EditorThemeExtension({
    required this.activityBarBackground,
    required this.sidebarBackground,
    required this.editorBackground,
    required this.tabBarBackground,
    required this.statusBarBackground,
    required this.textColor,
    required this.textColorDimmed,
    required this.hoverColor,
    required this.borderColor,
    required this.selectedItemColor,
    required this.modifiedIndicator,
  });

  /// Creates a dark theme extension mapping AppColors dark theme values.
  factory EditorThemeExtension.dark() {
    return const EditorThemeExtension(
      activityBarBackground: AppColors.activityBarBackground,
      sidebarBackground: AppColors.sidebarBackground,
      editorBackground: AppColors.editorBackground,
      tabBarBackground: AppColors.tabBarBackground,
      statusBarBackground: AppColors.statusBarBackground,
      textColor: AppColors.textColor,
      textColorDimmed: AppColors.textColorDimmed,
      hoverColor: AppColors.hoverColor,
      borderColor: AppColors.borderColor,
      selectedItemColor: AppColors.selectedItemColor,
      modifiedIndicator: AppColors.modifiedIndicator,
    );
  }

  /// Creates a light theme extension mapping AppColors light theme values.
  factory EditorThemeExtension.light() {
    return const EditorThemeExtension(
      activityBarBackground: AppColors.lightActivityBarBackground,
      sidebarBackground: AppColors.lightSidebarBackground,
      editorBackground: AppColors.lightEditorBackground,
      tabBarBackground: AppColors.lightTabBarBackground,
      statusBarBackground: AppColors.lightStatusBarBackground,
      textColor: AppColors.lightTextColor,
      textColorDimmed: AppColors.lightTextColorDimmed,
      hoverColor: AppColors.lightHoverColor,
      borderColor: AppColors.lightBorderColor,
      selectedItemColor: AppColors.lightSelectedItemColor,
      modifiedIndicator: AppColors.modifiedIndicator,
    );
  }

  @override
  ThemeExtension<EditorThemeExtension> copyWith({
    Color? activityBarBackground,
    Color? sidebarBackground,
    Color? editorBackground,
    Color? tabBarBackground,
    Color? statusBarBackground,
    Color? textColor,
    Color? textColorDimmed,
    Color? hoverColor,
    Color? borderColor,
    Color? selectedItemColor,
    Color? modifiedIndicator,
  }) {
    return EditorThemeExtension(
      activityBarBackground: activityBarBackground ?? this.activityBarBackground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      editorBackground: editorBackground ?? this.editorBackground,
      tabBarBackground: tabBarBackground ?? this.tabBarBackground,
      statusBarBackground: statusBarBackground ?? this.statusBarBackground,
      textColor: textColor ?? this.textColor,
      textColorDimmed: textColorDimmed ?? this.textColorDimmed,
      hoverColor: hoverColor ?? this.hoverColor,
      borderColor: borderColor ?? this.borderColor,
      selectedItemColor: selectedItemColor ?? this.selectedItemColor,
      modifiedIndicator: modifiedIndicator ?? this.modifiedIndicator,
    );
  }

  @override
  ThemeExtension<EditorThemeExtension> lerp(
    covariant ThemeExtension<EditorThemeExtension>? other,
    double t,
  ) {
    if (other is! EditorThemeExtension) {
      return this;
    }

    return EditorThemeExtension(
      activityBarBackground: Color.lerp(activityBarBackground, other.activityBarBackground, t)!,
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      editorBackground: Color.lerp(editorBackground, other.editorBackground, t)!,
      tabBarBackground: Color.lerp(tabBarBackground, other.tabBarBackground, t)!,
      statusBarBackground: Color.lerp(statusBarBackground, other.statusBarBackground, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      textColorDimmed: Color.lerp(textColorDimmed, other.textColorDimmed, t)!,
      hoverColor: Color.lerp(hoverColor, other.hoverColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      selectedItemColor: Color.lerp(selectedItemColor, other.selectedItemColor, t)!,
      modifiedIndicator: Color.lerp(modifiedIndicator, other.modifiedIndicator, t)!,
    );
  }
}
