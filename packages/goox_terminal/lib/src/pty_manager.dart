/// PTY Manager - Main entry point for PTY operations
library;

import 'package:goox_terminal/src/models.dart';
import 'package:goox_terminal/src/pty_session.dart';

/// Main entry point for PTY operations
///
/// This class manages all PTY sessions and provides methods to create,
/// close, and query sessions.
///
/// Use the singleton [instance] to access the manager:
/// ```dart
/// final manager = PtyManager.instance;
/// ```
class PtyManager {
  /// Singleton instance
  static final PtyManager instance = PtyManager._();

  /// Private constructor for singleton
  PtyManager._();

  /// Internal session registry
  final Map<String, PtySession> _sessions = {};

  /// Create a new PTY session
  ///
  /// Creates a new pseudo-terminal session with the given [config].
  /// Returns a unique session ID that can be used to retrieve the session.
  ///
  /// Example:
  /// ```dart
  /// final config = PtyConfig(shell: '/bin/bash');
  /// final sessionId = await PtyManager.instance.createSession(config);
  /// ```
  ///
  /// Throws [PtyException] if session creation fails.
  Future<String> createSession(PtyConfig config) async {
    // TODO: Implement using Rust FFI
    throw UnimplementedError('createSession not yet implemented');
  }

  /// Close a PTY session
  ///
  /// Closes the session with the given [sessionId] and cleans up resources.
  /// This will terminate the child process and close all I/O streams.
  ///
  /// Example:
  /// ```dart
  /// await PtyManager.instance.closeSession(sessionId);
  /// ```
  ///
  /// Throws [SessionNotFoundException] if session doesn't exist.
  Future<void> closeSession(String sessionId) async {
    // TODO: Implement using Rust FFI
    throw UnimplementedError('closeSession not yet implemented');
  }

  /// Get a PTY session by ID
  ///
  /// Returns the [PtySession] with the given [sessionId], or null if not found.
  ///
  /// Example:
  /// ```dart
  /// final session = PtyManager.instance.getSession(sessionId);
  /// if (session != null) {
  ///   await session.write('ls\n');
  /// }
  /// ```
  PtySession? getSession(String sessionId) {
    return _sessions[sessionId];
  }

  /// List all active session IDs
  ///
  /// Returns a list of all currently active session IDs.
  ///
  /// Example:
  /// ```dart
  /// final sessions = PtyManager.instance.listSessions();
  /// print('Active sessions: ${sessions.length}');
  /// ```
  List<String> listSessions() {
    return _sessions.keys.toList();
  }

  /// Check if a session is running
  ///
  /// Returns true if the session with [sessionId] exists and is running.
  ///
  /// Example:
  /// ```dart
  /// if (PtyManager.instance.isSessionRunning(sessionId)) {
  ///   print('Session is active');
  /// }
  /// ```
  bool isSessionRunning(String sessionId) {
    return _sessions.containsKey(sessionId);
  }
}
