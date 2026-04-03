import 'package:fpdart/fpdart.dart';
import 'package:goox/core/errors/failures.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';

abstract class WorkspaceRepository {
  TaskEither<Failure, List<FileNode>> loadWorkspace(String path);
  TaskEither<Failure, List<FileNode>> loadChildren(String path);
  Future<bool> pathExists(String path);
}
