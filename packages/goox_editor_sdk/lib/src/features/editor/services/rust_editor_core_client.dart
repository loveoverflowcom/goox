import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:goox_flutter_bridge/goox_flutter_bridge.dart' as raw_bridge;

import '../../../data/editor_repository.dart';
import '../models/editor_models.dart';
import 'editor_core_client.dart';

class RustEditorCoreClient implements EditorCoreClient {
  RustEditorCoreClient({GooxEditorRepository? repository})
    : _repository = repository ?? GooxEditorRepository(),
      _state = ValueNotifier(EditorViewState.empty()) {
    _initialize();
  }

  static const int _visibleLineCount = 14;

  final GooxEditorRepository _repository;
  final ValueNotifier<EditorViewState> _state;
  final List<String> _eventLog = [];

  ActiveExtensionInfo? _activeExtension;
  String? _workspaceRoot;
  String? _currentFilePath;
  Timer? _lspPollTimer;

  int _cursorOffset = 0;
  int _firstVisibleLine = 0;

  @override
  ValueListenable<EditorViewState> get listenable => _state;

  Future<void> _initialize() async {
    await _repository.seedDocument(text: '');
    await _publish(lastCommand: 'init');
  }

  @override
  Future<void> seedDocument() async {
    const seedText =
        'Goox is now powered by Rust via flutter_rust_bridge!\n'
        'Performance-heavy tasks like text manipulation and viewport calculation happen in Rust.\n'
        'The UI remains smooth while handling large documents.\n';
    await _repository.seedDocument(text: seedText);
    _workspaceRoot = null;
    _currentFilePath = null;
    _cursorOffset = seedText.length;
    _firstVisibleLine = 0;
    _recordEvent('Rust core seeded');
    await _publish(lastCommand: 'seed sample');
  }

  @override
  Future<void> setActiveExtension(ActiveExtensionInfo? extension) async {
    _activeExtension = extension;
    _updateLanguageServerPolling();

    // Clear stale diagnostics when the active extension changes.
    _state.value = _state.value.copyWith(
      lspStatus: 'inactive',
      lspDiagnostics: [],
      activeExtension: extension,
    );

    if (_currentFilePath == null) {
      return;
    }

    await _publish(lastCommand: 'set active extension');
  }

  @override
  Future<void> loadLargeDocument() async {
    final buffer = StringBuffer();
    for (var index = 1; index <= 1000; index++) {
      buffer.writeln('Line $index: Rust handles this long document with ease.');
    }

    await _repository.seedDocument(text: buffer.toString());
    _workspaceRoot = null;
    _currentFilePath = null;
    _cursorOffset = buffer.length;
    _firstVisibleLine = 0;
    _recordEvent('Rust core loaded 1000 lines');
    await _publish(lastCommand: 'load 1000 lines');
  }

  @override
  Future<void> loadDocument(
    String text, {
    String? filePath,
    String? workspaceRoot,
  }) async {
    await _repository.seedDocument(text: text);
    _currentFilePath = filePath;
    _workspaceRoot = workspaceRoot;
    _cursorOffset = 0;
    _firstVisibleLine = 0;
    _recordEvent('Rust core loaded document');

    // Clear stale diagnostics immediately so they don't bleed into the new file.
    _state.value = _state.value.copyWith(
      lspStatus: 'inactive',
      lspDiagnostics: [],
    );

    _updateLanguageServerPolling();
    await _publish(lastCommand: 'load document');
  }

  @override
  Future<String> getDocumentText() async {
    final snapshot = await _repository.getSnapshot();
    if (snapshot.lineCount == BigInt.zero) {
      return '';
    }

    final viewport = await _repository.getViewport(
      request: raw_bridge.ViewportRequest(
        firstLine: BigInt.zero,
        maxLines: snapshot.lineCount,
      ),
    );

    return viewport.lines.map((line) => line.text).join('\n');
  }

  @override
  Future<void> insertText(String text) async {
    if (text.isEmpty) {
      return;
    }

    final transaction = raw_bridge.BufferTransaction(
      operations: [
        raw_bridge.BufferOperation.insert(
          charIndex: BigInt.from(_cursorOffset),
          text: text,
        ),
      ],
      mergeable: true,
      label: 'insert',
    );

    try {
      final batch = await _repository.applyTransaction(
        transaction: transaction,
      );
      _cursorOffset += text.length;
      _normalizeViewport(await _getCursorPosition());
      _recordEvent('Rust applied insert -> revision ${batch.revision}');
      await _publish(
        lastCommand: 'insert text',
        lastPatches: batch.patches.map(_mapPatch).toList(growable: false),
      );
    } catch (error) {
      _recordEvent('Error: $error');
    }
  }

