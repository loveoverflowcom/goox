import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:goox/core/errors/exceptions.dart';
import 'package:goox/core/errors/failures.dart';
import 'package:goox/features/editor_content/data/models/file_content.dart';
import 'package:goox/features/editor_content/data/repositories/file_repository.dart';
import 'package:path/path.dart' as path_helper;

final class FileRepositoryImpl implements FileRepository {
  @override
  TaskEither<Failure, FileContent> readFile(String path) {
    return TaskEither.tryCatch(
      () async {
        final file = File(path);

        if (!file.existsSync()) {
          throw const FailureException(FileReadFailure('File does not exist'));
        }

        final content = await file.readAsString();
        final stat = file.statSync();
        final extension = path_helper.extension(path);

        return FileContent(
          path: path,
          content: content,
          encoding: 'UTF-8',
          language: _getLanguageFromExtension(extension),
          lastModified: stat.modified,
        );
      },
      (error, stackTrace) {
        if (error is FailureException) return error.failure as Failure;
        return FileReadFailure(error.toString());
      },
    );
  }

  @override
  TaskEither<Failure, Unit> writeFile(String path, String content) {
    return TaskEither.tryCatch(
      () async {
        final file = File(path);
        await file.writeAsString(content);
        return unit;
      },
      (error, stackTrace) {
        if (error is FailureException) return error.failure as Failure;
        return FileWriteFailure(error.toString());
      },
    );
  }

  String _getLanguageFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.dart':
        return 'Dart';
      case '.json':
        return 'JSON';
      case '.yaml':
      case '.yml':
        return 'YAML';
      case '.md':
        return 'Markdown';
      case '.js':
        return 'JavaScript';
      case '.ts':
        return 'TypeScript';
      case '.py':
        return 'Python';
      case '.java':
        return 'Java';
      case '.cpp':
      case '.cc':
      case '.cxx':
        return 'C++';
      case '.c':
        return 'C';
      case '.h':
      case '.hpp':
        return 'Header';
      default:
        return 'Plain Text';
    }
  }
}
