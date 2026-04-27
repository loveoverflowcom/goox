import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/editor_content/data/models/file_content.dart';
import 'package:goox/features/editor_content/data/repositories/file_repository.dart';
import 'package:goox_editor_engine/goox_editor_engine.dart';

part 'editor_content_event.dart';
part 'editor_content_state.dart';

final class EditorContentBloc
    extends Bloc<EditorContentEvent, EditorContentState> {
  EditorContentBloc({required this.repository})
    : super(const EditorContentState()) {
    on<LoadFileContentEvent>(_onLoadFileContent);
    on<UpdateContentEvent>(_onUpdateContent);
    on<UndoContentEvent>(_onUndoContent);
    on<RedoContentEvent>(_onRedoContent);
    on<UpdateCursorPositionEvent>(_onUpdateCursorPosition);
    on<SaveFileEvent>(_onSaveFile);
    on<CloseContentEvent>(_onCloseContent);
  }
  final FileRepository repository;

  Future<void> _onLoadFileContent(
    LoadFileContentEvent event,
    Emitter<EditorContentState> emit,
  ) async {
    emit(state.copyWith(status: .loading));

    final result = await repository.readFile(event.filePath).run();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: .error,
          errorMessage: failure.message,
        ),
      ),
      (content) => emit(
        state.copyWith(
          content: content,
          originalContent: content.content,
          isModified: false,
          status: .loaded,
        ),
      ),
    );
  }

  void _onUpdateContent(
    UpdateContentEvent event,
    Emitter<EditorContentState> emit,
  ) {
    if (state.fileContent == null) return;

    final fileContent = state.fileContent!;
    final buffer = fileContent.textBuffer;
    final currentText = buffer.getRawText();
    final diff = _calculateDiff(currentText, event.content);

    if (diff.deletedLength > 0) {
      buffer.delete(diff.offset, diff.deletedLength);
    }
    if (diff.insertedText.isNotEmpty) {
      buffer.insert(diff.offset, diff.insertedText);
    }

    final updatedText = buffer.getRawText();

    emit(
      state.copyWith(
        content: fileContent.copyWith(textBuffer: buffer),
        isModified: updatedText != state.originalContent,
      ),
    );
  }

  void _onUndoContent(
    UndoContentEvent event,
    Emitter<EditorContentState> emit,
  ) {
    final fileContent = state.fileContent;
    if (fileContent == null) return;

    final buffer = fileContent.textBuffer;
    if (!buffer.undo()) return;
    final updatedText = buffer.getRawText();

    emit(
      state.copyWith(
        content: fileContent.copyWith(textBuffer: buffer),
        isModified: updatedText != state.originalContent,
      ),
    );
  }

  void _onRedoContent(
    RedoContentEvent event,
    Emitter<EditorContentState> emit,
  ) {
    final fileContent = state.fileContent;
    if (fileContent == null) return;

    final buffer = fileContent.textBuffer;
    if (!buffer.redo()) return;
    final updatedText = buffer.getRawText();

    emit(
      state.copyWith(
        content: fileContent.copyWith(textBuffer: buffer),
        isModified: updatedText != state.originalContent,
      ),
    );
  }

  void _onUpdateCursorPosition(
    UpdateCursorPositionEvent event,
    Emitter<EditorContentState> emit,
  ) {
    emit(
      state.copyWith(
        cursorPosition: CursorPosition(
          line: event.line,
          column: event.column,
          offset: 0, // Can be calculated if needed
        ),
      ),
    );
  }

  Future<void> _onSaveFile(
    SaveFileEvent event,
    Emitter<EditorContentState> emit,
  ) async {
    if (state.fileContent == null) return;

    emit(state.copyWith(status: .saving));

    final result = await repository
        .writeFile(
          state.fileContent!.path,
          state.fileContent!.content,
        )
        .run();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: .error,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          originalContent: state.fileContent!.content,
          isModified: false,
          status: .saved,
        ),
      ),
    );
  }
}

void _onCloseContent(
  CloseContentEvent event,
  Emitter<EditorContentState> emit,
) {
  emit(const EditorContentState());
}

_DiffRange _calculateDiff(String oldText, String newText) {
  if (oldText == newText) {
    return const _DiffRange(offset: 0, deletedLength: 0, insertedText: '');
  }

  var prefix = 0;
  final maxPrefix = oldText.length < newText.length
      ? oldText.length
      : newText.length;
  while (prefix < maxPrefix &&
      oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
    prefix++;
  }

  var oldSuffix = oldText.length;
  var newSuffix = newText.length;
  while (oldSuffix > prefix &&
      newSuffix > prefix &&
      oldText.codeUnitAt(oldSuffix - 1) == newText.codeUnitAt(newSuffix - 1)) {
    oldSuffix--;
    newSuffix--;
  }

  return _DiffRange(
    offset: prefix,
    deletedLength: oldSuffix - prefix,
    insertedText: newText.substring(prefix, newSuffix),
  );
}

final class _DiffRange {
  const _DiffRange({
    required this.offset,
    required this.deletedLength,
    required this.insertedText,
  });

  final int offset;
  final int deletedLength;
  final String insertedText;
}