  @override
  Future<void> insertBurst() async {
    final firstText = 'Patch batching avoids bridge chatter.\n';
    final secondText = 'Workers stay off the input path.\n';
    final firstOffset = _cursorOffset;

    final transaction = raw_bridge.BufferTransaction(
      operations: [
        raw_bridge.BufferOperation.insert(
          charIndex: BigInt.from(firstOffset),
          text: firstText,
        ),
        raw_bridge.BufferOperation.insert(
          charIndex: BigInt.from(firstOffset + firstText.length),
          text: secondText,
        ),
      ],
      mergeable: false,
      label: 'burst',
    );

    try {
      final batch = await _repository.applyTransaction(
        transaction: transaction,
      );
      _cursorOffset += firstText.length + secondText.length;
      _normalizeViewport(await _getCursorPosition());
      _recordEvent('Rust applied burst -> revision ${batch.revision}');
      await _publish(
        lastCommand: 'insert burst',
        lastPatches: batch.patches.map(_mapPatch).toList(growable: false),
      );
    } catch (error) {
      _recordEvent('Error: $error');
    }
  }

  @override
  Future<void> insertNewline() => insertText('\n');

  @override
  Future<void> backspace() async {
    if (_cursorOffset == 0) {
      return;
    }

    final transaction = raw_bridge.BufferTransaction(
      operations: [
        raw_bridge.BufferOperation.delete(
          start: BigInt.from(_cursorOffset - 1),
          end: BigInt.from(_cursorOffset),
        ),
      ],
      mergeable: true,
      label: 'backspace',
    );

    try {
      final batch = await _repository.applyTransaction(
        transaction: transaction,
      );
      _cursorOffset -= 1;
      _normalizeViewport(await _getCursorPosition());
      _recordEvent('Rust applied backspace -> revision ${batch.revision}');
      await _publish(
        lastCommand: 'backspace',
        lastPatches: batch.patches.map(_mapPatch).toList(growable: false),
      );
    } catch (error) {
      _recordEvent('Error: $error');
    }
  }

  @override
  Future<void> deleteCurrentLine() async {
    try {
      final batch = await _repository.deleteLine(
        charIndex: BigInt.from(_cursorOffset),
      );
      _cursorOffset = batch.patches.fold<int>(_cursorOffset, (
        offset,
        operation,
      ) {
        return operation.when(
          insert: (charIndex, text) => offset + text.length,
          delete: (start, end) => start.toInt(),
        );
      });
      _normalizeViewport(await _getCursorPosition());
      _recordEvent('Rust applied delete line -> revision ${batch.revision}');
      await _publish(
        lastCommand: 'delete line',
        lastPatches: batch.patches.map(_mapPatch).toList(growable: false),
      );
    } catch (error) {
      _recordEvent('Error: $error');
    }
  }

  @override
  Future<void> moveViewport(int lineDelta) async {
    final snapshot = await _repository.getSnapshot();
    final totalLines = snapshot.lineCount.toInt();
    final maxLine = totalLines > 0 ? totalLines - 1 : 0;
    _firstVisibleLine = (_firstVisibleLine + lineDelta)
        .clamp(0, maxLine)
        .toInt();
    await _publish(lastCommand: lineDelta > 0 ? 'scroll down' : 'scroll up');
  }

  @override
  Future<void> moveCursorRelative(int charDelta) async {
    final snapshot = await _repository.getSnapshot();
    _cursorOffset = (_cursorOffset + charDelta)
        .clamp(0, snapshot.charCount.toInt())
        .toInt();
    _normalizeViewport(await _getCursorPosition());
    await _publish(lastCommand: 'move cursor');
  }

  @override
  Future<void> moveCursorToOffset(int offset) async {
    final snapshot = await _repository.getSnapshot();
    _cursorOffset = offset.clamp(0, snapshot.charCount.toInt()).toInt();
    _normalizeViewport(await _getCursorPosition());
    await _publish(lastCommand: 'move cursor offset');
  }

