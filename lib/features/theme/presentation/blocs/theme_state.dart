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
    ThemeData? themeData,
  }) : _themeData = themeData;

  /// User's selected theme mode (dark/light/system)
  final AppThemeMode themeMode;

  /// Actual brightness to apply (resolved from themeMode)
  final Brightness resolvedBrightness;

  /// Loading status
  final ThemeStatus status;

  /// Cached theme data
  final ThemeData? _themeData;

  /// Get the ThemeData based on resolved brightness
  ThemeData get themeData {
    // Return cached theme data if available, otherwise compute from brightness
    if (_themeData != null) {
      return _themeData;
    }
    return resolvedBrightness == Brightness.dark
        ? AppTheme.dark
        : AppTheme.light;
  }

  /// Copy with method for immutable updates
  ThemeState copyWith({
    AppThemeMode? themeMode,
    Brightness? resolvedBrightness,
    ThemeStatus? status,
    ThemeData? themeData,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      resolvedBrightness: resolvedBrightness ?? this.resolvedBrightness,
      status: status ?? this.status,
      themeData: themeData ?? _themeData,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    resolvedBrightness,
    status,
    _themeData,
  ];
}
