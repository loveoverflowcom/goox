import 'package:flutter/foundation.dart';

import '../models/editor_models.dart';
import '../services/editor_core_client.dart';

class EditorDemoController {
  EditorDemoController({EditorCoreClient? coreClient})
    : _coreClient = coreClient ?? LocalEditorCoreClient();

  final EditorCoreClient _coreClient;

  ValueListenable<EditorViewState> get stateListenable =>
      _coreClient.listenable;

  Future<void> seedDocument() => _coreClient.seedDocument();

  Future<void> loadLargeDocument() => _coreClient.loadLargeDocument();

  Future<void> insertText(String text) => _coreClient.insertText(text);

  Future<void> insertBurst() => _coreClient.insertBurst();

  Future<void> insertNewline() => _coreClient.insertNewline();

  Future<void> backspace() => _coreClient.backspace();

  Future<void> deleteCurrentLine() => _coreClient.deleteCurrentLine();

  Future<void> moveViewport(int lineDelta) =>
      _coreClient.moveViewport(lineDelta);

  Future<void> undo() => _coreClient.undo();

  Future<void> redo() => _coreClient.redo();

  void dispose() => _coreClient.dispose();
}

final class LocalEditorCoreClient implements EditorCoreClient {
  LocalEditorCoreClient() : _state = ValueNotifier(EditorViewState.empty()) {
    _resetTo(seedText, command: 'bootstrap seed');
  }

  static const int _visibleLineCount = 14;
  static const String seedText =
      'Goox keeps Rust as the single source of truth.\n'
      'Flutter only paints a viewport model and local interaction hints.\n'
      'Patch batches cross the bridge instead of full document snapshots.\n'
      '\n'
      'Try typing into the canvas, press Enter, Backspace, or use Undo.\n'
      'The right-hand panel mirrors ownership, revision flow, and patch history.\n';

  final ValueNotifier<EditorViewState> _state;
  final List<_HistoryEntry> _undoStack = [];
  final List<_HistoryEntry> _redoStack = [];
  final List<String> _eventLog = [];

  String _text = '';
  int _revision = 0;
  int _cursorOffset = 0;
  int _firstVisibleLine = 0;

  @override
  ValueListenable<EditorViewState> get listenable => _state;

  @override
  Future<void> seedDocument() async =>
      _resetTo(seedText, command: 'seed sample');

  @override
  Future<void> loadLargeDocument() async {
    final buffer = StringBuffer();
    for (var index = 1; index <= 120; index++) {
      buffer.writeln(
        'Line $index: viewport-first rendering keeps the Flutter frame budget predictable.',
      );
    }

    _resetTo(buffer.toString(), command: 'load 120 lines');
  }

  @override
  Future<void> insertText(String text) async {
    if (text.isEmpty) {
      return;
    }

    await _apply(
      label: 'insert text',
      forward: [_Operation.insert(offset: _cursorOffset, text: text)],
    );
  }

  @override
  Future<void> insertBurst() async {
    final firstText = 'Patch batching avoids bridge chatter.\n';
    final secondText = 'Workers stay off the input path.\n';
    final firstOffset = _cursorOffset;

    await _apply(
      label: 'insert patch burst',
      forward: [
        _Operation.insert(offset: firstOffset, text: firstText),
        _Operation.insert(
          offset: firstOffset + firstText.length,
          text: secondText,
        ),
      ],
    );
  }

  @override
  Future<void> insertNewline() => insertText('\n');

  @override
  Future<void> backspace() async {
    if (_cursorOffset == 0) {
      return;
    }

    await _apply(
      label: 'backspace',
      forward: [
        _Operation.delete(start: _cursorOffset - 1, end: _cursorOffset),
      ],
    );
  }

  @override
  Future<void> deleteCurrentLine() async {
    final range = _currentLineRange();
    if (range == null) {
      return;
    }

    await _apply(
      label: 'delete line',
      forward: [_Operation.delete(start: range.start, end: range.end)],
    );
  }

  @override
  Future<void> moveViewport(int lineDelta) async {
    final totalLines = _splitLines().length;
    final maxLine = totalLines > 0 ? totalLines - 1 : 0;
    _firstVisibleLine = (_firstVisibleLine + lineDelta).clamp(0, maxLine);
    _publish(lastCommand: lineDelta > 0 ? 'scroll down' : 'scroll up');
  }

  @override
  Future<void> undo() async {
    if (_undoStack.isEmpty) {
      return;
    }

    final entry = _undoStack.removeLast();
    _applyOperations(entry.inverse, trackHistory: false);
    _redoStack.add(entry);
    _revision++;
    _recordEvent('Undo -> revision $_revision');
    _publish(
      lastCommand: 'undo',
      lastPatches: entry.inverse
          .map((operation) => operation.toPatch())
          .toList(),
    );
  }

  @override
  Future<void> redo() async {
    if (_redoStack.isEmpty) {
      return;
    }

    final entry = _redoStack.removeLast();
    _applyOperations(entry.forward, trackHistory: false);
    _undoStack.add(entry);
    _revision++;
    _recordEvent('Redo -> revision $_revision');
    _publish(
      lastCommand: 'redo',
      lastPatches: entry.forward
          .map((operation) => operation.toPatch())
          .toList(),
    );
  }

  @override
  void dispose() => _state.dispose();

