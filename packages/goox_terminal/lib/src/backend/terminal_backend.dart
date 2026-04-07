/// Internal backend contract for the terminal wrapper.
library;

import 'dart:typed_data';

import 'package:goox_terminal/src/models.dart';

/// Contract for terminal session backends.
///
/// The production implementation talks to Rust through flutter_rust_bridge.
/// Tests can inject a fake backend without depending on native PTY support.
abstract interface class TerminalBackend {
  /// Ensures the backend is ready to accept requests.
  Future<void> ensureInitialized();

  /// Creates a new terminal session and returns its identifier.
  Future<String> createSession(PtyConfig config);

  /// Returns the current snapshot for a managed session.
  Future<TerminalSessionInfo> sessionInfo(String sessionId);

  /// Lists all managed sessions.
  Future<List<TerminalSessionInfo>> listSessions();

  /// Subscribes to terminal output for the given session.
  Stream<Uint8List> observeOutput(String sessionId);

  /// Writes bytes into the terminal input stream.
  Future<int> writeInput(String sessionId, Uint8List data);

  /// Resizes the terminal.
  Future<void> resizeSession(String sessionId, PtySize size);

  /// Sends a signal to the terminal process.
  Future<void> sendSignal(String sessionId, PtySignal signal);

  /// Waits for the process to exit and returns the exit code.
  Future<int> waitForExit(String sessionId);

  /// Closes and removes the session from the backend registry.
  Future<void> closeSession(String sessionId);

  /// Releases any backend-specific resources.
  Future<void> dispose();
}
