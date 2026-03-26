import 'package:flutter/foundation.dart';

import '../models/editor_models.dart';

abstract interface class EditorCoreClient {
  ValueListenable<EditorViewState> get listenable;

  Future<void> seedDocument();
  Future<void> loadLargeDocument();
  Future<void> insertText(String text);
  Future<void> insertBurst();
  Future<void> insertNewline();
  Future<void> backspace();
  Future<void> deleteCurrentLine();
  Future<void> moveViewport(int lineDelta);
  Future<void> moveCursorRelative(int charDelta);
  Future<void> moveCursorToPosition(int line, int column);
  Future<void> undo();
  Future<void> redo();
  Future<void> loadDocument(String text);
  Future<String> getDocumentText();
  void dispose();
}
