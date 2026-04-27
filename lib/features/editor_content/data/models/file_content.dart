import 'package:equatable/equatable.dart';
import 'package:goox/features/editor_content/data/models/piece_table_text_buffer.dart';

final class FileContent extends Equatable {
  FileContent({
    required this.path,
    required this.encoding,
    required this.language,
    required this.lastModified,
    required String content,
    PieceTableTextBuffer? textBuffer,
  }) : textBuffer = textBuffer ?? PieceTableTextBuffer.fromText(content);

  final String path;
  final String encoding;
  final String language;
  final DateTime lastModified;
  final PieceTableTextBuffer textBuffer;

  /// Current document content reconstructed from the piece table.
  String get content => textBuffer.getRawText();

  /// Fast line count for status bar and virtual scrolling.
  int get lineCount => textBuffer.lineCount;

  FileContent copyWith({
    String? path,
    String? content,
    String? encoding,
    String? language,
    DateTime? lastModified,
    PieceTableTextBuffer? textBuffer,
  }) {
    return FileContent(
      path: path ?? this.path,
      encoding: encoding ?? this.encoding,
      language: language ?? this.language,
      lastModified: lastModified ?? this.lastModified,
      content: content ?? this.content,
      textBuffer: textBuffer ?? this.textBuffer,
    );
  }

  @override
  List<Object?> get props => [
    path,
    textBuffer,
    encoding,
    language,
    lastModified,
  ];
}
