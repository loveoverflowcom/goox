import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/goox_terminal.dart';
import 'package:goox_terminal_example/main.dart';

void main() {
  testWidgets('creates, uses, and closes a fake terminal session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = FakeTerminalBackend();
    final manager = PtyManager.test(backend: backend);

    await tester.pumpWidget(
      TerminalManagerApp(
        manager: manager,
        initialize: () async {},
        disposeTerminal: () async {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Goox Terminal'), findsOneWidget);
    expect(find.text('New terminal'), findsOneWidget);

    await tester.tap(find.text('New terminal'));
    await tester.pumpAndSettle();

    expect(find.text('fake-1'), findsOneWidget);
    expect(backend.initializedCount, greaterThanOrEqualTo(2));

    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.textContaining('hello from Goox Terminal'), findsOneWidget);
    expect(find.textContaining('echo'), findsOneWidget);

    await tester.tap(find.byTooltip('Close terminal'));
    await tester.pumpAndSettle();

    expect(find.text('fake-1'), findsNothing);
  });
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
    final sessions = _sessions.values.toList(growable: false);
    return sessions.map((session) => session.info).toList(growable: false);
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
    session.writes.add(Uint8List.fromList(data));
    session.output.add(Uint8List.fromList(data));
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
  _FakeSession({required this.id, required this.config})
    : size = config.size,
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
