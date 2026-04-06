/// Unix signal types for PTY sessions
library;

/// Unix signals that can be sent to a PTY session
///
/// These signals are used to control the behavior of the child process
/// running in the pseudo-terminal.
///
/// Example:
/// ```dart
/// await session.sendSignal(PtySignal.sigint); // Send Ctrl+C
/// ```
enum PtySignal {
  /// SIGINT - Interrupt signal (Ctrl+C)
  ///
  /// Typically used to interrupt a running program.
  /// Most programs will terminate gracefully when receiving this signal.
  sigint,

  /// SIGTERM - Termination signal
  ///
  /// Requests the process to terminate gracefully.
  /// This is the default signal sent by the `kill` command.
  sigterm,

  /// SIGKILL - Kill signal
  ///
  /// Forces the process to terminate immediately.
  /// Cannot be caught or ignored by the process.
  /// Use as a last resort when SIGTERM doesn't work.
  sigkill,

  /// SIGHUP - Hangup signal
  ///
  /// Originally sent when a terminal connection was lost.
  /// Often used to reload configuration files.
  sighup,

  /// SIGQUIT - Quit signal (Ctrl+\)
  ///
  /// Similar to SIGINT but also generates a core dump.
  /// Used for debugging purposes.
  sigquit;

  /// Get the Unix signal number
  ///
  /// Returns the standard Unix signal number for this signal.
  /// Note: Windows has limited signal support.
  int get signalNumber {
    switch (this) {
      case PtySignal.sigint:
        return 2;
      case PtySignal.sigterm:
        return 15;
      case PtySignal.sigkill:
        return 9;
      case PtySignal.sighup:
        return 1;
      case PtySignal.sigquit:
        return 3;
    }
  }

  /// Get the signal name
  ///
  /// Returns the standard Unix signal name (e.g., "SIGINT").
  String get signalName {
    switch (this) {
      case PtySignal.sigint:
        return 'SIGINT';
      case PtySignal.sigterm:
        return 'SIGTERM';
      case PtySignal.sigkill:
        return 'SIGKILL';
      case PtySignal.sighup:
        return 'SIGHUP';
      case PtySignal.sigquit:
        return 'SIGQUIT';
    }
  }

  /// Check if this signal is supported on the current platform
  ///
  /// Windows has limited signal support compared to Unix systems.
  bool get isSupportedOnCurrentPlatform {
    // On Windows, only SIGINT and SIGKILL are reliably supported
    // TODO: Implement platform detection
    return true; // Assume Unix for now
  }

  @override
  String toString() => signalName;
}