  Future<void> _apply({
    required String label,
    required List<_Operation> forward,
  }) async {
    if (forward.isEmpty) {
      return;
    }

    final inverse = _applyOperations(forward, trackHistory: true);
    _undoStack.add(_HistoryEntry(forward: forward, inverse: inverse));
    _redoStack.clear();
    _revision++;
    _recordEvent('Rust core applied "$label" -> revision $_revision');
    _publish(
      lastCommand: label,
      lastPatches: forward.map((operation) => operation.toPatch()).toList(),
    );
  }

  List<_Operation> _applyOperations(
    List<_Operation> operations, {
    required bool trackHistory,
  }) {
    final inverse = <_Operation>[];

    for (final operation in operations) {
      switch (operation.type) {
        case _OperationType.insert:
          final offset = operation.start.clamp(0, _text.length);
          _text = _text.replaceRange(offset, offset, operation.text);
          _cursorOffset = offset + operation.text.length;
          inverse.add(
            _Operation.delete(
              start: offset,
              end: offset + operation.text.length,
            ),
          );
        case _OperationType.delete:
          final start = operation.start.clamp(0, _text.length);
          final end = operation.end.clamp(start, _text.length);
          if (start == end) {
            continue;
          }

          final deleted = _text.substring(start, end);
          _text = _text.replaceRange(start, end, '');
          _cursorOffset = start;
          inverse.add(_Operation.insert(offset: start, text: deleted));
      }
    }

    _normalizeViewport();
    if (!trackHistory) {
      return inverse;
    }

    return inverse.reversed.toList(growable: false);
  }

  void _publish({
    required String lastCommand,
    List<EditorPatch> lastPatches = const [],
  }) {
    final lines = _splitLines();
    final cursor = _cursorPosition(lines);
    final viewportLines = lines
        .skip(_firstVisibleLine)
        .take(_visibleLineCount)
        .indexed
        .map(
          (entry) => ViewportLine(
            lineNumber: _firstVisibleLine + entry.$1 + 1,
            text: entry.$2,
          ),
        )
        .toList(growable: false);

    _state.value = EditorViewState(
      revision: _revision,
      totalChars: _text.length,
      totalLines: lines.length,
      firstVisibleLine: _firstVisibleLine,
      visibleLines: viewportLines,
      cursorOffset: _cursorOffset,
      cursor: cursor,
      lastPatches: lastPatches,
      eventLog: List.unmodifiable(_eventLog.reversed.take(6)),
      hasUndo: _undoStack.isNotEmpty,
      hasRedo: _redoStack.isNotEmpty,
      lastCommand: lastCommand,
    );
  }

  void _recordEvent(String event) {
    _eventLog.add(event);
    if (_eventLog.length > 32) {
      _eventLog.removeAt(0);
    }
  }

  void _resetTo(String text, {required String command}) {
    _text = text;
    _cursorOffset = text.length;
    _revision = 1;
    _firstVisibleLine = 0;
    _undoStack.clear();
    _redoStack.clear();
    _eventLog
      ..clear()
      ..add('Bootstrap -> revision $_revision');
    _publish(lastCommand: command);
  }

  void _normalizeViewport() {
    final lines = _splitLines();
    final cursor = _cursorPosition(lines);
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

  List<String> _splitLines() {
    final lines = _text.split('\n');
    return lines.isEmpty ? [''] : lines;
  }

  CursorPosition _cursorPosition(List<String> lines) {
    var traversed = 0;
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final inclusiveEnd = traversed + line.length;
      if (_cursorOffset <= inclusiveEnd) {
        return CursorPosition(
          line: lineIndex + 1,
          column: (_cursorOffset - traversed) + 1,
        );
      }

      traversed = inclusiveEnd + 1;
    }

    final lastLine = lines.isEmpty ? '' : lines.last;
    return CursorPosition(
      line: lines.isEmpty ? 1 : lines.length,
      column: lastLine.length + 1,
    );
  }

  _LineRange? _currentLineRange() {
    final lines = _splitLines();
    var traversed = 0;

    for (final line in lines) {
      final lineStart = traversed;
      final lineEnd = traversed + line.length;
      final includesNewline = lineEnd < _text.length;

      if (_cursorOffset <= lineEnd || !includesNewline) {
        return _LineRange(
          start: lineStart,
          end: includesNewline ? lineEnd + 1 : lineEnd,
        );
      }

      traversed = lineEnd + 1;
    }

    return null;
  }
}

enum _OperationType { insert, delete }

class _Operation {
  const _Operation.insert({required int offset, required this.text})
    : type = _OperationType.insert,
      start = offset,
      end = offset;

  const _Operation.delete({required this.start, required this.end})
    : type = _OperationType.delete,
      text = '';

  final _OperationType type;
  final int start;
  final int end;
  final String text;

  EditorPatch toPatch() => switch (type) {
    _OperationType.insert => EditorPatch.insert(start: start, text: text),
    _OperationType.delete => EditorPatch.delete(start: start, end: end),
  };
}

class _HistoryEntry {
  const _HistoryEntry({required this.forward, required this.inverse});

  final List<_Operation> forward;
  final List<_Operation> inverse;
}

class _LineRange {
  const _LineRange({required this.start, required this.end});

  final int start;
  final int end;
}
