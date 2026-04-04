part of 'theme_bloc.dart';

/// Status of theme loading
enum ThemeStatus {
  /// Initial state
  initial,

  /// Theme is loading
  loading,

  /// Theme loaded successfully
  loaded,
}

/// State for theme management
final class ThemeState extends Equatable {
  /// Constructor
  const ThemeState({
    this.themeMode = AppThemeMode.dark,
    this.resolvedBrightness = Brightness.dark,
    this.status = ThemeStatus.initial,
  });

  /// User's selected theme mode (dark/light/system)
  final AppThemeMode themeMode;

  /// Actual brightness to apply (resolved from themeMode)
  final Brightness resolvedBrightness;

  /// Loading status
  final ThemeStatus status;

  /// Get the ThemeData based on resolved brightness
  ThemeData get themeData {
    return resolvedBrightness == Brightness.dark
        ? AppTheme.dark
        : AppTheme.light;
  }

  /// Copy with method for immutable updates
  ThemeState copyWith({
    AppThemeMode? themeMode,
    Brightness? resolvedBrightness,
    ThemeStatus? status,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      resolvedBrightness: resolvedBrightness ?? this.resolvedBrightness,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [themeMode, resolvedBrightness, status];
}
