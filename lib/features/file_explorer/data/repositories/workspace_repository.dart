import 'package:fpdart/fpdart.dart';
import 'package:goox/core/errors/failures.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';

abstract class WorkspaceRepository {
  TaskEither<Failure, List<FileNode>> loadWorkspace(String path);
  TaskEither<Failure, List<FileNode>> loadChildren(String path);
  Future<bool> pathExists(String path);
  
  // File and folder creation
  TaskEither<Failure, FileNode> createFile(String parentPath, String fileName);
  TaskEither<Failure, FileNode> createFolder(String parentPath, String folderName);
  
  // File and folder operations
  TaskEither<Failure, FileNode> renameNode(String nodePath, String newName);
  TaskEither<Failure, Unit> deleteNode(String nodePath);
  
  // Validation and refresh
  Either<Failure, String> validateFileName(String name);
  TaskEither<Failure, List<FileNode>> refreshWorkspace(String workspacePath);
}
