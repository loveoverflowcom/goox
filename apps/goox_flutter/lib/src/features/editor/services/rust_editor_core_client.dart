import 'package:flutter/foundation.dart';
import '../models/editor_models.dart';
import 'editor_core_client.dart';
import 'rust_core_bridge/api.dart' as rust;
import 'rust_core_bridge/lib.dart' as rust_lib;

class RustEditorCoreClient implements EditorCoreClient {
  RustEditorCoreClient() : _state = ValueNotifier(EditorViewState.empty()) {
    _initialize();
  }

  static const int _visibleLineCount = 14;
  final ValueNotifier<EditorViewState> _state;
  final List<String> _eventLog = [];

  int _cursorOffset = 0;
  int _firstVisibleLine = 0;

  @override
  ValueListenable<EditorViewState> get listenable => _state;

  Future<void> _initialize() async {
    await rust.seedDocument(text: '');
    await _publish(lastCommand: 'init');
  }

  @override
  Future<void> seedDocument() async {
    const seedText =
        'Goox is now powered by Rust via flutter_rust_bridge!\n'
        'Performance-heavy tasks like text manipulation and viewport calculation happen in Rust.\n'
        'The UI remains smooth while handling large documents.\n';
    await rust.seedDocument(text: seedText);
    _cursorOffset = seedText.length;
    _firstVisibleLine = 0;
    _recordEvent('Rust core seeded');
    await _publish(lastCommand: 'seed sample');
  }

  @override
  Future<void> loadLargeDocument() async {
    final buffer = StringBuffer();
    for (var index = 1; index <= 1000; index++) {
      buffer.writeln(
        'Line $index: Rust handles this long document with ease.',
      );
    }
    await rust.seedDocument(text: buffer.toString());
    _cursorOffset = buffer.length;
    _firstVisibleLine = 0;
    _recordEvent('Rust core loaded 1000 lines');
    await _publish(lastCommand: 'load 1000 lines');
  }

  @override
  Future<void> loadDocument(String text) async {
    await rust.seedDocument(text: text);
    _cursorOffset = 0;
    _firstVisibleLine = 0;
    _recordEvent('Rust core loaded document');
    await _publish(lastCommand: 'load document');
  }

  @override
  Future<String> getDocumentText() async {
    final snapshot = await rust.getSnapshot();
    if (snapshot.lineCount == BigInt.zero) return '';
    final viewportReq = rust_lib.ViewportRequest(
      firstLine: BigInt.zero,
      maxLines: snapshot.lineCount,
    );
    final viewport = await rust.getViewport(request: viewportReq);
    return viewport.lines.map((l) => l.text).join('\n');
  }

  @override
  Future<void> insertText(String text) async {
    if (text.isEmpty) return;

    final transaction = rust_lib.BufferTransaction(
      operations: [
        rust_lib.BufferOperation.insert(
          charIndex: BigInt.from(_cursorOffset),
          text: text,
        ),
      ],
      mergeable: true,
      label: 'insert',
    );

    try {
      final batch = await rust.applyTransaction(transaction: transaction);
      _cursorOffset += text.length;
      _normalizeViewport(await _getCursorPosition());
      _recordEvent('Rust applied insert -> revision ${batch.revision}');
      await _publish(
        lastCommand: 'insert text',
        lastPatches: batch.patches.map(_mapPatch).toList(),
      );
    } catch (e) {
      _recordEvent('Error: $e');
    }
  }

  @override
  Future<void> insertBurst() async {
    final firstText = 'Patch batching avoids bridge chatter.\n';
    final secondText = 'Workers stay off the input path.\n';
    final firstOffset = _cursorOffset;

    final transaction = rust_lib.BufferTransaction(
      operations: [
        rust_lib.BufferOperation.insert(
          charIndex: BigInt.from(firstOffset),
          text: firstText,
        ),
        rust_lib.BufferOperation.insert(
          charIndex: BigInt.from(firstOffset + firstText.length),
          text: secondText,
        ),
      ],
      mergeable: false,
      label: 'burst',
    );

    try {
      final batch = await rust.applyTransaction(transaction: transaction);
      _cursorOffset += firstText.length + secondText.length;
      _normalizeViewport(await _getCursorPosition());
      _recordEvent('Rust applied burst -> revision ${batch.revision}');
      await _publish(
        lastCommand: 'insert burst',
        lastPatches: batch.patches.map(_mapPatch).toList(),
      );
    } catch (e) {
      _recordEvent('Error: $e');
    }
  }

  @override
  Future<void> insertNewline() => insertText('\n');

  @override
  Future<void> backspace() async {
    if (_cursorOffset == 0) return;

    final transaction = rust_lib.BufferTransaction(
      operations: [
        rust_lib.BufferOperation.delete(
          start: BigInt.from(_cursorOffset - 1),
          end: BigInt.from(_cursorOffset),
        ),
      ],
      mergeable: true,
      label: 'backspace',
    );

    try {
      final batch = await rust.applyTransaction(transaction: transaction);
      _cursorOffset -= 1;
      _normalizeViewport(await _getCursorPosition());
      _recordEvent('Rust applied backspace -> revision ${batch.revision}');
      await _publish(
        lastCommand: 'backspace',
        lastPatches: batch.patches.map(_mapPatch).toList(),
      );
    } catch (e) {
      _recordEvent('Error: $e');
    }
  }

