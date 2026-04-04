/// Theme mode enum for Goox Editor
enum AppThemeMode {
  /// Dark theme mode
  dark,

  /// Light theme mode
  light,

  /// System theme mode (follows OS settings)
  system,
}

/// Extension methods for AppThemeMode
extension AppThemeModeExtension on AppThemeMode {
  /// Get display name for UI
  String get displayName {
    switch (this) {
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.system:
        return 'System';
    }
  }

  /// Get persistence key for storage
  String get persistenceKey {
    switch (this) {
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.system:
        return 'system';
    }
  }

  /// Create AppThemeMode from persistence key
  static AppThemeMode fromPersistenceKey(String key) {
    switch (key) {
      case 'dark':
        return AppThemeMode.dark;
      case 'light':
        return AppThemeMode.light;
      case 'system':
        return AppThemeMode.system;
      default:
        return AppThemeMode.dark; // Default fallback
    }
  }
}
