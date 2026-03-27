import 'package:flutter/foundation.dart';

enum EditorPatchKind { insert, delete }

@immutable
class EditorPatch {
  const EditorPatch.insert({required this.start, required this.text})
    : kind = EditorPatchKind.insert,
      end = start;

  const EditorPatch.delete({required this.start, required this.end})
    : kind = EditorPatchKind.delete,
      text = '';

  final EditorPatchKind kind;
  final int start;
  final int end;
  final String text;

  String get description => switch (kind) {
    EditorPatchKind.insert =>
      'Insert @ $start "${text.replaceAll('\n', r'\n')}"',
    EditorPatchKind.delete => 'Delete $start..$end',
  };
}

@immutable
class CursorPosition {
  const CursorPosition({required this.line, required this.column});

  final int line;
  final int column;
}

@immutable
class ViewportLine {
  const ViewportLine({required this.lineNumber, required this.text});

  final int lineNumber;
  final String text;
}

@immutable
class ActiveExtensionInfo {
  const ActiveExtensionInfo({
    required this.name,
    required this.path,
    required this.filetypes,
    this.entry,
    this.languageId,
    this.lspExecutable,
  });

  factory ActiveExtensionInfo.empty() =>
      const ActiveExtensionInfo(name: '', path: '', filetypes: []);

  final String name;
  final String path;
  final String? entry;
  final List<String> filetypes;
  final String? languageId;
  final String? lspExecutable;

  bool get hasWasmEntry => entry != null && entry!.trim().isNotEmpty;

  bool get isEmpty => name.isEmpty;
}

@immutable
class EditorViewState {
  const EditorViewState({
    required this.revision,
    required this.totalChars,
    required this.totalLines,
    required this.documentText,
    required this.firstVisibleLine,
    required this.visibleLines,
    required this.cursorOffset,
    required this.cursor,
    required this.lastPatches,
    required this.eventLog,
    required this.hasUndo,
    required this.hasRedo,
    required this.lastCommand,
    required this.activeExtension,
  });

  factory EditorViewState.empty() => const EditorViewState(
    revision: 0,
    totalChars: 0,
    totalLines: 1,
    documentText: '',
    firstVisibleLine: 0,
    visibleLines: [ViewportLine(lineNumber: 1, text: '')],
    cursorOffset: 0,
    cursor: CursorPosition(line: 1, column: 1),
    lastPatches: [],
    eventLog: [],
    hasUndo: false,
    hasRedo: false,
    lastCommand: 'idle',
    activeExtension: null,
  );

  final int revision;
  final int totalChars;
  final int totalLines;
  final String documentText;
  final int firstVisibleLine;
  final List<ViewportLine> visibleLines;
  final int cursorOffset;
  final CursorPosition cursor;
  final List<EditorPatch> lastPatches;
  final List<String> eventLog;
  final bool hasUndo;
  final bool hasRedo;
  final String lastCommand;
  final ActiveExtensionInfo? activeExtension;
}
