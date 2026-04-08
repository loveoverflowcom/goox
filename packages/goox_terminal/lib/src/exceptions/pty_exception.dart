/// Exception types for PTY operations
library;

/// Base exception for PTY operations
///
/// All PTY-related exceptions extend this class.
class PtyException implements Exception {
  /// Error message
  final String message;

  /// Session ID (if applicable)
  final String? sessionId;

  /// Underlying cause (if any)
  final Object? cause;

  /// Creates a new PTY exception
  const PtyException(
    this.message, {
    this.sessionId,
    this.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer('PtyException: $message');
    if (sessionId != null) {
      buffer.write(' (session: $sessionId)');
    }
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

/// Session not found exception
///
/// Thrown when attempting to access a session that doesn't exist.
///
/// Example:
/// ```dart
/// try {
///   await PtyManager.instance.closeSession('invalid_id');
/// } on SessionNotFoundException catch (e) {
///   print('Session not found: ${e.sessionId}');
/// }
/// ```
class SessionNotFoundException extends PtyException {
  /// Creates a session not found exception
  const SessionNotFoundException(String sessionId)
      : super(
          'Session not found: $sessionId',
          sessionId: sessionId,
        );
}

/// Session creation exception
///
/// Thrown when creating a new PTY session fails.
///
/// Example:
/// ```dart
/// try {
///   await PtyManager.instance.createSession(config);
/// } on SessionCreationException catch (e) {
///   print('Failed to create session: ${e.message}');
/// }
/// ```
class SessionCreationException extends PtyException {
  /// Creates a session creation exception
  const SessionCreationException(
    String message, {
    Object? cause,
  }) : super(
          'Failed to create session: $message',
          cause: cause,
        );
}

/// I/O operation exception
///
/// Thrown when a read or write operation fails.
///
/// Example:
/// ```dart
/// try {
///   await session.write('command\n');
/// } on PtyIOException catch (e) {
///   print('I/O error: ${e.message}');
/// }
/// ```
class PtyIOException extends PtyException {
  /// Creates an I/O exception
  const PtyIOException(
    String message, {
    String? sessionId,
    Object? cause,
  }) : super(
          'I/O error: $message',
          sessionId: sessionId,
          cause: cause,
        );
}

/// Process spawn exception
///
/// Thrown when spawning the child process fails.
///
/// Example:
/// ```dart
/// try {
///   await PtyManager.instance.createSession(config);
/// } on ProcessSpawnException catch (e) {
///   print('Failed to spawn process: ${e.message}');
/// }
/// ```
class ProcessSpawnException extends PtyException {
  /// Creates a process spawn exception
  const ProcessSpawnException(
    String message, {
    Object? cause,
  }) : super(
          'Failed to spawn process: $message',
          cause: cause,
        );
}

/// PTY creation exception
///
/// Thrown when creating a PTY instance fails.
/// This is an alias for ProcessSpawnException for semantic clarity.
///
/// Example:
/// ```dart
/// try {
///   await controller.initialize();
/// } on PtyCreationException catch (e) {
///   print('Failed to create PTY: ${e.message}');
/// }
/// ```
typedef PtyCreationException = ProcessSpawnException;

/// PTY resize exception
///
/// Thrown when resizing the terminal fails.
///
/// Example:
/// ```dart
/// try {
///   await session.resize(30, 100);
/// } on PtyResizeException catch (e) {
///   print('Failed to resize: ${e.message}');
/// }
/// ```
class PtyResizeException extends PtyException {
  /// Creates a resize exception
  const PtyResizeException(
    String message, {
    String? sessionId,
    Object? cause,
  }) : super(
          'Failed to resize terminal: $message',
          sessionId: sessionId,
          cause: cause,
        );
}

/// Signal send exception
///
/// Thrown when sending a signal to the process fails.
///
/// Example:
/// ```dart
/// try {
///   await session.sendSignal(PtySignal.sigint);
/// } on SignalSendException catch (e) {
///   print('Failed to send signal: ${e.message}');
/// }
/// ```
class SignalSendException extends PtyException {
  /// Creates a signal send exception
  const SignalSendException(
    String message, {
    String? sessionId,
    Object? cause,
  }) : super(
          'Failed to send signal: $message',
          sessionId: sessionId,
          cause: cause,
        );
}
