import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:goox/core/errors/exceptions.dart';
import 'package:goox/core/errors/failures.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox/features/file_explorer/data/repositories/workspace_repository.dart';
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
}