  @override
  Future<void> moveCursorToPosition(int line, int column) async {
    final snapshot = await _repository.getSnapshot();
    final clampedLine = line.clamp(1, snapshot.lineCount.toInt()).toInt();
    final viewport = await _repository.getViewport(
      request: raw_bridge.ViewportRequest(
        firstLine: BigInt.zero,
        maxLines: BigInt.from(clampedLine),
      ),
    );

    var newOffset = 0;
    for (var index = 0; index < clampedLine - 1; index++) {
      if (index >= viewport.lines.length) {
        break;
      }

      newOffset += viewport.lines[index].text.length + 1;
    }

    final targetLineText = clampedLine - 1 < viewport.lines.length
        ? viewport.lines[clampedLine - 1].text
        : '';
    final clampedColumn = column.clamp(1, targetLineText.length + 1).toInt();
    newOffset += clampedColumn - 1;

    _cursorOffset = newOffset.clamp(0, snapshot.charCount.toInt()).toInt();
    _normalizeViewport(await _getCursorPosition());
    await _publish(lastCommand: 'move cursor pos');
  }

  @override
  Future<void> replaceTextRange(int start, int end, String replacement) async {
    final snapshot = await _repository.getSnapshot();
    final maxOffset = snapshot.charCount.toInt();
    final clampedStart = start.clamp(0, maxOffset).toInt();
    final clampedEnd = end.clamp(clampedStart, maxOffset).toInt();

    if (clampedStart == clampedEnd && replacement.isEmpty) {
      return;
    }

    final operations = <raw_bridge.BufferOperation>[
      if (clampedEnd > clampedStart)
        raw_bridge.BufferOperation.delete(
          start: BigInt.from(clampedStart),
          end: BigInt.from(clampedEnd),
        ),
      if (replacement.isNotEmpty)
        raw_bridge.BufferOperation.insert(
          charIndex: BigInt.from(clampedStart),
          text: replacement,
        ),
    ];

    final transaction = raw_bridge.BufferTransaction(
      operations: operations,
      mergeable: true,
      label: 'replace-range',
    );

    try {
      final batch = await _repository.applyTransaction(
        transaction: transaction,
      );
      _cursorOffset = clampedStart + replacement.length;
      _normalizeViewport(await _getCursorPosition());
      _recordEvent('Rust replaced range -> revision ${batch.revision}');
      await _publish(
        lastCommand: 'replace range',
        lastPatches: batch.patches.map(_mapPatch).toList(growable: false),
      );
    } catch (error) {
      _recordEvent('Error: $error');
    }
  }

  @override
  Future<void> undo() async {
    try {
      final batch = await _repository.undo();
      for (final patch in batch.patches) {
        patch.when(
          insert: (charIndex, text) => _cursorOffset += text.length,
          delete: (start, end) => _cursorOffset = start.toInt(),
        );
      }

      _normalizeViewport(await _getCursorPosition());
      _recordEvent('Rust undo -> revision ${batch.revision}');
      await _publish(
        lastCommand: 'undo',
        lastPatches: batch.patches.map(_mapPatch).toList(growable: false),
      );
    } catch (_) {
      _recordEvent('No undo available');
    }
  }

  @override
  Future<void> redo() async {
    try {
      final batch = await _repository.redo();
      for (final patch in batch.patches) {
        patch.when(
          insert: (charIndex, text) => _cursorOffset += text.length,
          delete: (start, end) => _cursorOffset = start.toInt(),
        );
      }

      _normalizeViewport(await _getCursorPosition());
      _recordEvent('Rust redo -> revision ${batch.revision}');
      await _publish(
        lastCommand: 'redo',
        lastPatches: batch.patches.map(_mapPatch).toList(growable: false),
      );
    } catch (_) {
      _recordEvent('No redo available');
    }
  }

  Future<CursorPosition> _getCursorPosition() async {
    final cursor = await _repository.getCursorPosition(
      charIndex: BigInt.from(_cursorOffset),
    );

    return CursorPosition(
      line: cursor.line.toInt(),
      column: cursor.column.toInt(),
    );
  }

  void _normalizeViewport(CursorPosition cursor) {
    final cursorLineIndex = cursor.line - 1;
    if (cursorLineIndex < _firstVisibleLine) {
      _firstVisibleLine = cursorLineIndex;
      return;
    }

    final lastVisibleLine = _firstVisibleLine + _visibleLineCount - 1;
    if (cursorLineIndex > lastVisibleLine) {
      _firstVisibleLine = cursorLineIndex - (_visibleLineCount - 1);
    }
  }

