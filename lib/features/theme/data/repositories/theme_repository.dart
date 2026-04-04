import 'package:flutter/material.dart';
import 'package:goox/features/theme/data/models/theme_mode.dart';

/// Abstract repository for theme persistence and system theme queries
abstract class ThemeRepository {
  /// Load the saved theme mode preference
  Future<AppThemeMode> loadThemeMode();

  /// Save the theme mode preference
  Future<void> saveThemeMode(AppThemeMode mode);

  /// Get the current system theme brightness
  Brightness getSystemBrightness();
}
