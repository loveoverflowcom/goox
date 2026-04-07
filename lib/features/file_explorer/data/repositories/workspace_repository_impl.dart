import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:goox/core/errors/exceptions.dart';
import 'package:goox/core/errors/failures.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox/features/file_explorer/data/repositories/workspace_repository.dart';
import 'package:goox/features/file_explorer/data/validators/file_name_validator.dart';
import 'package:path/path.dart' as path_helper;

final class WorkspaceRepositoryImpl implements WorkspaceRepository {
  @override
  TaskEither<Failure, List<FileNode>> loadWorkspace(String path) {
    return TaskEither.tryCatch(
      () async {
        if (!await pathExists(path)) {
          throw const FailureException(InvalidPathFailure('Workspace path does not exist'));
        }

        // Call loadChildren and get the result
        final childrenResult = await loadChildren(path).run();
        return childrenResult.getOrElse((failure) => throw FailureException(failure));
      },
      (error, stackTrace) {
        if (error is FailureException) return error.failure as Failure;
        return WorkspaceLoadFailure(error.toString());
      },
    );
  }

  @override
  TaskEither<Failure, List<FileNode>> loadChildren(String path) {
    return TaskEither.tryCatch(
      () async {
        final dir = Directory(path);
        final entities = await dir.list().toList();

        // Sort: folders first, then files, alphabetically
        entities.sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });

        final nodes = entities.map((entity) {
          final isDir = entity is Directory;
          final stat = entity.statSync();

          return FileNode(
            name: path_helper.basename(entity.path),
            path: entity.path,
            type: isDir ? .directory : .file,
            lastModified: stat.modified,
            size: isDir ? null : stat.size,
          );
        }).toList();

        return nodes;
      },
      (error, stackTrace) {
        if (error is FailureException) return error.failure as Failure;
        return WorkspaceLoadFailure(error.toString());
      },
    );
  }

  @override
  Future<bool> pathExists(String path) async {
    return Directory(path).existsSync() || File(path).existsSync();
  }

  @override
  TaskEither<Failure, FileNode> createFile(String parentPath, String fileName) {
    return TaskEither.tryCatch(
      () async {
        // Validate file name
        final validationResult = validateFileName(fileName);
        if (validationResult.isLeft()) {
          throw FailureException(
            validationResult.fold((failure) => failure, (_) => throw StateError('Unexpected state')),
          );
        }

        // Build full path
        final filePath = path_helper.join(parentPath, fileName);

        // Check if file already exists
        if (await pathExists(filePath)) {
          throw const FailureException(
            FileSystemFailure('A file with this name already exists'),
          );
        }

        // Create the file
        final file = File(filePath);
        await file.create();

        // Get file stats
        final stat = await file.stat();

        // Return FileNode
        return FileNode(
          name: fileName,
          path: filePath,
          type: FileNodeType.file,
          lastModified: stat.modified,
          size: stat.size,
        );
      },
      (error, stackTrace) {
        if (error is FailureException) return error.failure as Failure;
        return FileSystemFailure('Failed to create file: ${error.toString()}');
      },
    );
  }

  @override
  TaskEither<Failure, FileNode> createFolder(String parentPath, String folderName) {
    return TaskEither.tryCatch(
      () async {
        // Validate folder name
        final validationResult = validateFileName(folderName);
        if (validationResult.isLeft()) {
          throw FailureException(
            validationResult.fold((failure) => failure, (_) => throw StateError('Unexpected state')),
          );
        }

        // Build full path
        final folderPath = path_helper.join(parentPath, folderName);

        // Check if folder already exists
        if (await pathExists(folderPath)) {
          throw const FailureException(
            FileSystemFailure('A folder with this name already exists'),
          );
        }

        // Create the folder
        final directory = Directory(folderPath);
        await directory.create();

        // Get directory stats
        final stat = await directory.stat();

        // Return FileNode
        return FileNode(
          name: folderName,
          path: folderPath,
          type: FileNodeType.directory,
          lastModified: stat.modified,
        );
      },
      (error, stackTrace) {
        if (error is FailureException) return error.failure as Failure;
        return FileSystemFailure('Failed to create folder: ${error.toString()}');
      },
    );
  }

  @override
  TaskEither<Failure, FileNode> renameNode(String nodePath, String newName) {
    return TaskEither.tryCatch(
      () async {
        // Validate new name
        final validationResult = validateFileName(newName);
        if (validationResult.isLeft()) {
          throw FailureException(
            validationResult.fold((failure) => failure, (_) => throw StateError('Unexpected state')),
          );
        }

        // Check if node exists
        if (!await pathExists(nodePath)) {
          throw const FailureException(
            FileSystemFailure('File or folder does not exist'),
          );
        }

        // Build new path
        final parentPath = path_helper.dirname(nodePath);
        final newPath = path_helper.join(parentPath, newName);

        // Check if target already exists
        if (await pathExists(newPath)) {
          throw const FailureException(
            FileSystemFailure('A file or folder with this name already exists'),
          );
        }

        // Determine if it's a file or directory
        final isDirectory = Directory(nodePath).existsSync();
        final entity = isDirectory ? Directory(nodePath) : File(nodePath);

        // Rename the entity
        await entity.rename(newPath);

        // Get stats
        final stat = await entity.stat();

        // Return updated FileNode
        return FileNode(
          name: newName,
          path: newPath,
          type: isDirectory ? FileNodeType.directory : FileNodeType.file,
          lastModified: stat.modified,
          size: isDirectory ? null : stat.size,
        );
      },
      (error, stackTrace) {
        if (error is FailureException) return error.failure as Failure;
        return FileSystemFailure('Failed to rename: ${error.toString()}');
      },
    );
  }

  @override
  TaskEither<Failure, Unit> deleteNode(String nodePath) {
    return TaskEither.tryCatch(
      () async {
        // Check if node exists
        if (!await pathExists(nodePath)) {
          throw const FailureException(
            FileSystemFailure('File or folder does not exist'),
          );
        }

        // Determine if it's a file or directory
        final isDirectory = Directory(nodePath).existsSync();

        if (isDirectory) {
          // Delete directory recursively
          final directory = Directory(nodePath);
          await directory.delete(recursive: true);
        } else {
          // Delete file
          final file = File(nodePath);
          await file.delete();
        }

        return unit;
      },
      (error, stackTrace) {
        if (error is FailureException) return error.failure as Failure;
        return FileSystemFailure('Failed to delete: ${error.toString()}');
      },
    );
  }

  @override
  Either<Failure, String> validateFileName(String name) {
    return FileNameValidator.validate(name).mapLeft((validationFailure) => validationFailure as Failure);
  }

  @override
  TaskEither<Failure, List<FileNode>> refreshWorkspace(String workspacePath) {
    // Refresh is essentially reloading the workspace
    return loadWorkspace(workspacePath);
  }
}
