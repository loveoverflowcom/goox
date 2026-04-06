import 'package:flutter/material.dart';
import 'package:goox/features/theme/data/models/theme_mode.dart';
import 'package:goox/features/theme/data/repositories/theme_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of ThemeRepository using SharedPreferences
class ThemeRepositoryImpl implements ThemeRepository {
  /// Storage key for theme mode
  static const String _themeKey = 'theme_mode';

  @override
  Future<AppThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_themeKey);

      if (savedKey == null) {
        return AppThemeMode.dark; // Default to dark theme
      }

      return AppThemeModeExtension.fromPersistenceKey(savedKey);
    } on Exception catch (e) {
      // Log error and return default
      debugPrint('Error loading theme mode: $e');
      return AppThemeMode.dark;
    }
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.persistenceKey);
    } on Exception catch (e) {
      // Log error but don't throw
      debugPrint('Error saving theme mode: $e');
    }
  }

  @override
  Brightness getSystemBrightness() {
    try {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    } on Exception catch (e) {
      // Log error and return default
      debugPrint('Error getting system brightness: $e');
      return Brightness.dark;
    }
  }
}
