import 'package:flutter/material.dart';
import 'package:goox_ui/src/colors/app_colors.dart';

/// App theme for Goox editor.
final class AppTheme {
  /// Private constructor to prevent instantiation.
  const AppTheme._();

  /// Dark theme matching VSCode.
  static ThemeData get dark {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.editorBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.statusBarBackground,
        surface: AppColors.editorBackground,
        error: AppColors.errorColor,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: AppColors.textColor,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
