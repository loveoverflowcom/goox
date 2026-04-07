/// PTY session wrapper.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:goox_terminal/src/backend/terminal_backend.dart';
import 'package:goox_terminal/src/exceptions.dart';
import 'package:goox_terminal/src/models.dart';

/// Represents an active PTY session.
///
/// The session attaches to the Rust PTY output stream on creation so output is
/// drained even when no UI listener is present yet. The UI can subscribe to
/// [outputStream] and listen to [notifyListeners] for status updates.
class PtySession extends ChangeNotifier {
  /// Creates a terminal session wrapper.
  ///
  /// This is intended for internal use by [PtyManager].
  PtySession({
    required this.id,
    required this.config,
    required TerminalBackend backend,
    required TerminalSessionInfo info,
    VoidCallback? onClosed,
  })  : _backend = backend,
        _info = info,
        _onClosed = onClosed;

  /// Unique session identifier.
  final String id;

  /// Configuration used to create this session.
  final PtyConfig config;

  final TerminalBackend _backend;
  final VoidCallback? _onClosed;

  final StreamController<Uint8List> _outputController =
      StreamController<Uint8List>.broadcast(sync: true);
  final StringBuffer _transcriptBuffer = StringBuffer();
  late final ByteConversionSink _transcriptSink = const Utf8Decoder(
    allowMalformed: true,
  ).startChunkedConversion(
      StringConversionSink.fromStringSink(_transcriptBuffer));

  StreamSubscription<Uint8List>? _outputSubscription;

  TerminalSessionInfo _info;
  bool _attached = false;
  bool _closed = false;
  bool _disposed = false;

  /// Current session metadata.
  TerminalSessionInfo get info => _info;

  /// Current lifecycle status.
  TerminalStatus get status => _info.status;

  /// Process identifier, if available.
  int? get pid => _info.pid;

  /// Exit code if the process has already terminated.
  int? get exitCode => _info.exitCode;

  /// True if the output stream is attached.
  bool get isAttached => _attached;

  /// True if the session has been closed locally.
  bool get isClosed => _closed;

  /// Current transcript accumulated from terminal output.
  String get transcript => _transcriptBuffer.toString();

  /// Broadcast output stream for UI listeners.
  Stream<Uint8List> get outputStream => _outputController.stream;

  /// Replaces the cached snapshot with a fresh value.
  void syncInfo(TerminalSessionInfo info) {
    _syncInfo(info);
  }

  /// Attaches the terminal output stream if it is not already active.
  Future<void> attach() async {
    if (_disposed || _closed) {
      throw PtyException('Session is closed', sessionId: id);
    }
    if (_attached) {
      return;
    }

    await _backend.ensureInitialized();
    try {
      final stream = _backend.observeOutput(id);
      _outputSubscription = stream.listen(
        _handleOutput,
        onError: _handleOutputError,
        onDone: _handleOutputDone,
        cancelOnError: false,
      );
      _attached = true;
      _syncInfo(_info.copyWith(attached: true));
    } on Object catch (error, _) {
      throw PtyIOException(
        'Failed to attach terminal output',
        sessionId: id,
        cause: error,
      );
    }
  }

  /// Refreshes the snapshot from the backend.
  Future<TerminalSessionInfo> refresh() async {
    if (_disposed) {
      throw PtyException('Session has been disposed', sessionId: id);
    }
    final info = await _backend.sessionInfo(id);
    _syncInfo(info);
    return info;
  }

  /// Write string data to the PTY.
  Future<int> write(String data) =>
      writeBytes(Uint8List.fromList(utf8.encode(data)));

  /// Write binary data to the PTY.
  Future<int> writeBytes(Uint8List data) async {
    _ensureWritable();
    try {
      final written = await _backend.writeInput(id, data);
      _syncInfo(
        _info.copyWith(
          lastActivityAt: DateTime.now(),
          attached: true,
          status: TerminalStatus.running,
        ),
      );
      return written;
    } on Object catch (error, _) {
      throw PtyIOException(
        'Failed to write to session',
        sessionId: id,
        cause: error,
      );
    }
  }

  /// Resize the terminal.
  Future<void> resize(int rows, int cols) async {
    _ensureWritable();
    try {
      await _backend.resizeSession(id, PtySize(rows: rows, cols: cols));
      _syncInfo(
        _info.copyWith(
          size: PtySize(rows: rows, cols: cols),
          lastActivityAt: DateTime.now(),
        ),
      );
    } on Object catch (error, _) {
      throw PtyResizeException(
        'Failed to resize session',
        sessionId: id,
        cause: error,
      );
    }
  }

