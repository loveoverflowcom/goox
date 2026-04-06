import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/editor_content/data/models/file_content.dart';
import 'package:goox/features/editor_content/data/repositories/file_repository.dart';
import 'package:goox_editor_engine/goox_editor_engine.dart';

part 'editor_content_event.dart';
part 'editor_content_state.dart';

final class EditorContentBloc extends Bloc<EditorContentEvent, EditorContentState> {
  EditorContentBloc({required this.repository}) : super(const EditorContentState()) {
    on<LoadFileContentEvent>(_onLoadFileContent);
    on<UpdateContentEvent>(_onUpdateContent);
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

    final isModified = event.content != state.originalContent;
    
    emit(state.copyWith(
      content: state.fileContent!.copyWith(content: event.content),
      isModified: isModified,
    ));
  }

  void _onUpdateCursorPosition(
    UpdateCursorPositionEvent event,
    Emitter<EditorContentState> emit,
  ) {
    emit(state.copyWith(
      cursorPosition: CursorPosition(
        line: event.line,
        column: event.column,
        offset: 0, // Can be calculated if needed
      ),
    ));
  }

  Future<void> _onSaveFile(
    SaveFileEvent event,
    Emitter<EditorContentState> emit,
  ) async {
    if (state.fileContent == null) return;

    emit(state.copyWith(status: .saving));

    final result = await repository.writeFile(
      state.fileContent!.path,
      state.fileContent!.content,
    ).run();

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
