/// Production terminal backend implemented with flutter_rust_bridge.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:goox_terminal/src/backend/terminal_backend.dart';
import 'package:goox_terminal/src/models.dart';
import 'package:goox_terminal/src/rust/api/terminal.dart' as rust_api;
import 'package:goox_terminal/src/rust/frb_generated.dart';

/// Production backend that delegates to the Rust PTY runtime.
final class RustTerminalBackend implements TerminalBackend {
  /// Creates the singleton backend.
  RustTerminalBackend._();

  /// Shared backend instance.
  static final RustTerminalBackend instance = RustTerminalBackend._();

  Future<void>? _initFuture;

  @override
  Future<void> ensureInitialized() {
    return _initFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await RustLib.init(forceSameCodegenVersion: true);
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  @override
  Future<String> createSession(PtyConfig config) async {
    await ensureInitialized();
    final request = _toRustSpawnRequest(config);
    return rust_api.createSession(request: request);
  }

  @override
  Future<TerminalSessionInfo> sessionInfo(String sessionId) async {
    await ensureInitialized();
    final snapshot = await rust_api.sessionSnapshot(sessionId: sessionId);
    return _mapSnapshot(snapshot);
  }

  @override
  Future<List<TerminalSessionInfo>> listSessions() async {
    await ensureInitialized();
    final snapshots = await rust_api.listSessions();
    return snapshots.map(_mapSnapshot).toList(growable: false);
  }

  @override
  Stream<Uint8List> observeOutput(String sessionId) {
    return rust_api.attachOutput(sessionId: sessionId);
  }

  @override
  Future<int> writeInput(String sessionId, Uint8List data) async {
    await ensureInitialized();
    return rust_api.writeInput(sessionId: sessionId, data: data);
  }

  @override
  Future<void> resizeSession(String sessionId, PtySize size) async {
    await ensureInitialized();
    await rust_api.resizeSession(
      sessionId: sessionId,
      rows: size.rows,
      cols: size.cols,
    );
  }

  @override
  Future<void> sendSignal(String sessionId, PtySignal signal) async {
    await ensureInitialized();
    await rust_api.sendSignal(
      sessionId: sessionId,
      signalNumber: signal.signalNumber,
    );
  }

  @override
  Future<int> waitForExit(String sessionId) async {
    await ensureInitialized();
    return await rust_api.waitForExit(sessionId: sessionId);
  }

  @override
  Future<void> closeSession(String sessionId) async {
    await ensureInitialized();
    await rust_api.closeSession(sessionId: sessionId);
  }

  @override
  Future<void> dispose() async {
    _initFuture = null;
    RustLib.dispose();
  }

  rust_api.TerminalSpawnRequest _toRustSpawnRequest(PtyConfig config) {
    return rust_api.TerminalSpawnRequest(
      shell: config.shell,
      args: List<String>.unmodifiable(config.args),
      workingDirectory: config.workingDirectory,
      environment: config.environment == null
          ? const <String, String>{}
          : Map<String, String>.unmodifiable(config.environment!),
      rows: config.size.rows,
      cols: config.size.cols,
    );
  }

  TerminalSessionInfo _mapSnapshot(rust_api.TerminalSessionSnapshot snapshot) {
    return TerminalSessionInfo(
      id: snapshot.sessionId,
      status: _mapStatus(snapshot.status),
      pid: snapshot.pid?.toInt(),
      exitCode: snapshot.exitCode?.toInt(),
      shell: snapshot.shell,
      args: List<String>.unmodifiable(snapshot.args),
      workingDirectory: snapshot.workingDirectory,
      environment: Map<String, String>.unmodifiable(snapshot.environment),
      size: PtySize(rows: snapshot.rows.toInt(), cols: snapshot.cols.toInt()),
      attached: snapshot.attached,
      createdAt: DateTime.fromMillisecondsSinceEpoch(snapshot.createdAtMs),
      startedAt: snapshot.startedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(snapshot.startedAtMs!),
      lastActivityAt: snapshot.lastActivityAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(snapshot.lastActivityAtMs!),
    );
  }

  TerminalStatus _mapStatus(rust_api.TerminalSessionStatus status) {
    switch (status) {
      case rust_api.TerminalSessionStatus.starting:
        return TerminalStatus.starting;
      case rust_api.TerminalSessionStatus.running:
        return TerminalStatus.running;
      case rust_api.TerminalSessionStatus.exited:
        return TerminalStatus.exited;
      case rust_api.TerminalSessionStatus.closed:
        return TerminalStatus.closed;
      case rust_api.TerminalSessionStatus.failed:
        return TerminalStatus.failed;
    }
  }
}