  Future<void> _publish({
    required String lastCommand,
    List<EditorPatch> lastPatches = const [],
  }) async {
    final snapshot = await _repository.getSnapshot();
    final viewport = await _repository.getViewport(
      request: raw_bridge.ViewportRequest(
        firstLine: BigInt.from(_firstVisibleLine),
        maxLines: BigInt.from(_visibleLineCount),
      ),
    );
    final cursor = await _getCursorPosition();
    final documentText = await getDocumentText();

    await _syncLanguageServer(documentText);
    final lspSnapshot = await _refreshLanguageServerSnapshot();

    _state.value = EditorViewState(
      revision: snapshot.revision.toInt(),
      totalChars: snapshot.charCount.toInt(),
      totalLines: snapshot.lineCount.toInt(),
      documentText: documentText,
      firstVisibleLine: viewport.firstVisibleLine.toInt(),
      visibleLines: viewport.lines
          .map(
            (line) => ViewportLine(
              lineNumber: line.lineIndex.toInt() + 1,
              text: line.text,
            ),
          )
          .toList(growable: false),
      cursorOffset: _cursorOffset,
      cursor: cursor,
      lastPatches: lastPatches,
      eventLog: List.unmodifiable(_eventLog.reversed.take(6)),
      hasUndo: true,
      hasRedo: true,
      lastCommand: lastCommand,
      activeExtension: _activeExtension,
      lspStatus: lspSnapshot.status,
      lspDiagnostics: lspSnapshot.diagnostics
          .map(_diagnosticFromBridge)
          .toList(growable: false),
    );
  }

  void _recordEvent(String event) {
    _eventLog.add(event);
    if (_eventLog.length > 32) {
      _eventLog.removeAt(0);
    }
  }

  EditorPatch _mapPatch(raw_bridge.BufferOperation operation) => operation.when(
    insert: (charIndex, text) =>
        EditorPatch.insert(start: charIndex.toInt(), text: text),
    delete: (start, end) =>
        EditorPatch.delete(start: start.toInt(), end: end.toInt()),
  );

  LspDiagnostic _diagnosticFromBridge(
    raw_bridge.LanguageServerDiagnostic diagnostic,
  ) {
    return LspDiagnostic(
      message: diagnostic.message,
      startLine: diagnostic.range.startLine,
      startColumn: diagnostic.range.startCharacter,
      endLine: diagnostic.range.endLine,
      endColumn: diagnostic.range.endCharacter,
      severity: diagnostic.severity,
      source: diagnostic.source,
    );
  }

  bool get _canUseLanguageServer {
    final extension = _activeExtension;
    return _currentFilePath != null &&
        extension != null &&
        (extension.lspExecutable?.trim().isNotEmpty ?? false);
  }

  void _updateLanguageServerPolling() {
    final shouldPoll = _canUseLanguageServer;
    if (shouldPoll && _lspPollTimer == null) {
      _lspPollTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => unawaited(_refreshLanguageServerSnapshot(applyState: true)),
      );
      return;
    }

    if (!shouldPoll) {
      _lspPollTimer?.cancel();
      _lspPollTimer = null;
    }
  }

  Future<void> _syncLanguageServer(String text) async {
    final extension = _activeExtension;
    final shouldSync = _canUseLanguageServer;

    if (!shouldSync) {
      return;
    }

    try {
      await _repository.syncLanguageServer(
        workspaceRoot: _workspaceRoot,
        filePath: _currentFilePath,
        languageId: extension?.languageId,
        lspExecutable: extension?.lspExecutable,
        text: text,
      );
    } catch (error) {
      _recordEvent('LSP sync failed: $error');
    }

    _updateLanguageServerPolling();
  }

  Future<raw_bridge.LanguageServerSnapshot> _refreshLanguageServerSnapshot({
    bool applyState = false,
  }) async {
    final snapshot = await _repository.pollLanguageServer();
    if (applyState) {
      _applyLanguageServerSnapshot(snapshot);
    }
    return snapshot;
  }

  void _applyLanguageServerSnapshot(
    raw_bridge.LanguageServerSnapshot snapshot,
  ) {
    final diagnostics = snapshot.diagnostics
        .map(_diagnosticFromBridge)
        .toList(growable: false);
    _state.value = _state.value.copyWith(
      lspStatus: snapshot.status,
      lspDiagnostics: diagnostics,
    );
  }

  @override
  void dispose() {
    _lspPollTimer?.cancel();
    unawaited(_repository.shutdownLanguageServer());
    _state.dispose();
  }
}