  @override
  Future<void> deleteCurrentLine() async {
    try {
      final batch = await rust.deleteLine(charIndex: BigInt.from(_cursorOffset));
      _cursorOffset = batch.patches.fold<int>(_cursorOffset, (offset, op) {
        return op.when(
          insert: (charIndex, text) => offset + text.length,
          delete: (start, end) => start.toInt(),
        );
      });
      _normalizeViewport(await _getCursorPosition());
      _recordEvent('Rust applied delete line -> revision ${batch.revision}');
      await _publish(
        lastCommand: 'delete line',
        lastPatches: batch.patches.map(_mapPatch).toList(),
      );
    } catch (e) {
      _recordEvent('Error: $e');
    }
  }

  @override
  Future<void> moveViewport(int lineDelta) async {
    final snapshot = await rust.getSnapshot();
    final totalLines = snapshot.lineCount.toInt();
    final maxLine = totalLines > 0 ? totalLines - 1 : 0;
    _firstVisibleLine = (_firstVisibleLine + lineDelta).clamp(0, maxLine);
    await _publish(lastCommand: lineDelta > 0 ? 'scroll down' : 'scroll up');
  }

  @override
  Future<void> moveCursorRelative(int charDelta) async {
    final snapshot = await rust.getSnapshot();
    _cursorOffset = (_cursorOffset + charDelta).clamp(0, snapshot.charCount.toInt());
    _normalizeViewport(await _getCursorPosition());
    await _publish(lastCommand: 'move cursor');
  }

  @override
  Future<void> moveCursorToPosition(int line, int column) async {
    final snapshot = await rust.getSnapshot();
    final clampedLine = line.clamp(1, snapshot.lineCount.toInt());
    
    // Fetch all lines up to clampedLine to calculate charIndex.
    final req = rust_lib.ViewportRequest(firstLine: BigInt.zero, maxLines: BigInt.from(clampedLine));
    final viewport = await rust.getViewport(request: req);
    
    int newOffset = 0;
    for (int i = 0; i < clampedLine - 1; i++) {
       if (i < viewport.lines.length) {
         final lineText = viewport.lines[i].text;
         // Note: For some platforms, newline isn't just +1 char, but assuming standard '\n' (+1).
         newOffset += lineText.length + 1;
       }
    }
    
    // Add column
    final targetLineText = (clampedLine - 1 < viewport.lines.length) ? viewport.lines[clampedLine - 1].text : '';
    int col = column.clamp(1, targetLineText.length + 1);
    newOffset += (col - 1);
    
    _cursorOffset = newOffset.clamp(0, snapshot.charCount.toInt());
    _normalizeViewport(await _getCursorPosition());
    await _publish(lastCommand: 'move cursor pos');
  }

  @override
  Future<void> undo() async {
    try {
      final batch = await rust.undo();
      // Update cursor offset based on patches
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
        lastPatches: batch.patches.map(_mapPatch).toList(),
      );
    } catch (e) {
      _recordEvent('No undo available');
    }
  }

  @override
  Future<void> redo() async {
    try {
      final batch = await rust.redo();
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
        lastPatches: batch.patches.map(_mapPatch).toList(),
      );
    } catch (e) {
      _recordEvent('No redo available');
    }
  }

  @override
  void dispose() => _state.dispose();

  Future<void> _publish({
    required String lastCommand,
    List<EditorPatch> lastPatches = const [],
  }) async {
    final viewportReq = rust_lib.ViewportRequest(
      firstLine: BigInt.from(_firstVisibleLine),
      maxLines: BigInt.from(_visibleLineCount),
    );
    final viewport = await rust.getViewport(request: viewportReq);
    final snapshot = await rust.getSnapshot();
    final cursor = await _getCursorPosition();

    _state.value = EditorViewState(
      revision: snapshot.revision.toInt(),
      totalChars: snapshot.charCount.toInt(),
      totalLines: snapshot.lineCount.toInt(),
      firstVisibleLine: _firstVisibleLine,
      visibleLines: viewport.lines
          .map(
            (l) => ViewportLine(
              lineNumber: l.lineIndex.toInt() + 1,
              text: l.text,
            ),
          )
          .toList(),
      cursorOffset: _cursorOffset,
      cursor: cursor,
      lastPatches: lastPatches,
      eventLog: List.unmodifiable(_eventLog.reversed.take(6)),
      hasUndo: true, // Simplified
      hasRedo: true, // Simplified
      lastCommand: lastCommand,
    );
  }

  Future<CursorPosition> _getCursorPosition() async {
    final pos = await rust.getCursorPosition(charIndex: BigInt.from(_cursorOffset));
    return CursorPosition(line: pos.line.toInt(), column: pos.column.toInt());
  }

  void _recordEvent(String event) {
    _eventLog.add(event);
    if (_eventLog.length > 32) _eventLog.removeAt(0);
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

  EditorPatch _mapPatch(rust_lib.BufferOperation op) {
    return op.when(
      insert: (charIndex, text) => EditorPatch.insert(
        start: charIndex.toInt(),
        text: text,
      ),
      delete: (start, end) => EditorPatch.delete(
        start: start.toInt(),
        end: end.toInt(),
      ),
    );
  }
}
