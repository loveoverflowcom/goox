import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox/features/file_explorer/presentation/widgets/file_node_context_menu.dart';

void main() {
  group('FileNodeContextMenu', () {
    testWidgets('should show file menu items for file node', (tester) async {
      final fileNode = FileNode(
        name: 'test.txt',
        path: '/workspace/test.txt',
        type: FileNodeType.file,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileNodeContextMenu(
              node: fileNode,
              position: Offset.zero,
              onNewFile: () {},
              onNewFolder: () {},
              onRename: () {},
              onDelete: () {},
              onCopyPath: () {},
            ),
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Verify file menu items are present
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Copy Path'), findsOneWidget);

      // Verify folder-specific items are NOT present
      expect(find.text('New File'), findsNothing);
      expect(find.text('New Folder'), findsNothing);
      expect(find.text('Refresh'), findsNothing);
    });

    testWidgets('should show folder menu items for folder node', (tester) async {
      final folderNode = FileNode(
        name: 'folder',
        path: '/workspace/folder',
        type: FileNodeType.directory,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileNodeContextMenu(
              node: folderNode,
              position: Offset.zero,
              onNewFile: () {},
              onNewFolder: () {},
              onRename: () {},
              onDelete: () {},
              onCopyPath: () {},
            ),
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Verify folder menu items are present
      expect(find.text('New File'), findsOneWidget);
      expect(find.text('New Folder'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Copy Path'), findsOneWidget);

      // Verify empty area specific items are NOT present
      expect(find.text('Refresh'), findsNothing);
    });

    testWidgets('should show empty area menu items when node is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileNodeContextMenu(
              node: null,
              position: Offset.zero,
              onNewFile: () {},
              onNewFolder: () {},
              onRefresh: () {},
            ),
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Verify empty area menu items are present
      expect(find.text('New File'), findsOneWidget);
      expect(find.text('New Folder'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      // Verify file/folder specific items are NOT present
      expect(find.text('Rename'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Copy Path'), findsNothing);
    });

    testWidgets('should call onRename when Rename is selected', (tester) async {
      var renameCalled = false;

      final fileNode = FileNode(
        name: 'test.txt',
        path: '/workspace/test.txt',
        type: FileNodeType.file,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileNodeContextMenu(
              node: fileNode,
              position: Offset.zero,
              onNewFile: () {},
              onNewFolder: () {},
              onRename: () => renameCalled = true,
            ),
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap Rename
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(renameCalled, true);
    });

    testWidgets('should call onDelete when Delete is selected', (tester) async {
      var deleteCalled = false;

      final fileNode = FileNode(
        name: 'test.txt',
        path: '/workspace/test.txt',
        type: FileNodeType.file,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileNodeContextMenu(
              node: fileNode,
              position: Offset.zero,
              onNewFile: () {},
              onNewFolder: () {},
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleteCalled, true);
    });

    testWidgets('should call onCopyPath when Copy Path is selected', (tester) async {
      var copyPathCalled = false;

      final fileNode = FileNode(
        name: 'test.txt',
        path: '/workspace/test.txt',
        type: FileNodeType.file,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileNodeContextMenu(
              node: fileNode,
              position: Offset.zero,
              onNewFile: () {},
              onNewFolder: () {},
              onCopyPath: () => copyPathCalled = true,
            ),
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap Copy Path
      await tester.tap(find.text('Copy Path'));
      await tester.pumpAndSettle();

      expect(copyPathCalled, true);
    });

    testWidgets('should call onNewFile when New File is selected from folder menu', (tester) async {
      var newFileCalled = false;

      final folderNode = FileNode(
        name: 'folder',
        path: '/workspace/folder',
        type: FileNodeType.directory,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileNodeContextMenu(
              node: folderNode,
              position: Offset.zero,
              onNewFile: () => newFileCalled = true,
              onNewFolder: () {},
            ),
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap New File
      await tester.tap(find.text('New File'));
      await tester.pumpAndSettle();

      expect(newFileCalled, true);
    });

    testWidgets('should call onRefresh when Refresh is selected from empty area menu', (tester) async {
      var refreshCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileNodeContextMenu(
              node: null,
              position: Offset.zero,
              onNewFile: () {},
              onNewFolder: () {},
              onRefresh: () => refreshCalled = true,
            ),
          ),
        ),
      );

      // Open the menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap Refresh
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      expect(refreshCalled, true);
    });
  });
}
