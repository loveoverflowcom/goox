import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/theme/data/models/theme_mode.dart';
import 'package:goox/features/theme/data/repositories/theme_repository.dart';
import 'package:goox_ui/goox_ui.dart';

part 'theme_event.dart';
part 'theme_state.dart';

/// BLoC for managing theme state
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  /// Constructor
  ThemeBloc({
    required ThemeRepository repository,
  })  : _repository = repository,
        super(const ThemeState()) {
    on<LoadThemePreferenceEvent>(_onLoadThemePreference);
    on<SelectThemeEvent>(_onSelectTheme);
    on<SystemThemeChangedEvent>(_onSystemThemeChanged);

    // Set up system theme observer
    _setupSystemThemeObserver();
  }

  final ThemeRepository _repository;
  _ThemeObserver? _observer;

  /// Set up observer for system theme changes
  void _setupSystemThemeObserver() {
    _observer = _ThemeObserver((brightness) {
      add(SystemThemeChangedEvent(brightness));
    });
    WidgetsBinding.instance.addObserver(_observer!);
  }

  /// Handle loading saved theme preference
  Future<void> _onLoadThemePreference(
    LoadThemePreferenceEvent event,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(status: ThemeStatus.loading));

    final mode = await _repository.loadThemeMode();
    final brightness = _resolveBrightness(mode);
    final themeData = brightness == Brightness.dark 
        ? AppTheme.dark 
        : AppTheme.light;

    emit(
      state.copyWith(
        themeMode: mode,
        resolvedBrightness: brightness,
        themeData: themeData,
        status: ThemeStatus.loaded,
      ),
    );
  }

  /// Handle theme selection
  Future<void> _onSelectTheme(
    SelectThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    // Save to repository
    await _repository.saveThemeMode(event.mode);

    // Resolve brightness
    final brightness = _resolveBrightness(event.mode);
    final themeData = brightness == Brightness.dark 
        ? AppTheme.dark 
        : AppTheme.light;

    emit(
      state.copyWith(
        themeMode: event.mode,
        resolvedBrightness: brightness,
        themeData: themeData,
        status: ThemeStatus.loaded,
      ),
    );
  }

  /// Handle system theme change
  void _onSystemThemeChanged(
    SystemThemeChangedEvent event,
    Emitter<ThemeState> emit,
  ) {
    // Only update if current mode is system
    if (state.themeMode == AppThemeMode.system) {
      final themeData = event.brightness == Brightness.dark 
          ? AppTheme.dark 
          : AppTheme.light;
      
      emit(
        state.copyWith(
          resolvedBrightness: event.brightness,
          themeData: themeData,
        ),
      );
    }
  }

  /// Resolve brightness from theme mode
  Brightness _resolveBrightness(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.system:
        return _repository.getSystemBrightness();
    }
  }

  @override
  Future<void> close() {
    if (_observer != null) {
      WidgetsBinding.instance.removeObserver(_observer!);
    }
    return super.close();
  }
}

/// Observer for system theme changes
class _ThemeObserver extends WidgetsBindingObserver {
  /// Constructor
  _ThemeObserver(this.onBrightnessChanged);

  /// Callback when brightness changes
  final void Function(Brightness) onBrightnessChanged;

  @override
  void didChangePlatformBrightness() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    onBrightnessChanged(brightness);
  }
}
