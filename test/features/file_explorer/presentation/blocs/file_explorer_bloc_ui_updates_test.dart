import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:goox/core/errors/failures.dart';
import 'package:goox/features/file_explorer/data.dart';
import 'package:goox/features/file_explorer/presentation/blocs/file_explorer_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

void main() {
  group('FileExplorerBloc UI Updates', () {
    late MockWorkspaceRepository mockRepository;
    late FileExplorerBloc bloc;

    setUp(() {
      mockRepository = MockWorkspaceRepository();
      bloc = FileExplorerBloc(repository: mockRepository);
    });

    tearDown(() {
      bloc.close();
    });

    group('CreateFileEvent', () {
      test('should auto-reload workspace and select new file', () async {
        // Arrange
        const workspacePath = '/workspace';
        const parentPath = '/workspace';
        const fileName = 'test.txt';
        final newFile = FileNode(
          name: fileName,
          path: '$parentPath/$fileName',
          type: FileNodeType.file,
        );
        final rootNodes = [newFile];

        // Setup initial state
        bloc.emit(
          const FileExplorerState(
            workspacePath: workspacePath,
            status: FileExplorerStatus.loaded,
          ),
        );

        when(() => mockRepository.validateFileName(fileName))
            .thenReturn(const Right('test.txt'));
        when(() => mockRepository.createFile(parentPath, fileName))
            .thenAnswer((_) => TaskEither.right(newFile));
        when(() => mockRepository.refreshWorkspace(workspacePath))
            .thenAnswer((_) => TaskEither.right(rootNodes));

        // Act
        bloc.add(
          const CreateFileEvent(
            parentPath: parentPath,
            fileName: fileName,
          ),
        );

        // Assert
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<FileExplorerState>(
              (state) =>
                  state.status == FileExplorerStatus.loading &&
                  state.pendingOperation == FileOperation.creating,
              'loading state with creating operation',
            ),
            predicate<FileExplorerState>(
              (state) =>
                  state.status == FileExplorerStatus.loaded &&
                  state.selectedPath == newFile.path &&
                  state.fileToOpen == newFile &&
                  state.successMessage == 'File created successfully',
              'loaded state with selected file and fileToOpen set',
            ),
          ]),
        );

        // Verify workspace was reloaded
        verify(() => mockRepository.refreshWorkspace(workspacePath)).called(1);
      });

      test('should expand parent folder when creating file in subfolder',
          () async {
        // Arrange
        const workspacePath = '/workspace';
        const parentPath = '/workspace/subfolder';
        const fileName = 'test.txt';
        final newFile = FileNode(
          name: fileName,
          path: '$parentPath/$fileName',
          type: FileNodeType.file,
        );
        final parentChildren = [newFile];
        final rootNodes = [
          const FileNode(
            name: 'subfolder',
            path: parentPath,
            type: FileNodeType.directory,
          ),
        ];

        // Setup initial state
        bloc.emit(
          const FileExplorerState(
            workspacePath: workspacePath,
            status: FileExplorerStatus.loaded,
          ),
        );

        when(() => mockRepository.validateFileName(fileName))
            .thenReturn(const Right('test.txt'));
        when(() => mockRepository.createFile(parentPath, fileName))
            .thenAnswer((_) => TaskEither.right(newFile));
        when(() => mockRepository.loadChildren(parentPath))
            .thenAnswer((_) => TaskEither.right(parentChildren));
        when(() => mockRepository.refreshWorkspace(workspacePath))
            .thenAnswer((_) => TaskEither.right(rootNodes));

        // Act
        bloc.add(
          const CreateFileEvent(
            parentPath: parentPath,
            fileName: fileName,
          ),
        );

        // Wait for all events to process
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Assert - parent folder should be expanded
        expect(bloc.state.expandedFolders.containsKey(parentPath), true);
        verify(() => mockRepository.loadChildren(parentPath)).called(2); // Called once for expand, once for reload
      });
    });

    group('CreateFolderEvent', () {
      test('should auto-reload workspace and select new folder', () async {
        // Arrange
        const workspacePath = '/workspace';
        const parentPath = '/workspace';
        const folderName = 'new_folder';
        final newFolder = FileNode(
          name: folderName,
          path: '$parentPath/$folderName',
          type: FileNodeType.directory,
        );
        final rootNodes = [newFolder];

        // Setup initial state
        bloc.emit(
          const FileExplorerState(
            workspacePath: workspacePath,
            status: FileExplorerStatus.loaded,
          ),
        );

        when(() => mockRepository.validateFileName(folderName))
            .thenReturn(const Right('new_folder'));
        when(() => mockRepository.createFolder(parentPath, folderName))
            .thenAnswer((_) => TaskEither.right(newFolder));
        when(() => mockRepository.refreshWorkspace(workspacePath))
            .thenAnswer((_) => TaskEither.right(rootNodes));

        // Act
        bloc.add(
          const CreateFolderEvent(
            parentPath: parentPath,
            folderName: folderName,
          ),
        );

        // Assert
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<FileExplorerState>(
              (state) =>
                  state.status == FileExplorerStatus.loading &&
                  state.pendingOperation == FileOperation.creating,
              'loading state with creating operation',
            ),
            predicate<FileExplorerState>(
              (state) =>
                  state.status == FileExplorerStatus.loaded &&
                  state.selectedPath == newFolder.path &&
                  state.successMessage == 'Folder created successfully',
              'loaded state with selected folder',
            ),
          ]),
        );

        // Verify workspace was reloaded
        verify(() => mockRepository.refreshWorkspace(workspacePath)).called(1);
      });
    });

    group('RenameNodeEvent', () {
      test('should auto-reload workspace and select renamed node', () async {
        // Arrange
        const workspacePath = '/workspace';
        const oldPath = '/workspace/old.txt';
        const newName = 'new.txt';
        final renamedFile = FileNode(
          name: newName,
          path: '/workspace/$newName',
          type: FileNodeType.file,
        );
        final rootNodes = [renamedFile];

        // Setup initial state
        bloc.emit(
          const FileExplorerState(
            workspacePath: workspacePath,
            selectedPath: oldPath,
            status: FileExplorerStatus.loaded,
          ),
        );

        when(() => mockRepository.validateFileName(newName))
            .thenReturn(const Right('new.txt'));
        when(() => mockRepository.renameNode(oldPath, newName))
            .thenAnswer((_) => TaskEither.right(renamedFile));
        when(() => mockRepository.refreshWorkspace(workspacePath))
            .thenAnswer((_) => TaskEither.right(rootNodes));

        // Act
        bloc.add(
          const RenameNodeEvent(
            nodePath: oldPath,
            newName: newName,
          ),
        );

        // Assert
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<FileExplorerState>(
              (state) =>
                  state.status == FileExplorerStatus.loading &&
                  state.pendingOperation == FileOperation.renaming,
              'loading state with renaming operation',
            ),
            predicate<FileExplorerState>(
              (state) =>
                  state.status == FileExplorerStatus.loaded &&
                  state.selectedPath == renamedFile.path &&
                  state.successMessage == 'Renamed successfully',
              'loaded state with renamed node selected',
            ),
          ]),
        );

        // Verify workspace was reloaded
        verify(() => mockRepository.refreshWorkspace(workspacePath)).called(1);
      });
    });

    group('DeleteNodeEvent', () {
      test('should auto-reload workspace and clear selection if deleted node was selected',
          () async {
        // Arrange
        const workspacePath = '/workspace';
        const deletedPath = '/workspace/delete.txt';
        final rootNodes = <FileNode>[];

        // Setup initial state with deleted file selected
        bloc.emit(
          const FileExplorerState(
            workspacePath: workspacePath,
            selectedPath: deletedPath,
            status: FileExplorerStatus.loaded,
          ),
        );

        when(() => mockRepository.deleteNode(deletedPath))
            .thenAnswer((_) => TaskEither.right(unit));
        when(() => mockRepository.refreshWorkspace(workspacePath))
            .thenAnswer((_) => TaskEither.right(rootNodes));

        // Act
        bloc.add(const DeleteNodeEvent(deletedPath));

        // Assert
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<FileExplorerState>(
              (state) =>
                  state.status == FileExplorerStatus.loading &&
                  state.pendingOperation == FileOperation.deleting,
              'loading state with deleting operation',
            ),
            predicate<FileExplorerState>(
              (state) =>
                  state.status == FileExplorerStatus.loaded &&
                  state.selectedPath == null &&
                  state.successMessage == 'Deleted successfully',
              'loaded state with cleared selection',
            ),
          ]),
        );

        // Verify workspace was reloaded
        verify(() => mockRepository.refreshWorkspace(workspacePath)).called(1);
      });

      test('should maintain selection if deleted node was not selected',
          () async {
        // Arrange
        const workspacePath = '/workspace';
        const selectedPath = '/workspace/selected.txt';
        const deletedPath = '/workspace/delete.txt';
        final rootNodes = [
          const FileNode(
            name: 'selected.txt',
            path: selectedPath,
            type: FileNodeType.file,
          ),
        ];

        // Setup initial state with different file selected
        bloc.emit(
          const FileExplorerState(
            workspacePath: workspacePath,
            selectedPath: selectedPath,
            status: FileExplorerStatus.loaded,
          ),
        );

        when(() => mockRepository.deleteNode(deletedPath))
            .thenAnswer((_) => TaskEither.right(unit));
        when(() => mockRepository.refreshWorkspace(workspacePath))
            .thenAnswer((_) => TaskEither.right(rootNodes));

        // Act
        bloc.add(const DeleteNodeEvent(deletedPath));

        // Wait for all events to process
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Assert - selection should be maintained
        expect(bloc.state.selectedPath, selectedPath);
      });
    });

    group('Maintain expand/collapse state', () {
      test('should preserve expanded folders after workspace reload', () async {
        // Arrange
        const workspacePath = '/workspace';
        const folder1Path = '/workspace/folder1';
        const folder2Path = '/workspace/folder2';
        const fileName = 'test.txt';
        final folder1Children = [
          const FileNode(
            name: 'file1.txt',
            path: '$folder1Path/file1.txt',
            type: FileNodeType.file,
          ),
        ];
        final folder2Children = [
          const FileNode(
            name: 'file2.txt',
            path: '$folder2Path/file2.txt',
            type: FileNodeType.file,
          ),
        ];
        final newFile = FileNode(
          name: fileName,
          path: '/workspace/$fileName',
          type: FileNodeType.file,
        );
        final rootNodes = [
          const FileNode(
            name: 'folder1',
            path: folder1Path,
            type: FileNodeType.directory,
          ),
          const FileNode(
            name: 'folder2',
            path: folder2Path,
            type: FileNodeType.directory,
          ),
          newFile,
        ];

        // Setup initial state with two folders expanded
        bloc.emit(
          FileExplorerState(
            workspacePath: workspacePath,
            expandedFolders: {
              folder1Path: folder1Children,
              folder2Path: folder2Children,
            },
            status: FileExplorerStatus.loaded,
          ),
        );

        when(() => mockRepository.validateFileName(fileName))
            .thenReturn(const Right('test.txt'));
        when(() => mockRepository.createFile(workspacePath, fileName))
            .thenAnswer((_) => TaskEither.right(newFile));
        when(() => mockRepository.refreshWorkspace(workspacePath))
            .thenAnswer((_) => TaskEither.right(rootNodes));
        when(() => mockRepository.loadChildren(folder1Path))
            .thenAnswer((_) => TaskEither.right(folder1Children));
        when(() => mockRepository.loadChildren(folder2Path))
            .thenAnswer((_) => TaskEither.right(folder2Children));

        // Act - create a file which triggers workspace reload
        bloc.add(
          const CreateFileEvent(
            parentPath: workspacePath,
            fileName: fileName,
          ),
        );

        // Wait for all events to process
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Assert - both folders should still be expanded
        expect(bloc.state.expandedFolders.containsKey(folder1Path), true);
        expect(bloc.state.expandedFolders.containsKey(folder2Path), true);
        verify(() => mockRepository.loadChildren(folder1Path)).called(1);
        verify(() => mockRepository.loadChildren(folder2Path)).called(1);
      });
    });

    group('ClearFileToOpenEvent', () {
      test('should clear fileToOpen flag', () async {
        // Arrange
        final fileNode = const FileNode(
          name: 'test.txt',
          path: '/workspace/test.txt',
          type: FileNodeType.file,
        );

        bloc.emit(
          FileExplorerState(
            workspacePath: '/workspace',
            fileToOpen: fileNode,
            status: FileExplorerStatus.loaded,
          ),
        );

        // Act
        bloc.add(const ClearFileToOpenEvent());

        // Assert
        await expectLater(
          bloc.stream,
          emits(
            predicate<FileExplorerState>(
              (state) => state.fileToOpen == null,
              'fileToOpen should be null',
            ),
          ),
        );
      });
    });
  });
}
