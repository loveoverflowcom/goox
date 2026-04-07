/// Session registry and lifecycle helper.
library;

import 'package:goox_terminal/src/backend/rust_terminal_backend.dart';
import 'package:goox_terminal/src/backend/terminal_backend.dart';
import 'package:goox_terminal/src/exceptions.dart';
import 'package:goox_terminal/src/models.dart';
import 'package:goox_terminal/src/pty_session.dart';

/// Registry and lifecycle helper for PTY sessions.
class PtyManager {
  /// Singleton instance using the Rust backend.
  static final PtyManager instance = PtyManager._(
    backend: RustTerminalBackend.instance,
  );

  /// Creates a test-friendly manager with a custom backend.
  PtyManager.test({required TerminalBackend backend})
      : this._(backend: backend);

  PtyManager._({required TerminalBackend backend}) : _backend = backend;

  final TerminalBackend _backend;
  final Map<String, PtySession> _sessions = {};

  /// Creates a new PTY session and returns its session identifier.
  Future<String> createSession(PtyConfig config) async {
    final session = await createSessionHandle(config);
    return session.id;
  }

  /// Creates a new PTY session and returns the wrapper directly.
  Future<PtySession> createSessionHandle(PtyConfig config) async {
    config.validate();
    await _backend.ensureInitialized();

    String? sessionId;
    try {
      sessionId = await _backend.createSession(config);
      final info = await _backend.sessionInfo(sessionId);
      final session = _createSession(
        sessionId: sessionId,
        config: config,
        info: info,
      );
      _sessions[sessionId] = session;
      await session.attach();
      return session;
    } on Object catch (error, _) {
      if (sessionId != null) {
        _sessions.remove(sessionId);
        try {
          await _backend.closeSession(sessionId);
        } on Object {
          // Best-effort cleanup.
        }
      }
      throw SessionCreationException(
        'Failed to create terminal session',
        cause: error,
      );
    }
  }

  /// Opens an existing session or restores a local wrapper around it.
  Future<PtySession> openSession(String sessionId) async {
    final existing = _sessions[sessionId];
    if (existing != null) {
      try {
        await existing.refresh();
        return existing;
      } on Object {
        _sessions.remove(sessionId);
        throw SessionNotFoundException(sessionId);
      }
    }

    await _backend.ensureInitialized();
    try {
      final info = await _backend.sessionInfo(sessionId);
      final session = _createSession(
        sessionId: sessionId,
        config: info.toConfig(),
        info: info,
      );
      _sessions[sessionId] = session;
      await session.attach();
      return session;
    } on Object {
      throw SessionNotFoundException(sessionId);
    }
  }

  /// Refreshes and returns the latest snapshot for a managed session.
  Future<TerminalSessionInfo> refreshSession(String sessionId) async {
    final session = _sessions[sessionId];
    if (session != null) {
      try {
        return await session.refresh();
      } on Object {
        _sessions.remove(sessionId);
        throw SessionNotFoundException(sessionId);
      }
    }

    await _backend.ensureInitialized();
    return _backend.sessionInfo(sessionId);
  }

  /// Returns a managed session wrapper if one exists.
  PtySession? getSession(String sessionId) => _sessions[sessionId];

  /// Returns all managed session ids.
  List<String> listSessions() => _sessions.keys.toList(growable: false);

  /// Returns a backend snapshot for every managed session.
  Future<List<TerminalSessionInfo>> listSessionInfos() async {
    await _backend.ensureInitialized();
    final infos = await _backend.listSessions();
    for (final info in infos) {
      _sessions[info.id]?.syncInfo(info);
    }
    return infos;
  }

  /// Checks whether the session is still running.
  bool isSessionRunning(String sessionId) {
    return _sessions[sessionId]?.status.isActive ?? false;
  }

  /// Closes a managed session.
  Future<void> closeSession(String sessionId) async {
    final session = _sessions[sessionId];
    if (session == null) {
      throw SessionNotFoundException(sessionId);
    }

    await session.close();
    _sessions.remove(sessionId);
  }

  /// Closes every managed session.
  Future<void> closeAllSessions() async {
    final ids = listSessions();
    for (final sessionId in ids) {
      try {
        await closeSession(sessionId);
      } on Object {
        // Best-effort cleanup for shutdown paths.
      }
    }
  }

  PtySession _createSession({
    required String sessionId,
    required PtyConfig config,
    required TerminalSessionInfo info,
  }) {
    return PtySession(
      id: sessionId,
      config: config,
      backend: _backend,
      info: info,
      onClosed: () => _sessions.remove(sessionId),
    );
  }
}
