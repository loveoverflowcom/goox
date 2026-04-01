import 'package:flutter/foundation.dart';

import '../models/editor_models.dart';
import '../services/editor_core_client.dart';
import '../services/rust_editor_core_client.dart';

class GooxEditorController {
  GooxEditorController({EditorCoreClient? coreClient})
    : _coreClient = coreClient ?? RustEditorCoreClient();

  final EditorCoreClient _coreClient;

  ValueListenable<EditorViewState> get stateListenable =>
      _coreClient.listenable;

  Future<void> seedDocument() => _coreClient.seedDocument();

  Future<void> setActiveExtension(ActiveExtensionInfo? extension) =>
      _coreClient.setActiveExtension(extension);

  Future<void> loadDocument(
    String text, {
    String? filePath,
    String? workspaceRoot,
  }) => _coreClient.loadDocument(
    text,
    filePath: filePath,
    workspaceRoot: workspaceRoot,
  );

  Future<String> getDocumentText() => _coreClient.getDocumentText();

  Future<void> loadLargeDocument() => _coreClient.loadLargeDocument();

  Future<void> insertText(String text) => _coreClient.insertText(text);

  Future<void> insertBurst() => _coreClient.insertBurst();

  Future<void> insertNewline() => _coreClient.insertNewline();

  Future<void> backspace() => _coreClient.backspace();

  Future<void> deleteCurrentLine() => _coreClient.deleteCurrentLine();

  Future<void> moveViewport(int lineDelta) =>
      _coreClient.moveViewport(lineDelta);

  Future<void> moveCursorRelative(int charDelta) =>
      _coreClient.moveCursorRelative(charDelta);

  Future<void> moveCursorToOffset(int offset) =>
      _coreClient.moveCursorToOffset(offset);

  Future<void> moveCursorToPosition(int line, int column) =>
      _coreClient.moveCursorToPosition(line, column);

  Future<void> replaceTextRange(int start, int end, String replacement) =>
      _coreClient.replaceTextRange(start, end, replacement);

  Future<void> undo() => _coreClient.undo();

  Future<void> redo() => _coreClient.redo();

  Future<List<LanguageServerLocation>> lspFindDefinitions({int? charIndex}) =>
      _coreClient.lspFindDefinitions(charIndex: charIndex);

  Future<List<LanguageServerLocation>> lspFindDeclarations({int? charIndex}) =>
      _coreClient.lspFindDeclarations(charIndex: charIndex);

  Future<List<LanguageServerLocation>> lspFindImplementations({
    int? charIndex,
  }) => _coreClient.lspFindImplementations(charIndex: charIndex);

  Future<List<LanguageServerLocation>> lspFindReferences({int? charIndex}) =>
      _coreClient.lspFindReferences(charIndex: charIndex);

  Future<LanguageServerHover?> lspGetHover({int? charIndex}) =>
      _coreClient.lspGetHover(charIndex: charIndex);

  Future<void> requestHover(int offset) => _coreClient.requestHover(offset);

  Future<List<LanguageServerDocumentHighlight>> lspGetDocumentHighlights({
    int? charIndex,
  }) => _coreClient.lspGetDocumentHighlights(charIndex: charIndex);

  void dispose() => _coreClient.dispose();
}
