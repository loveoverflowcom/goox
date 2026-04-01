import 'package:flutter/foundation.dart';

import '../models/editor_models.dart';

abstract interface class EditorCoreClient {
  ValueListenable<EditorViewState> get listenable;

  Future<void> seedDocument();
  Future<void> setActiveExtension(ActiveExtensionInfo? extension);
  Future<void> loadLargeDocument();
  Future<void> insertText(String text);
  Future<void> insertBurst();
  Future<void> insertNewline();
  Future<void> backspace();
  Future<void> deleteCurrentLine();
  Future<void> moveViewport(int lineDelta);
  Future<void> moveCursorRelative(int charDelta);
  Future<void> moveCursorToOffset(int offset);
  Future<void> moveCursorToPosition(int line, int column);
  Future<void> replaceTextRange(int start, int end, String replacement);
  Future<void> undo();
  Future<void> redo();
  Future<void> loadDocument(
    String text, {
    String? filePath,
    String? workspaceRoot,
  });
  Future<String> getDocumentText();
  Future<List<LanguageServerLocation>> lspFindDefinitions({int? charIndex});
  Future<List<LanguageServerLocation>> lspFindDeclarations({int? charIndex});
  Future<List<LanguageServerLocation>> lspFindImplementations({int? charIndex});
  Future<List<LanguageServerLocation>> lspFindReferences({int? charIndex});
  Future<LanguageServerHover?> lspGetHover({int? charIndex});
  Future<List<LanguageServerDocumentHighlight>> lspGetDocumentHighlights({
    int? charIndex,
  });

  Future<void> requestHover(int offset);

  void dispose();
}
