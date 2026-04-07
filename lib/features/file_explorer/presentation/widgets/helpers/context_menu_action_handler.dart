import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox/features/file_explorer/presentation/blocs/file_explorer_bloc.dart';
import 'package:goox/features/file_explorer/presentation/widgets/dialogs/create_file_dialog.dart';
import 'package:goox/features/file_explorer/presentation/widgets/dialogs/create_folder_dialog.dart';
import 'package:goox/features/file_explorer/presentation/widgets/dialogs/delete_confirmation_dialog.dart';
import 'package:goox/features/file_explorer/presentation/widgets/dialogs/rename_dialog.dart';

/// Helper class for handling context menu actions.
///
/// Wires context menu callbacks to BLoC events and dialogs.
/// Handles menu positioning and dialog display.
///
/// **Validates: Requirements 2.7, 2.8, 2.9, 2.10**
final class ContextMenuActionHandler {
  /// Creates a context menu action handler.
  const ContextMenuActionHandler({
    required this.context,
    required this.workspacePath,
  });

  /// The build context for accessing BLoC and showing dialogs.
  final BuildContext context;

  /// The workspace path for creating files/folders at root.
  final String workspacePath;

  /// Handles "New File" action.
  ///
  /// Shows create file dialog and dispatches CreateFileEvent.
  /// [parentPath] is the folder where the file will be created.
  Future<void> handleNewFile(String parentPath) async {
    final fileName = await showDialog<String>(
      context: context,
      builder: (context) => CreateFileDialog(parentPath: parentPath),
    );

    if (fileName != null && context.mounted) {
      context.read<FileExplorerBloc>().add(
            CreateFileEvent(
              parentPath: parentPath,
              fileName: fileName,
            ),
          );
    }
  }

  /// Handles "New Folder" action.
  ///
  /// Shows create folder dialog and dispatches CreateFolderEvent.
  /// [parentPath] is the folder where the new folder will be created.
  Future<void> handleNewFolder(String parentPath) async {
    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => CreateFolderDialog(parentPath: parentPath),
    );

    if (folderName != null && context.mounted) {
      context.read<FileExplorerBloc>().add(
            CreateFolderEvent(
              parentPath: parentPath,
              folderName: folderName,
            ),
          );
    }
  }

  /// Handles "Rename" action.
  ///
  /// Shows rename dialog and dispatches RenameNodeEvent.
  /// [node] is the file or folder to be renamed.
  Future<void> handleRename(FileNode node) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => RenameDialog(
        currentName: node.name,
        nodePath: node.path,
      ),
    );

    if (newName != null && context.mounted) {
      context.read<FileExplorerBloc>().add(
            RenameNodeEvent(
              nodePath: node.path,
              newName: newName,
            ),
          );
    }
  }

  /// Handles "Delete" action.
  ///
  /// Shows delete confirmation dialog and dispatches DeleteNodeEvent.
  /// [node] is the file or folder to be deleted.
  Future<void> handleDelete(FileNode node) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        nodeName: node.name,
        nodeType: node.type,
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<FileExplorerBloc>().add(
            DeleteNodeEvent(node.path),
          );
    }
  }

  /// Handles "Copy Path" action.
  ///
  /// Dispatches CopyPathEvent to copy the path to clipboard.
  /// [nodePath] is the path to be copied.
  void handleCopyPath(String nodePath) {
    context.read<FileExplorerBloc>().add(
          CopyPathEvent(nodePath),
        );
  }

  /// Handles "Refresh" action.
  ///
  /// Dispatches RefreshWorkspaceEvent to reload the workspace.
  void handleRefresh() {
    context.read<FileExplorerBloc>().add(
          RefreshWorkspaceEvent(workspacePath),
        );
  }

  /// Shows context menu at the specified position.
  ///
  /// Returns callbacks for the context menu widget.
  /// [node] is the file/folder that was right-clicked (null for empty area).
  /// [position] is the position where the menu should appear.
  ContextMenuCallbacks getCallbacks({
    required FileNode? node,
  }) {
    // Determine parent path for new file/folder actions
    final parentPath = node?.type == FileNodeType.directory
        ? node!.path
        : workspacePath;

    return ContextMenuCallbacks(
      onNewFile: () => handleNewFile(parentPath),
      onNewFolder: () => handleNewFolder(parentPath),
      onRename: node != null ? () => handleRename(node) : null,
      onDelete: node != null ? () => handleDelete(node) : null,
      onCopyPath: node != null ? () => handleCopyPath(node.path) : null,
      onRefresh: () => handleRefresh(),
    );
  }
}

/// Data class holding context menu callbacks.
final class ContextMenuCallbacks {
  /// Creates context menu callbacks.
  const ContextMenuCallbacks({
    required this.onNewFile,
    required this.onNewFolder,
    required this.onRefresh,
    this.onRename,
    this.onDelete,
    this.onCopyPath,
  });

  /// Callback for "New File" action.
  final VoidCallback onNewFile;

  /// Callback for "New Folder" action.
  final VoidCallback onNewFolder;

  /// Callback for "Rename" action (null if not applicable).
  final VoidCallback? onRename;

  /// Callback for "Delete" action (null if not applicable).
  final VoidCallback? onDelete;

  /// Callback for "Copy Path" action (null if not applicable).
  final VoidCallback? onCopyPath;

  /// Callback for "Refresh" action.
  final VoidCallback onRefresh;
}
