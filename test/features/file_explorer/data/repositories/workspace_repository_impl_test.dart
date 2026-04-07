import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goox/core/errors/failures.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox/features/file_explorer/data/repositories/workspace_repository_impl.dart';

void main() {
  late WorkspaceRepositoryImpl repository;
  late Directory testDir;

  setUp(() async {
    repository = WorkspaceRepositoryImpl();
    testDir = await Directory.systemTemp.createTemp('test_workspace_');
  });

  tearDown(() async {
    if (testDir.existsSync()) {
      await testDir.delete(recursive: true);
    }
  });

  group('WorkspaceRepositoryImpl', () {
    group('createFile', () {
      test('should create file successfully', () async {
        // Act
        final result = await repository.createFile(testDir.path, 'test.txt').run();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (fileNode) {
            expect(fileNode.name, 'test.txt');
            expect(fileNode.type, FileNodeType.file);
            expect(File(fileNode.path).existsSync(), true);
          },
        );
      });

      test('should fail when file already exists', () async {
        // Arrange
        await File('${testDir.path}/existing.txt').create();

        // Act
        final result = await repository.createFile(testDir.path, 'existing.txt').run();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<FileSystemFailure>());
            expect(failure.message, contains('already exists'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });

      test('should fail with invalid file name', () async {
        // Act
        final result = await repository.createFile(testDir.path, 'invalid/name.txt').run();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('cannot contain'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });

      test('should fail with empty file name', () async {
        // Act
        final result = await repository.createFile(testDir.path, '').run();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('cannot be empty'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });
    });

    group('createFolder', () {
      test('should create folder successfully', () async {
        // Act
        final result = await repository.createFolder(testDir.path, 'test_folder').run();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (fileNode) {
            expect(fileNode.name, 'test_folder');
            expect(fileNode.type, FileNodeType.directory);
            expect(Directory(fileNode.path).existsSync(), true);
          },
        );
      });

      test('should fail when folder already exists', () async {
        // Arrange
        await Directory('${testDir.path}/existing_folder').create();

        // Act
        final result = await repository.createFolder(testDir.path, 'existing_folder').run();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<FileSystemFailure>());
            expect(failure.message, contains('already exists'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });

      test('should fail with invalid folder name', () async {
        // Act
        final result = await repository.createFolder(testDir.path, 'invalid*name').run();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('cannot contain'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });
    });

    group('renameNode', () {
      test('should rename file successfully', () async {
        // Arrange
        final file = await File('${testDir.path}/old_name.txt').create();

        // Act
        final result = await repository.renameNode(file.path, 'new_name.txt').run();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (fileNode) {
            expect(fileNode.name, 'new_name.txt');
            expect(File('${testDir.path}/new_name.txt').existsSync(), true);
            expect(File('${testDir.path}/old_name.txt').existsSync(), false);
          },
        );
      });

      test('should rename folder successfully', () async {
        // Arrange
        final dir = await Directory('${testDir.path}/old_folder').create();

        // Act
        final result = await repository.renameNode(dir.path, 'new_folder').run();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (fileNode) {
            expect(fileNode.name, 'new_folder');
            expect(Directory('${testDir.path}/new_folder').existsSync(), true);
            expect(Directory('${testDir.path}/old_folder').existsSync(), false);
          },
        );
      });

      test('should fail when target name already exists', () async {
        // Arrange
        await File('${testDir.path}/file1.txt').create();
        await File('${testDir.path}/file2.txt').create();

        // Act
        final result = await repository.renameNode('${testDir.path}/file1.txt', 'file2.txt').run();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<FileSystemFailure>());
            expect(failure.message, contains('already exists'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });

      test('should fail when node does not exist', () async {
        // Act
        final result = await repository.renameNode('${testDir.path}/nonexistent.txt', 'new.txt').run();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<FileSystemFailure>());
            expect(failure.message, contains('does not exist'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });

      test('should fail with invalid new name', () async {
        // Arrange
        final file = await File('${testDir.path}/test.txt').create();

        // Act
        final result = await repository.renameNode(file.path, 'invalid:name.txt').run();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('cannot contain'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });
    });

    group('deleteNode', () {
      test('should delete file successfully', () async {
        // Arrange
        final file = await File('${testDir.path}/delete_me.txt').create();

        // Act
        final result = await repository.deleteNode(file.path).run();

        // Assert
        expect(result.isRight(), true);
        expect(File(file.path).existsSync(), false);
      });

      test('should delete folder successfully', () async {
        // Arrange
        final dir = await Directory('${testDir.path}/delete_me').create();

        // Act
        final result = await repository.deleteNode(dir.path).run();

        // Assert
        expect(result.isRight(), true);
        expect(Directory(dir.path).existsSync(), false);
      });

      test('should delete folder with contents recursively', () async {
        // Arrange
        final dir = await Directory('${testDir.path}/folder_with_contents').create();
        await File('${dir.path}/file.txt').create();
        await Directory('${dir.path}/subfolder').create();

        // Act
        final result = await repository.deleteNode(dir.path).run();

        // Assert
        expect(result.isRight(), true);
        expect(Directory(dir.path).existsSync(), false);
      });

      test('should fail when node does not exist', () async {
        // Act
        final result = await repository.deleteNode('${testDir.path}/nonexistent.txt').run();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<FileSystemFailure>());
            expect(failure.message, contains('does not exist'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });
    });

    group('validateFileName', () {
      test('should accept valid file names', () {
        final validNames = [
          'file.txt',
          'my-file.dart',
          'file_name.json',
          'file123.md',
          'file.name.with.dots.txt',
        ];

        for (final name in validNames) {
          final result = repository.validateFileName(name);
          expect(result.isRight(), true, reason: 'Should accept: $name');
        }
      });

      test('should reject empty name', () {
        final result = repository.validateFileName('');
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure.message, contains('cannot be empty')),
          (_) => fail('Expected failure'),
        );
      });

      test('should reject whitespace-only name', () {
        final result = repository.validateFileName('   ');
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure.message, contains('cannot be empty')),
          (_) => fail('Expected failure'),
        );
      });

      test('should reject names with invalid characters', () {
        final invalidNames = [
          'file/name',
          'file\\name',
          'file:name',
          'file*name',
          'file?name',
          'file"name',
          'file<name',
          'file>name',
          'file|name',
        ];

        for (final name in invalidNames) {
          final result = repository.validateFileName(name);
          expect(result.isLeft(), true, reason: 'Should reject: $name');
        }
      });
    });

    group('refreshWorkspace', () {
      test('should reload workspace successfully', () async {
        // Arrange
        await File('${testDir.path}/file1.txt').create();
        await File('${testDir.path}/file2.txt').create();

        // Act
        final result = await repository.refreshWorkspace(testDir.path).run();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure: ${failure.message}'),
          (nodes) {
            expect(nodes.length, 2);
            expect(nodes.any((n) => n.name == 'file1.txt'), true);
            expect(nodes.any((n) => n.name == 'file2.txt'), true);
          },
        );
      });
    });
  });
}
