import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox/features/file_explorer/presentation/blocs/file_explorer_bloc.dart';
import 'package:goox/features/file_explorer/presentation/widgets/dialogs/create_file_dialog.dart';
import 'package:goox/features/file_explorer/presentation/widgets/dialogs/create_folder_dialog.dart';

/// Callback handlers for FileExplorerToolbar actions.
///
/// Provides methods to show dialogs and dispatch BLoC events for
/// creating new files and folders.
///
/// **Validates: Requirements 1.4, 1.5**
final class FileExplorerToolbarCallbacks {
  /// Shows the CreateFileDialog and dispatches CreateFileEvent on confirmation.
  ///
  /// This callback is intended to be passed to FileExplorerToolbar.onNewFile.
  ///
  /// The file will be created in:
  /// - The currently selected folder if a folder is selected
  /// - The parent of the currently selected file if a file is selected
  /// - The workspace root if nothing is selected
  static void handleNewFile(BuildContext context) {
    final bloc = context.read<FileExplorerBloc>();
    final state = bloc.state;
    
    // Determine parent path based on current selection
    final String parentPath;
    if (state.selectedPath != null) {
      // If a folder is selected, use it as parent
      // If a file is selected, use its parent directory
      final selectedNode = _findNodeByPath(state, state.selectedPath!);
      if (selectedNode != null && selectedNode.type == FileNodeType.directory) {
        parentPath = selectedNode.path;
      } else if (selectedNode != null) {
        // Extract parent directory from file path
        parentPath = selectedNode.path.substring(
          0,
          selectedNode.path.lastIndexOf('/'),
        );
      } else {
        // Fallback to workspace root
        parentPath = state.workspacePath ?? '';
      }
    } else {
      // No selection, use workspace root
      parentPath = state.workspacePath ?? '';
    }
    
    // Show dialog
    showDialog<String>(
      context: context,
      builder: (dialogContext) => CreateFileDialog(parentPath: parentPath),
    ).then((fileName) {
      if (fileName != null && fileName.isNotEmpty) {
        // Dispatch event to create file
        bloc.add(CreateFileEvent(
          parentPath: parentPath,
          fileName: fileName,
        ));
      }
    });
  }
  
  /// Shows the CreateFolderDialog and dispatches CreateFolderEvent on confirmation.
  ///
  /// This callback is intended to be passed to FileExplorerToolbar.onNewFolder.
  ///
  /// The folder will be created in:
  /// - The currently selected folder if a folder is selected
  /// - The parent of the currently selected file if a file is selected
  /// - The workspace root if nothing is selected
  static void handleNewFolder(BuildContext context) {
    final bloc = context.read<FileExplorerBloc>();
    final state = bloc.state;
    
    // Determine parent path based on current selection
    final String parentPath;
    if (state.selectedPath != null) {
      // If a folder is selected, use it as parent
      // If a file is selected, use its parent directory
      final selectedNode = _findNodeByPath(state, state.selectedPath!);
      if (selectedNode != null && selectedNode.type == FileNodeType.directory) {
        parentPath = selectedNode.path;
      } else if (selectedNode != null) {
        // Extract parent directory from file path
        parentPath = selectedNode.path.substring(
          0,
          selectedNode.path.lastIndexOf('/'),
        );
      } else {
        // Fallback to workspace root
        parentPath = state.workspacePath ?? '';
      }
    } else {
      // No selection, use workspace root
      parentPath = state.workspacePath ?? '';
    }
    
    // Show dialog
    showDialog<String>(
      context: context,
      builder: (dialogContext) => CreateFolderDialog(parentPath: parentPath),
    ).then((folderName) {
      if (folderName != null && folderName.isNotEmpty) {
        // Dispatch event to create folder
        bloc.add(CreateFolderEvent(
          parentPath: parentPath,
          folderName: folderName,
        ));
      }
    });
  }
  
  /// Helper method to find a node by its path in the current state.
  static FileNode? _findNodeByPath(FileExplorerState state, String path) {
    // Search in root nodes
    for (final node in state.rootNodes) {
      if (node.path == path) {
        return node;
      }
      // Search in expanded folders
      final found = _findNodeInChildren(state, node, path);
      if (found != null) {
        return found;
      }
    }
    return null;
  }
  
  /// Recursively search for a node in children.
  static FileNode? _findNodeInChildren(
    FileExplorerState state,
    FileNode parent,
    String path,
  ) {
    if (parent.type == FileNodeType.directory) {
      final children = state.expandedFolders[parent.path] ?? [];
      for (final child in children) {
        if (child.path == path) {
          return child;
        }
        final found = _findNodeInChildren(state, child, path);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }
}
