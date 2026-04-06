import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:goox_ui/src/colors/app_colors.dart';
import 'package:goox_ui/src/theme/editor_theme_extension.dart';

/// App theme for Goox editor.
final class AppTheme {
  /// Private constructor to prevent instantiation.
  const AppTheme._();

  /// Brand color from logo (blue)
  static const Color _brandColor = Color(0xFF007ACC);

  /// Dark theme matching VSCode with color seed from logo.
  static ThemeData get dark {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _brandColor,
        brightness: Brightness.dark,
        surface: AppColors.editorBackground,
        error: AppColors.errorColor,
      ),
      scaffoldBackgroundColor: AppColors.editorBackground,
      extensions: [EditorThemeExtension.dark()],
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(baseTheme.textTheme),
    );
  }

  /// Light theme matching VSCode light theme with color seed from logo.
  static ThemeData get light {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _brandColor,
        surface: AppColors.lightEditorBackground,
        error: AppColors.errorColor,
      ),
      scaffoldBackgroundColor: AppColors.lightEditorBackground,
      extensions: [EditorThemeExtension.light()],
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(baseTheme.textTheme),
    );
  }
}
