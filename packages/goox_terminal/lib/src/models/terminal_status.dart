/// Lifecycle state for a terminal session.
library;

/// Lifecycle state for a terminal session.
///
/// Represents the current state of a terminal session in its lifecycle.
/// Status transitions follow: initializing → running → (exited | error)
enum TerminalStatus {
  /// Terminal is being initialized (creating xterm and PTY instances).
  initializing,

  /// Terminal is running and can accept input.
  running,

  /// Terminal process has exited normally.
  exited,

  /// Terminal encountered an error and cannot continue.
  error,
}

extension TerminalStatusX on TerminalStatus {
  /// Returns true if the terminal is actively running.
  ///
  /// Only running terminals are considered active.
  bool get isActive => this == TerminalStatus.running;

  /// Returns true if the terminal can accept user input.
  ///
  /// Only running terminals can accept input.
  bool get canSendInput => this == TerminalStatus.running;
}
