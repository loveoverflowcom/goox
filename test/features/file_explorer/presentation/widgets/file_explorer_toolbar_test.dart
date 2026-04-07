import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/file_explorer/presentation/widgets/file_explorer_toolbar.dart';
import 'package:goox_ui/goox_ui.dart';

void main() {
  group('FileExplorerToolbar', () {
    testWidgets('should display new file and new folder buttons',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [EditorThemeExtension.dark()],
          ),
          home: Scaffold(
            body: FileExplorerToolbar(
              onNewFile: () {},
              onNewFolder: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
      expect(find.byIcon(Icons.create_new_folder_outlined), findsOneWidget);
    });

    testWidgets('should have correct height and border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [EditorThemeExtension.dark()],
          ),
          home: Scaffold(
            body: FileExplorerToolbar(
              onNewFile: () {},
              onNewFolder: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxHeight, 40);
    });

    testWidgets('should call onNewFile when new file button tapped',
        (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [EditorThemeExtension.dark()],
          ),
          home: Scaffold(
            body: FileExplorerToolbar(
              onNewFile: () => called = true,
              onNewFolder: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.insert_drive_file_outlined));
      expect(called, true);
    });

    testWidgets('should call onNewFolder when new folder button tapped',
        (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [EditorThemeExtension.dark()],
          ),
          home: Scaffold(
            body: FileExplorerToolbar(
              onNewFile: () {},
              onNewFolder: () => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
      expect(called, true);
    });

    testWidgets('should display tooltips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [EditorThemeExtension.dark()],
          ),
          home: Scaffold(
            body: FileExplorerToolbar(
              onNewFile: () {},
              onNewFolder: () {},
            ),
          ),
        ),
      );

      // Find the IconButton widgets
      final newFileButton = find.ancestor(
        of: find.byIcon(Icons.insert_drive_file_outlined),
        matching: find.byType(IconButton),
      );
      final newFolderButton = find.ancestor(
        of: find.byIcon(Icons.create_new_folder_outlined),
        matching: find.byType(IconButton),
      );

      // Verify tooltips
      final newFileIconButton = tester.widget<IconButton>(newFileButton);
      final newFolderIconButton = tester.widget<IconButton>(newFolderButton);

      expect(newFileIconButton.tooltip, 'New File');
      expect(newFolderIconButton.tooltip, 'New Folder');
    });
  });
}
