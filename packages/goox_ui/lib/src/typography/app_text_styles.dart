import 'package:flutter/material.dart';
import 'package:goox_ui/src/colors/app_colors.dart';
import 'package:goox_ui/src/measurements/app_measurements.dart';
import 'package:goox_ui/src/typography/app_font_weight.dart';

/// Text styles for the app.
final class AppTextStyles {
  /// Private constructor to prevent instantiation.
  const AppTextStyles._();

  /// Editor text style.
  static const TextStyle editor = TextStyle(
    color: AppColors.textColor,
    fontSize: AppSpacing.fontSize,
    fontFamily: 'monospace',
    height: AppSpacing.lineHeight,
    fontWeight: AppFontWeight.regular,
  );

  /// Line number text style.
  static const TextStyle lineNumber = TextStyle(
    color: AppColors.textColorDimmed,
    fontSize: AppSpacing.fontSize,
    fontFamily: 'monospace',
    height: AppSpacing.lineHeight,
    fontWeight: AppFontWeight.regular,
  );

  /// Tab text style.
  static TextStyle tab({bool isActive = false}) {
    return TextStyle(
      color: AppColors.textColor,
      fontSize: 13,
      fontWeight: isActive ? AppFontWeight.medium : AppFontWeight.regular,
    );
  }

  /// File explorer text style.
  static const TextStyle fileExplorer = TextStyle(
    color: AppColors.textColor,
    fontSize: 13,
    fontWeight: AppFontWeight.regular,
  );

  /// Status bar text style.
  static const TextStyle statusBar = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: AppFontWeight.regular,
  );

  /// Section header text style.
  static const TextStyle sectionHeader = TextStyle(
    color: AppColors.textColor,
    fontSize: 11,
    fontWeight: AppFontWeight.bold,
  );
}