  /// Returns the current terminal size.
  Future<PtySize> getSize() async {
    final updated = await refresh();
    return updated.size;
  }

  /// Send a signal to the process.
  Future<void> sendSignal(PtySignal signal) async {
    _ensureWritable();
    try {
      await _backend.sendSignal(id, signal);
      _syncInfo(_info.copyWith(lastActivityAt: DateTime.now()));
    } on Object catch (error, _) {
      throw SignalSendException(
        'Failed to send ${signal.signalName}',
        sessionId: id,
        cause: error,
      );
    }
  }

  /// Wait for the process to exit.
  Future<int> waitForExit() async {
    if (_info.exitCode != null) {
      return _info.exitCode!;
    }
    try {
      final exitCode = await _backend.waitForExit(id);
      _syncInfo(
        _info.copyWith(
          exitCode: exitCode,
          status: TerminalStatus.exited,
          lastActivityAt: DateTime.now(),
        ),
      );
      return exitCode;
    } on Object catch (error, _) {
      throw PtyException(
        'Failed to wait for exit',
        sessionId: id,
        cause: error,
      );
    }
  }

  /// Close the session and release native resources.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _attached = false;

    await _outputSubscription?.cancel();
    _outputSubscription = null;
    _closeTranscriber();
    if (!_outputController.isClosed) {
      await _outputController.close();
    }

    try {
      await _backend.closeSession(id);
    } on Object catch (error, _) {
      _syncInfo(
        _info.copyWith(
          status: TerminalStatus.closed,
          attached: false,
          lastActivityAt: DateTime.now(),
        ),
      );
      _onClosed?.call();
      throw PtyException(
        'Failed to close session',
        sessionId: id,
        cause: error,
      );
    }

    _syncInfo(
      _info.copyWith(
        status: TerminalStatus.closed,
        attached: false,
        lastActivityAt: DateTime.now(),
      ),
    );
    _onClosed?.call();
  }

  /// Releases local resources without closing the backend session.
  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final subscription = _outputSubscription;
    _outputSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    _closeTranscriber();
    if (!_outputController.isClosed) {
      _outputController.close();
    }
    super.dispose();
  }

  void _ensureWritable() {
    if (_disposed) {
      throw PtyException('Session has been disposed', sessionId: id);
    }
    if (_closed) {
      throw PtyException('Session is closed', sessionId: id);
    }
    if (!_info.canSendInput) {
      throw PtyException('Session is not ready for input', sessionId: id);
    }
  }

  void _handleOutput(Uint8List data) {
    if (_disposed || _closed) {
      return;
    }
    _transcriptSink.add(data);
    _outputController.add(data);
    _syncInfo(
      _info.copyWith(
        lastActivityAt: DateTime.now(),
        status: TerminalStatus.running,
        attached: true,
      ),
    );
  }

  void _handleOutputError(Object error, StackTrace stackTrace) {
    if (_disposed || _closed) {
      return;
    }
    _syncInfo(
      _info.copyWith(
        status: TerminalStatus.failed,
        lastActivityAt: DateTime.now(),
      ),
    );
    if (!_outputController.isClosed) {
      _outputController.addError(error, stackTrace);
    }
    notifyListeners();
  }

  void _handleOutputDone() {
    if (_disposed) {
      return;
    }
    _attached = false;
    _closeTranscriber();
    if (!_outputController.isClosed) {
      _outputController.close();
    }
    if (_closed) {
      notifyListeners();
      return;
    }

    unawaited(_refreshAfterOutputDone());
  }

  Future<void> _refreshAfterOutputDone() async {
    try {
      await refresh();
    } on Object {
      _syncInfo(
        _info.copyWith(
          status: TerminalStatus.exited,
          lastActivityAt: DateTime.now(),
          attached: false,
        ),
      );
    }
    notifyListeners();
  }

  void _syncInfo(TerminalSessionInfo info) {
    _info = info;
    notifyListeners();
  }

  void _closeTranscriber() {
    try {
      _transcriptSink.close();
    } on Object {
      // The sink is best-effort; it can already be closed when output ends.
    }
  }
}
