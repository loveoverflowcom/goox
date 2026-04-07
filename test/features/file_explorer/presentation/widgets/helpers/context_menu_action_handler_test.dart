import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox/features/file_explorer/presentation/widgets/helpers/context_menu_action_handler.dart';

void main() {
  group('ContextMenuActionHandler', () {
    group('getCallbacks', () {
      test('should return callbacks for file node', () {
        // Test that ContextMenuCallbacks can be created with all required callbacks
        FileNode(
          name: 'test.txt',
          path: '/test/workspace/test.txt',
          type: FileNodeType.file,
        );

        final callbacks = ContextMenuCallbacks(
          onNewFile: () {},
          onNewFolder: () {},
          onRename: () {},
          onDelete: () {},
          onCopyPath: () {},
          onRefresh: () {},
        );

        expect(callbacks.onNewFile, isNotNull);
        expect(callbacks.onNewFolder, isNotNull);
        expect(callbacks.onRename, isNotNull);
        expect(callbacks.onDelete, isNotNull);
        expect(callbacks.onCopyPath, isNotNull);
        expect(callbacks.onRefresh, isNotNull);
      });

      test('should return callbacks for folder node', () {
        // Test that ContextMenuCallbacks can be created with all required callbacks
        FileNode(
          name: 'folder',
          path: '/test/workspace/folder',
          type: FileNodeType.directory,
        );

        final callbacks = ContextMenuCallbacks(
          onNewFile: () {},
          onNewFolder: () {},
          onRename: () {},
          onDelete: () {},
          onCopyPath: () {},
          onRefresh: () {},
        );

        expect(callbacks.onNewFile, isNotNull);
        expect(callbacks.onNewFolder, isNotNull);
        expect(callbacks.onRename, isNotNull);
        expect(callbacks.onDelete, isNotNull);
        expect(callbacks.onCopyPath, isNotNull);
        expect(callbacks.onRefresh, isNotNull);
      });

      test('should return callbacks for empty area (null node)', () {
        final callbacks = ContextMenuCallbacks(
          onNewFile: () {},
          onNewFolder: () {},
          onRefresh: () {},
        );

        expect(callbacks.onNewFile, isNotNull);
        expect(callbacks.onNewFolder, isNotNull);
        expect(callbacks.onRename, isNull);
        expect(callbacks.onDelete, isNull);
        expect(callbacks.onCopyPath, isNull);
        expect(callbacks.onRefresh, isNotNull);
      });

      test('should allow null callbacks for node-specific actions', () {
        final callbacks = ContextMenuCallbacks(
          onNewFile: () {},
          onNewFolder: () {},
          onRefresh: () {},
          onRename: null,
          onDelete: null,
          onCopyPath: null,
        );

        expect(callbacks.onRename, isNull);
        expect(callbacks.onDelete, isNull);
        expect(callbacks.onCopyPath, isNull);
      });
    });
  });
}
