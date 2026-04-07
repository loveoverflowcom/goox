part of 'terminal_panel_bloc.dart';

/// Base class for terminal panel events
sealed class TerminalPanelEvent extends Equatable {
  /// Constructor
  const TerminalPanelEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize terminal panel with saved preferences
final class InitializeTerminalPanelEvent extends TerminalPanelEvent {
  /// Constructor
  const InitializeTerminalPanelEvent();
}

/// Event to toggle terminal panel visibility
final class ToggleTerminalPanelEvent extends TerminalPanelEvent {
  /// Constructor
  const ToggleTerminalPanelEvent();
}

/// Event to resize terminal panel
final class ResizeTerminalPanelEvent extends TerminalPanelEvent {
  /// Constructor
  const ResizeTerminalPanelEvent(this.newHeight);

  /// The new height for the terminal panel
  final double newHeight;

  @override
  List<Object?> get props => [newHeight];
}

/// Event to create a new terminal session
final class CreateTerminalSessionEvent extends TerminalPanelEvent {
  /// Constructor
  const CreateTerminalSessionEvent({this.workingDirectory});

  /// Optional working directory for the new session
  final String? workingDirectory;

  @override
  List<Object?> get props => [workingDirectory];
}

/// Event to close a terminal session
final class CloseTerminalSessionEvent extends TerminalPanelEvent {
  /// Constructor
  const CloseTerminalSessionEvent(this.sessionId);

  /// ID of the session to close
  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

/// Event to switch to a different terminal session
final class SwitchTerminalSessionEvent extends TerminalPanelEvent {
  /// Constructor
  const SwitchTerminalSessionEvent(this.sessionId);

  /// ID of the session to switch to
  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

/// Event to cycle through terminal sessions
final class CycleTerminalSessionEvent extends TerminalPanelEvent {
  /// Constructor
  const CycleTerminalSessionEvent({required this.forward});

  /// Whether to cycle forward (true) or backward (false)
  final bool forward;

  @override
  List<Object?> get props => [forward];
}
