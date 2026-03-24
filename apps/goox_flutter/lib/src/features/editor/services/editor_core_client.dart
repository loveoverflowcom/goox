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
  Future<void> undo();
  Future<void> redo();
  void dispose();
}
