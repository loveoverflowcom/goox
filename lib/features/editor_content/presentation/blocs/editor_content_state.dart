part of 'editor_content_bloc.dart';

enum EditorContentStatus { initial, loading, loaded, saving, saved, error }

final class EditorContentState extends Equatable {

  const EditorContentState({
    this.fileContent,
    this.originalContent = '',
    this.cursorPosition = const CursorPosition(line: 1, column: 1, offset: 0),
    this.isModified = false,
    this.status = .initial,
    this.errorMessage,
  });
  final FileContent? fileContent;
  final String originalContent;
  final CursorPosition cursorPosition;
  final bool isModified;
  final EditorContentStatus status;
  final String? errorMessage;

  EditorContentState copyWith({
    FileContent? content,
    String? originalContent,
    CursorPosition? cursorPosition,
    bool? isModified,
    EditorContentStatus? status,
    String? errorMessage,
  }) {
    return EditorContentState(
      fileContent: content ?? fileContent,
      originalContent: originalContent ?? this.originalContent,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      isModified: isModified ?? this.isModified,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  int get totalLines {
    if (fileContent == null) return 0;
    return fileContent!.content.split('\n').length;
  }

  @override
  List<Object?> get props => [
        fileContent,
        originalContent,
        cursorPosition,
        isModified,
        status,
        errorMessage,
      ];
}
