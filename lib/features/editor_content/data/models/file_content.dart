import 'package:equatable/equatable.dart';

final class FileContent extends Equatable {

  const FileContent({
    required this.path,
    required this.content,
    required this.encoding,
    required this.language,
    required this.lastModified,
  });
  final String path;
  final String content;
  final String encoding;
  final String language;
  final DateTime lastModified;

  FileContent copyWith({
    String? path,
    String? content,
    String? encoding,
    String? language,
    DateTime? lastModified,
  }) {
    return FileContent(
      path: path ?? this.path,
      content: content ?? this.content,
      encoding: encoding ?? this.encoding,
      language: language ?? this.language,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  List<Object?> get props => [path, content, encoding, language, lastModified];
}
