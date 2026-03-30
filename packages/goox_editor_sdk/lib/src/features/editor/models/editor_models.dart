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
    required this.rendering,
    this.entry,
    this.languageId,
    this.lspExecutable,
  });

  factory ActiveExtensionInfo.empty() =>
      const ActiveExtensionInfo(
        name: '',
        path: '',
        filetypes: [],
        rendering: false,
      );

  final String name;
  final String path;
  final String? entry;
  final List<String> filetypes;
  final bool rendering;
  final String? languageId;
  final String? lspExecutable;

  bool get hasWasmEntry => entry != null && entry!.trim().isNotEmpty;
  bool get hasErpCapability => rendering && hasWasmEntry;

  bool get isEmpty => name.isEmpty;
}

@immutable
class LspDiagnostic {
  const LspDiagnostic({
    required this.message,
    required this.startLine,
    required this.startColumn,
    required this.endLine,
    required this.endColumn,
    this.severity,
    this.source,
  });

  final String message;
  final int startLine;
  final int startColumn;
  final int endLine;
  final int endColumn;
  final int? severity;
  final String? source;

  String get location =>
      'L${startLine + 1}:${startColumn + 1}-L${endLine + 1}:${endColumn + 1}';
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
    required this.lspStatus,
    required this.lspDiagnostics,
  });

  EditorViewState copyWith({
    int? revision,
    int? totalChars,
    int? totalLines,
    String? documentText,
    int? firstVisibleLine,
    List<ViewportLine>? visibleLines,
    int? cursorOffset,
    CursorPosition? cursor,
    List<EditorPatch>? lastPatches,
    List<String>? eventLog,
    bool? hasUndo,
    bool? hasRedo,
    String? lastCommand,
    ActiveExtensionInfo? activeExtension,
    String? lspStatus,
    List<LspDiagnostic>? lspDiagnostics,
  }) {
    return EditorViewState(
      revision: revision ?? this.revision,
      totalChars: totalChars ?? this.totalChars,
      totalLines: totalLines ?? this.totalLines,
      documentText: documentText ?? this.documentText,
      firstVisibleLine: firstVisibleLine ?? this.firstVisibleLine,
      visibleLines: visibleLines ?? this.visibleLines,
      cursorOffset: cursorOffset ?? this.cursorOffset,
      cursor: cursor ?? this.cursor,
      lastPatches: lastPatches ?? this.lastPatches,
      eventLog: eventLog ?? this.eventLog,
      hasUndo: hasUndo ?? this.hasUndo,
      hasRedo: hasRedo ?? this.hasRedo,
      lastCommand: lastCommand ?? this.lastCommand,
      activeExtension: activeExtension ?? this.activeExtension,
      lspStatus: lspStatus ?? this.lspStatus,
      lspDiagnostics: lspDiagnostics ?? this.lspDiagnostics,
    );
  }

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
    lspStatus: 'inactive',
    lspDiagnostics: [],
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
  final String lspStatus;
  final List<LspDiagnostic> lspDiagnostics;
}
