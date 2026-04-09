import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:goox/core/errors/failures.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox/features/file_explorer/data/repositories/workspace_repository.dart';
import 'package:goox/features/file_explorer/presentation/blocs/file_explorer_bloc.dart';
import 'package:goox/features/file_explorer/presentation/widgets/file_explorer_widget.dart';
import 'package:goox_ui/goox_ui.dart';
import 'package:mocktail/mocktail.dart';

final class MockWorkspaceRepository extends Mock
    implements WorkspaceRepository {}

void main() {
  late MockWorkspaceRepository repository;

  setUp(() {
    repository = MockWorkspaceRepository();
  });

  testWidgets(
    'shows workspace root header with compact new file and new folder actions',
    (tester) async {
      final nodes = [
        const FileNode(
          name: 'lib',
          path: '/workspace/lib',
          type: FileNodeType.directory,
        ),
        const FileNode(
          name: 'main.dart',
          path: '/workspace/main.dart',
          type: FileNodeType.file,
        ),
      ];

      when(() => repository.loadWorkspace(any())).thenAnswer(
        (_) => TaskEither.right(nodes),
      );
      when(() => repository.loadChildren(any())).thenAnswer(
        (_) => TaskEither.right(const <FileNode>[]),
      );
      when(() => repository.pathExists(any())).thenAnswer((_) async => true);
      when(() => repository.createFile(any(), any())).thenAnswer(
        (_) => TaskEither.left(
          const FileSystemFailure('createFile is not used in this test'),
        ),
      );
      when(() => repository.createFolder(any(), any())).thenAnswer(
        (_) => TaskEither.left(
          const FileSystemFailure('createFolder is not used in this test'),
        ),
      );
      when(() => repository.renameNode(any(), any())).thenAnswer(
        (_) => TaskEither.left(
          const FileSystemFailure('renameNode is not used in this test'),
        ),
      );
      when(() => repository.deleteNode(any())).thenAnswer(
        (_) => TaskEither.left(
          const FileSystemFailure('deleteNode is not used in this test'),
        ),
      );
      when(() => repository.validateFileName(any())).thenReturn(
        const Right(''),
      );
      when(() => repository.refreshWorkspace(any())).thenAnswer(
        (_) => TaskEither.right(nodes),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [EditorThemeExtension.dark()],
          ),
          home: Scaffold(
            body: BlocProvider(
              create: (_) =>
                  FileExplorerBloc(repository: repository)
                    ..add(const LoadWorkspaceEvent('/workspace')),
              child: FileExplorerWidget(
                onFileSelected: (path, fileName) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('workspace'), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
      expect(find.byIcon(Icons.note_add_outlined), findsOneWidget);
      expect(find.byIcon(Icons.create_new_folder_outlined), findsOneWidget);
    },
  );

  testWidgets('does not show per-file actions button on hover', (tester) async {
    final nodes = [
      const FileNode(
        name: 'lib',
        path: '/workspace/lib',
        type: FileNodeType.directory,
      ),
      const FileNode(
        name: 'main.dart',
        path: '/workspace/main.dart',
        type: FileNodeType.file,
      ),
    ];

    when(() => repository.loadWorkspace(any())).thenAnswer(
      (_) => TaskEither.right(nodes),
    );
    when(() => repository.loadChildren(any())).thenAnswer(
      (_) => TaskEither.right(const <FileNode>[]),
    );
    when(() => repository.pathExists(any())).thenAnswer((_) async => true);
    when(() => repository.createFile(any(), any())).thenAnswer(
      (_) => TaskEither.left(
        const FileSystemFailure('createFile is not used in this test'),
      ),
    );
    when(() => repository.createFolder(any(), any())).thenAnswer(
      (_) => TaskEither.left(
        const FileSystemFailure('createFolder is not used in this test'),
      ),
    );
    when(() => repository.renameNode(any(), any())).thenAnswer(
      (_) => TaskEither.left(
        const FileSystemFailure('renameNode is not used in this test'),
      ),
    );
    when(() => repository.deleteNode(any())).thenAnswer(
      (_) => TaskEither.left(
        const FileSystemFailure('deleteNode is not used in this test'),
      ),
    );
    when(() => repository.validateFileName(any())).thenReturn(
      const Right(''),
    );
    when(() => repository.refreshWorkspace(any())).thenAnswer(
      (_) => TaskEither.right(nodes),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: [EditorThemeExtension.dark()],
        ),
        home: Scaffold(
          body: BlocProvider(
            create: (_) =>
                FileExplorerBloc(repository: repository)
                  ..add(const LoadWorkspaceEvent('/workspace')),
            child: FileExplorerWidget(
              onFileSelected: (path, fileName) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.text('main.dart')));
    await tester.pump();

    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.text('Actions'), findsNothing);
  });
}
