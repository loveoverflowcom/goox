import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/terminal/data/models/terminal_config.dart';
import 'package:goox/features/terminal/data/repositories/terminal_repository.dart';

part 'terminal_event.dart';
part 'terminal_state.dart';

/// BLoC for managing terminal panel state
class TerminalBloc extends Bloc<TerminalEvent, TerminalState> {
  /// Constructor
  TerminalBloc({
    required TerminalRepository repository,
  })  : _repository = repository,
        super(const TerminalState()) {
    on<InitializeTerminalEvent>(_onInitialize);
    on<ToggleTerminalEvent>(_onToggle);
    on<ResizeTerminalEvent>(_onResize);
  }

  final TerminalRepository _repository;

  /// Handle initialization with saved preferences
  Future<void> _onInitialize(
    InitializeTerminalEvent event,
    Emitter<TerminalState> emit,
  ) async {
    final visibility = await _repository.loadVisibility();
    final height = await _repository.loadHeight();

    emit(
      state.copyWith(
        isVisible: visibility,
        height: height,
        status: TerminalStatus.loaded,
      ),
    );
  }

  /// Handle terminal visibility toggle
  Future<void> _onToggle(
    ToggleTerminalEvent event,
    Emitter<TerminalState> emit,
  ) async {
    final newVisibility = !state.isVisible;

    // Save to repository
    await _repository.saveVisibility(isVisible: newVisibility);

    emit(
      state.copyWith(
        isVisible: newVisibility,
      ),
    );
  }

  /// Handle terminal resize
  Future<void> _onResize(
    ResizeTerminalEvent event,
    Emitter<TerminalState> emit,
  ) async {
    // Constrain height to valid range
    final constrainedHeight = math.max(
      TerminalConfig.minHeight,
      event.newHeight,
    );

    // Save to repository
    await _repository.saveHeight(constrainedHeight);

    emit(
      state.copyWith(
        height: constrainedHeight,
      ),
    );
  }
}
