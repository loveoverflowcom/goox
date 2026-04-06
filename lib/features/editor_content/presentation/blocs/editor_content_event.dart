part of 'editor_content_bloc.dart';

abstract class EditorContentEvent extends Equatable {
  const EditorContentEvent();

  @override
  List<Object?> get props => [];
}

final class LoadFileContentEvent extends EditorContentEvent {

  const LoadFileContentEvent(this.filePath);
  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

final class UpdateContentEvent extends EditorContentEvent {

  const UpdateContentEvent(this.content);
  final String content;

  @override
  List<Object?> get props => [content];
}

final class UpdateCursorPositionEvent extends EditorContentEvent {

  const UpdateCursorPositionEvent({
    required this.line,
    required this.column,
  });
  final int line;
  final int column;

  @override
  List<Object?> get props => [line, column];
}

final class SaveFileEvent extends EditorContentEvent {
  const SaveFileEvent();
}

final class CloseContentEvent extends EditorContentEvent {
  const CloseContentEvent();
}
