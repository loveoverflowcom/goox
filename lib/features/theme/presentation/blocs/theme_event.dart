part of 'theme_bloc.dart';

/// Base class for theme events
sealed class ThemeEvent extends Equatable {
  /// Constructor
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load saved theme preference on app start
final class LoadThemePreferenceEvent extends ThemeEvent {
  /// Constructor
  const LoadThemePreferenceEvent();
}

/// Event when user selects a theme mode
final class SelectThemeEvent extends ThemeEvent {
  /// Constructor
  const SelectThemeEvent(this.mode);

  /// The selected theme mode
  final AppThemeMode mode;

  @override
  List<Object?> get props => [mode];
}

/// Event when system theme changes (only relevant in System mode)
final class SystemThemeChangedEvent extends ThemeEvent {
  /// Constructor
  const SystemThemeChangedEvent(this.brightness);

  /// The new system brightness
  final Brightness brightness;

  @override
  List<Object?> get props => [brightness];
}
