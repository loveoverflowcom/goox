import 'package:fpdart/fpdart.dart';
import 'package:goox/core/errors/failures.dart';
import 'package:goox/features/editor_content/data/models/file_content.dart';

abstract class FileRepository {
  TaskEither<Failure, FileContent> readFile(String path);
  TaskEither<Failure, Unit> writeFile(String path, String content);
}
