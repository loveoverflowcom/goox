import 'package:flutter/foundation.dart';

import '../models/pty_size.dart';
import '../models/shell_config.dart';
import 'terminal_controller.dart';

/// Manages multiple terminal sessions and provides a centralized registry.
///
/// This singleton class is responsible for:
/// - Creating new terminal sessions
/// - Tracking all active sessions
/// - Managing active session selection
/// - Enforcing session limits (max 10)
/// - Providing session lookup
/// - Cleaning up closed sessions
/// - Notifying listeners of session changes
///
/// Example:
/// ```dart
/// final sessionManager = TerminalSessionManager.instance;
///
/// // Create a new terminal session
/// final controller = await sessionManager.createSession(
///   shellConfig: ShellConfig.bash(),
///   initialSize: PtySize.defaultSize,
/// );
///
/// // Switch active session
/// sessionManager.activeSessionId = controller.id;
///
/// // Close session
/// await sessionManager.closeSession(controller.id);
/// ```
class TerminalSessionManager extends ChangeNotifier {
  /// Private constructor for singleton pattern.
  TerminalSessionManager._();

  /// Singleton instance of TerminalSessionManager.
  static final TerminalSessionManager instance = TerminalSessionManager._();

  /// Session registry mapping session IDs to TerminalController instances.
  final Map<String, TerminalController> _sessions = {};

  /// Currently active session ID.
  ///
  /// This is the session that is currently displayed in the UI.
  /// Can be null if no sessions exist.
  String? _activeSessionId;

  /// Maximum number of concurrent sessions allowed.
  ///
  /// This limit prevents resource exhaustion from too many PTY processes.
  static const int maxSessions = 10;

  /// Counter for generating unique session IDs.
  int _sessionCounter = 0;

  /// Gets the currently active session ID.
  ///
  /// Returns null if no sessions exist or no session is active.
  String? get activeSessionId => _activeSessionId;

  /// Sets the currently active session ID.
  ///
  /// The session must exist in the registry.
  ///
  /// Throws [ArgumentError] if the session ID does not exist in the registry.
  set activeSessionId(String? id) {
    if (id != null && !_sessions.containsKey(id)) {
      throw ArgumentError(
        'Cannot set active session: session with id "$id" does not exist',
      );
    }

    if (_activeSessionId != id) {
      _activeSessionId = id;
      notifyListeners();
    }
  }

  /// Gets the currently active session controller.
  ///
  /// Returns null if no session is active.
  TerminalController? get activeSession {
    if (_activeSessionId == null) {
      return null;
    }
    return _sessions[_activeSessionId];
  }

  /// Gets the number of active sessions.
  int get sessionCount => _sessions.length;

  /// Gets all active sessions as a list.
  List<TerminalController> get allSessions => _sessions.values.toList();

  /// Checks if a new session can be created.
  ///
  /// Returns true if the session count is below the maximum limit.
  bool get canCreateSession => sessionCount < maxSessions;

  /// Creates a new terminal session.
  ///
  /// Parameters:
  /// - [shellConfig]: Configuration for the shell process. If not provided,
  ///   uses the default shell configuration.
  /// - [initialSize]: Initial terminal dimensions. If not provided,
  ///   uses the default size (24x80).
  ///
  /// Returns the created [TerminalController].
  ///
  /// Throws [StateError] if the session limit has been reached.
  Future<TerminalController> createSession({
    ShellConfig? shellConfig,
    PtySize? initialSize,
  }) async {
    // Validate session count < maxSessions
    if (!canCreateSession) {
      throw StateError(
        'Cannot create session: maximum session limit ($maxSessions) reached',
      );
    }

    // Generate unique session ID
    final sessionId = 'terminal-${_sessionCounter++}';

    // Create TerminalController with provided or default config
    final controller = TerminalController(
      id: sessionId,
      shellConfig: shellConfig ?? ShellConfig.forPlatform(),
      initialSize: initialSize ?? PtySize.defaultSize,
    );

    // Initialize the controller
    await controller.initialize();

    // Add controller to registry
    _sessions[sessionId] = controller;

    // Set as active session if first session
    if (_sessions.length == 1) {
      _activeSessionId = sessionId;
    }

    // Notify listeners
    notifyListeners();

    return controller;
  }

  /// Closes a terminal session.
  ///
  /// Parameters:
  /// - [id]: The ID of the session to close.
  ///
  /// Throws [ArgumentError] if the session does not exist.
  Future<void> closeSession(String id) async {
    // Get controller from registry
    final controller = _sessions[id];
    if (controller == null) {
      throw ArgumentError(
        'Cannot close session: session with id "$id" does not exist',
      );
    }

    // Call controller.dispose()
    await controller.dispose();

    // Remove from registry
    _sessions.remove(id);

    // Update activeSessionId if closing active session
    if (_activeSessionId == id) {
      // Set active session to the first available session, or null if none
      _activeSessionId = _sessions.isNotEmpty ? _sessions.keys.first : null;
    }

    // Notify listeners
    notifyListeners();
  }

  /// Gets a session controller by ID.
  ///
  /// Returns null if the session does not exist.
  TerminalController? getSession(String id) {
    return _sessions[id];
  }

  /// Closes all terminal sessions.
  ///
  /// This method disposes all active sessions and clears the registry.
  Future<void> closeAllSessions() async {
    // Create a copy of session IDs to avoid modification during iteration
    final sessionIds = _sessions.keys.toList();

    // Close each session
    for (final id in sessionIds) {
      await closeSession(id);
    }

    // Ensure registry is empty and active session is null
    _sessions.clear();
    _activeSessionId = null;

    // Notify listeners
    notifyListeners();
  }

  @override
  void dispose() {
    // Close all sessions before disposing
    closeAllSessions();
    super.dispose();
  }
}
