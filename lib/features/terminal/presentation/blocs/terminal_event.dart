part of 'terminal_bloc.dart';

/// Base class for terminal events
sealed class TerminalEvent extends Equatable {
  /// Constructor
  const TerminalEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize terminal with saved preferences
final class InitializeTerminalEvent extends TerminalEvent {
  /// Constructor
  const InitializeTerminalEvent();
}

/// Event to toggle terminal visibility
final class ToggleTerminalEvent extends TerminalEvent {
  /// Constructor
  const ToggleTerminalEvent();
}

/// Event to resize terminal panel
final class ResizeTerminalEvent extends TerminalEvent {
  /// Constructor
  const ResizeTerminalEvent(this.newHeight);

  /// The new height for the terminal panel
  final double newHeight;

  @override
  List<Object?> get props => [newHeight];
}
