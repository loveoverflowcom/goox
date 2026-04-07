import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/goox_terminal.dart';

void main() {
  test('createSessionHandle relays output and resize updates state', () async {
    final backend = FakeTerminalBackend();
    final manager = PtyManager.test(backend: backend);

    addTearDown(() async => _disposeManager(manager, backend));

    final session = await manager.createSessionHandle(
      PtyConfig.defaultShell(
        size: const PtySize(rows: 24, cols: 80),
      ),
    );

    expect(backend.initializedCount, greaterThanOrEqualTo(2));
    expect(session.status, TerminalStatus.running);
    expect(session.isAttached, isTrue);

    final outputs = <String>[];
    final subscription =
        session.outputStream.map(utf8.decode).listen(outputs.add);
    addTearDown(subscription.cancel);

    await session.write('echo hello\n');
    expect(outputs.join(), contains('echo hello'));
    expect(session.transcript, contains('echo hello'));

    await session.resize(40, 120);
    expect(session.info.size, const PtySize(rows: 40, cols: 120));

    final infos = await manager.listSessionInfos();
    expect(infos, hasLength(1));
    expect(infos.single.size, const PtySize(rows: 40, cols: 120));

    await session.close();
    expect(session.isClosed, isTrue);
    expect(manager.listSessions(), isEmpty);
  });

  test('openSession attaches to an existing session', () async {
    final backend = FakeTerminalBackend();
    final creator = PtyManager.test(backend: backend);
    final opener = PtyManager.test(backend: backend);

    addTearDown(() async {
      await creator.closeAllSessions();
      await opener.closeAllSessions();
      await backend.dispose();
    });

    final created = await creator.createSessionHandle(
      PtyConfig.defaultShell(
        size: const PtySize(rows: 24, cols: 80),
      ),
    );

    final reopened = await opener.openSession(created.id);
    expect(reopened.id, created.id);
    expect(reopened.isAttached, isTrue);

    final outputs = <String>[];
    final subscription =
        reopened.outputStream.map(utf8.decode).listen(outputs.add);
    addTearDown(subscription.cancel);

    await reopened.write('whoami\n');
    expect(outputs.join(), contains('whoami'));
    expect(reopened.transcript, contains('whoami'));
  });

  test('closeAllSessions cleans up multiple sessions', () async {
    final backend = FakeTerminalBackend();
    final manager = PtyManager.test(backend: backend);

    addTearDown(() async => _disposeManager(manager, backend));

    await manager.createSessionHandle(
      PtyConfig.defaultShell(
        size: const PtySize(rows: 24, cols: 80),
      ),
    );
    await manager.createSessionHandle(
      PtyConfig.defaultShell(
        size: const PtySize(rows: 30, cols: 100),
      ),
    );

    expect(manager.listSessions(), hasLength(2));

    await manager.closeAllSessions();

    expect(manager.listSessions(), isEmpty);
    expect(backend.sessionCount, 0);
  });
}

Future<void> _disposeManager(
  PtyManager manager,
  FakeTerminalBackend backend,
) async {
  await manager.closeAllSessions();
  await backend.dispose();
}

class FakeTerminalBackend implements TerminalBackend {
  final Map<String, _FakeSession> _sessions = <String, _FakeSession>{};
  int _nextId = 1;

  int initializedCount = 0;

  int get sessionCount => _sessions.length;

  @override
  Future<void> ensureInitialized() async {
    initializedCount += 1;
  }

  @override
  Future<String> createSession(PtyConfig config) async {
    final id = 'fake-${_nextId++}';
    _sessions[id] = _FakeSession(id: id, config: config);
    return id;
  }

  @override
  Future<TerminalSessionInfo> sessionInfo(String sessionId) async {
    return _session(sessionId).info;
  }

  @override
  Future<List<TerminalSessionInfo>> listSessions() async {
    return _sessions.values
        .map((session) => session.info)
        .toList(growable: false);
  }

  @override
  Stream<Uint8List> observeOutput(String sessionId) {
    final session = _session(sessionId);
    session.attached = true;
    session.info = session.info.copyWith(attached: true);
    return session.output.stream;
  }

  @override
  Future<int> writeInput(String sessionId, Uint8List data) async {
    final session = _session(sessionId);
    final copy = Uint8List.fromList(data);
    session.writes.add(copy);
    session.output.add(copy);
    session.info = session.info.copyWith(
      lastActivityAt: DateTime.now(),
      status: TerminalStatus.running,
      attached: true,
    );
    return data.length;
  }

  @override
  Future<void> resizeSession(String sessionId, PtySize size) async {
    final session = _session(sessionId);
    session.size = size;
    session.info = session.info.copyWith(
      size: size,
      lastActivityAt: DateTime.now(),
    );
  }

  @override
  Future<void> sendSignal(String sessionId, PtySignal signal) async {
    final session = _session(sessionId);
    session.info = session.info.copyWith(
      status: TerminalStatus.exited,
      exitCode: signal == PtySignal.sigkill ? 137 : 130,
      lastActivityAt: DateTime.now(),
    );
  }

  @override
  Future<int> waitForExit(String sessionId) async {
    final session = _session(sessionId);
    session.info = session.info.copyWith(
      status: TerminalStatus.exited,
      exitCode: session.info.exitCode ?? 0,
      lastActivityAt: DateTime.now(),
    );
    return session.info.exitCode ?? 0;
  }

  @override
  Future<void> closeSession(String sessionId) async {
    final session = _sessions.remove(sessionId);
    if (session == null) {
      throw StateError('Session not found: $sessionId');
    }
    session.info = session.info.copyWith(
      status: TerminalStatus.closed,
      attached: false,
      lastActivityAt: DateTime.now(),
    );
    await session.output.close();
  }

  @override
  Future<void> dispose() async {
    final sessions = _sessions.values.toList(growable: false);
    _sessions.clear();
    for (final session in sessions) {
      await session.output.close();
    }
  }

  _FakeSession _session(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) {
      throw StateError('Session not found: $sessionId');
    }
    return session;
  }
}

class _FakeSession {
  _FakeSession({
    required this.id,
    required this.config,
  })  : size = config.size,
        info = TerminalSessionInfo(
          id: id,
          status: TerminalStatus.running,
          shell: config.shell ?? 'shell',
          args: List<String>.unmodifiable(config.args),
          workingDirectory: config.workingDirectory,
          environment: config.environment == null
              ? const <String, String>{}
              : Map<String, String>.unmodifiable(config.environment!),
          size: config.size,
          attached: false,
          createdAt: DateTime.now(),
          startedAt: DateTime.now(),
          lastActivityAt: DateTime.now(),
        );

  final String id;
  final PtyConfig config;
  PtySize size;
  TerminalSessionInfo info;
  final List<Uint8List> writes = <Uint8List>[];
  final StreamController<Uint8List> output =
      StreamController<Uint8List>.broadcast(sync: true);
  bool attached = false;
}
