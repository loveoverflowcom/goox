import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox/features/file_explorer/presentation/blocs/file_explorer_bloc.dart';
import 'package:goox/features/file_explorer/presentation/widgets/file_explorer_toolbar.dart';
import 'package:goox/features/file_explorer/presentation/widgets/file_explorer_toolbar_callbacks.dart';
import 'package:goox/features/file_explorer/presentation/widgets/helpers/context_menu_action_handler.dart';
import 'package:goox_ui/goox_ui.dart';

/// Widget for displaying file explorer tree.
final class FileExplorerWidget extends StatelessWidget {
  /// Creates a file explorer widget.
  const FileExplorerWidget({
    required this.onFileSelected,
    super.key,
  });

  /// Callback when a file is selected.
  final void Function(String filePath, String fileName) onFileSelected;

  /// Shows error message in a SnackBar.
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows success message in a SnackBar.
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows context menu at the specified position.
  void _showContextMenu({
    required BuildContext context,
    required Offset position,
    required FileNode? node,
    required String workspacePath,
  }) {
    final handler = ContextMenuActionHandler(
      context: context,
      workspacePath: workspacePath,
    );
    final callbacks = handler.getCallbacks(node: node);

    unawaited(
      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx,
          position.dy,
        ),
        items: _buildContextMenuItems(node, callbacks),
      ),
    );
  }

  /// Builds context menu items based on node type.
  List<PopupMenuEntry<String>> _buildContextMenuItems(
    FileNode? node,
    ContextMenuCallbacks callbacks,
  ) {
    if (node == null) {
      // Empty area menu
      return [
        PopupMenuItem<String>(
          onTap: callbacks.onNewFile,
          child: const Row(
            children: [
              Icon(Icons.insert_drive_file_outlined, size: 18),
              SizedBox(width: 8),
              Text('New File'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: callbacks.onNewFolder,
          child: const Row(
            children: [
              Icon(Icons.create_new_folder_outlined, size: 18),
              SizedBox(width: 8),
              Text('New Folder'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          onTap: callbacks.onRefresh,
          child: const Row(
            children: [
              Icon(Icons.refresh, size: 18),
              SizedBox(width: 8),
              Text('Refresh'),
            ],
          ),
        ),
      ];
    } else if (node.type == FileNodeType.directory) {
      // Folder menu
      return [
        PopupMenuItem<String>(
          onTap: callbacks.onNewFile,
          child: const Row(
            children: [
              Icon(Icons.insert_drive_file_outlined, size: 18),
              SizedBox(width: 8),
              Text('New File'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: callbacks.onNewFolder,
          child: const Row(
            children: [
              Icon(Icons.create_new_folder_outlined, size: 18),
              SizedBox(width: 8),
              Text('New Folder'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          onTap: callbacks.onRename,
          child: const Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: callbacks.onDelete,
          child: const Row(
            children: [
              Icon(Icons.delete_outline, size: 18),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          onTap: callbacks.onCopyPath,
          child: const Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('Copy Path'),
            ],
          ),
        ),
      ];
    } else {
      // File menu
      return [
        PopupMenuItem<String>(
          onTap: callbacks.onRename,
          child: const Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: callbacks.onDelete,
          child: const Row(
            children: [
              Icon(Icons.delete_outline, size: 18),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          onTap: callbacks.onCopyPath,
          child: const Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('Copy Path'),
            ],
          ),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FileExplorerBloc, FileExplorerState>(
      listener: (context, state) {
        // Auto-open file in editor when fileToOpen is set
        if (state.fileToOpen != null) {
          final fileNode = state.fileToOpen!;
          onFileSelected(fileNode.path, fileNode.name);
          
          // Clear the fileToOpen flag after opening
          context.read<FileExplorerBloc>().add(
            const ClearFileToOpenEvent(),
          );
        }

        // Show error messages
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          _showErrorSnackBar(context, state.errorMessage!);
          // Clear messages after showing
          context.read<FileExplorerBloc>().add(const ClearMessagesEvent());
        }

        // Show success messages
        if (state.successMessage != null && state.successMessage!.isNotEmpty) {
          _showSuccessSnackBar(context, state.successMessage!);
          // Clear messages after showing
          context.read<FileExplorerBloc>().add(const ClearMessagesEvent());
        }
      },
      builder: (context, state) {
        if (state.status == .loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == .error) {
          return Center(
            child: Column(
              mainAxisAlignment: .center,
              children: [
                Text(
                  state.errorMessage ?? 'Error loading workspace',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: .center,
                ),
                const SizedBox(height: AppSpacing.lg),
                _OpenFolderButton(
                  onFolderSelected: (path) {
                    context.read<FileExplorerBloc>().add(LoadWorkspaceEvent(path));
                  },
                ),
              ],
            ),
          );
        }

        if (state.rootNodes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: .center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: AppSpacing.xxxlg,
                  color: Theme.of(context).extension<EditorThemeExtension>()!.textColorDimmed,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No folder opened',
                  style: TextStyle(
                    color: Theme.of(context).extension<EditorThemeExtension>()!.textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Open a folder to start editing',
                  style: TextStyle(
                    color: Theme.of(context).extension<EditorThemeExtension>()!.textColorDimmed,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.xlg),
                _OpenFolderButton(
                  onFolderSelected: (path) {
                    context.read<FileExplorerBloc>().add(LoadWorkspaceEvent(path));
                  },
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            FileExplorerToolbar(
              onNewFile: () => FileExplorerToolbarCallbacks.handleNewFile(context),
              onNewFolder: () => FileExplorerToolbarCallbacks.handleNewFolder(context),
            ),
            Expanded(
              child: GestureDetector(
                onSecondaryTapDown: (details) {
                  _showContextMenu(
                    context: context,
                    position: details.globalPosition,
                    node: null,
                    workspacePath: state.workspacePath ?? '',
                  );
                },
                child: ListView(
                  children: [
                    for (final node in state.rootNodes)
                      _FileNodeWidget(
                        node: node,
                        depth: 0,
                        state: state,
                        onFileSelected: onFileSelected,
                        workspacePath: state.workspacePath ?? '',
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget for the "Open Folder" button.
final class _OpenFolderButton extends StatelessWidget {
  const _OpenFolderButton({
    required this.onFolderSelected,
  });

  final void Function(String path) onFolderSelected;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final result = await FilePicker.platform.getDirectoryPath();
        if (result != null) {
          onFolderSelected(result);
        }
      },
      icon: const Icon(Icons.folder_open),
      label: const Text('Open Folder'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).extension<EditorThemeExtension>()!.statusBarBackground,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

/// Widget for displaying a single file node in the tree.
final class _FileNodeWidget extends StatelessWidget {
  const _FileNodeWidget({
    required this.node,
    required this.depth,
    required this.state,
    required this.onFileSelected,
    required this.workspacePath,
  });

  final FileNode node;
  final int depth;
  final FileExplorerState state;
  final void Function(String filePath, String fileName) onFileSelected;
  final String workspacePath;

  @override
  Widget build(BuildContext context) {
    final isSelected = state.selectedPath == node.path;
    final isExpanded = state.expandedFolders.containsKey(node.path);
    final children = state.expandedFolders[node.path] ?? [];
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onSecondaryTapDown: (details) {
            _showNodeContextMenu(
              context: context,
              position: details.globalPosition,
              node: node,
              workspacePath: workspacePath,
            );
          },
          child: InkWell(
            onTap: () {
              if (node.type == .directory) {
                context.read<FileExplorerBloc>().add(ToggleFolderEvent(node.path));
              } else {
                context.read<FileExplorerBloc>().add(SelectFileEvent(node.path));
                onFileSelected(node.path, node.name);
              }
            },
            hoverColor: editorTheme.hoverColor,
            child: ColoredBox(
              color: isSelected ? editorTheme.selectedItemColor : Colors.transparent,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 8.0 + (depth * AppSpacing.fileItemIndent),
                  top: 4,
                  bottom: 4,
                  right: 8,
                ),
                child: Row(
                  children: [
                    if (node.type == .directory)
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 18,
                        color: editorTheme.textColor,
                      )
                    else
                      Icon(
                        _getFileIcon(node.name),
                        size: AppSpacing.iconSize,
                        color: editorTheme.textColor,
                      ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        node.name,
                        style: AppTextStyles.fileExplorer,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (node.type == .directory && isExpanded)
          for (final child in children)
            _FileNodeWidget(
              node: child,
              depth: depth + 1,
              state: state,
              onFileSelected: onFileSelected,
              workspacePath: workspacePath,
            ),
      ],
    );
  }

  /// Shows context menu for this node.
  void _showNodeContextMenu({
    required BuildContext context,
    required Offset position,
    required FileNode node,
    required String workspacePath,
  }) {
    final handler = ContextMenuActionHandler(
      context: context,
      workspacePath: workspacePath,
    );
    final callbacks = handler.getCallbacks(node: node);

    unawaited(
      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx,
          position.dy,
        ),
        items: _buildContextMenuItems(node, callbacks),
      ),
    );
  }

  /// Builds context menu items based on node type.
  List<PopupMenuEntry<String>> _buildContextMenuItems(
    FileNode node,
    ContextMenuCallbacks callbacks,
  ) {
    if (node.type == FileNodeType.directory) {
      // Folder menu
      return [
        PopupMenuItem<String>(
          onTap: callbacks.onNewFile,
          child: const Row(
            children: [
              Icon(Icons.insert_drive_file_outlined, size: 18),
              SizedBox(width: 8),
              Text('New File'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: callbacks.onNewFolder,
          child: const Row(
            children: [
              Icon(Icons.create_new_folder_outlined, size: 18),
              SizedBox(width: 8),
              Text('New Folder'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          onTap: callbacks.onRename,
          child: const Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: callbacks.onDelete,
          child: const Row(
            children: [
              Icon(Icons.delete_outline, size: 18),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          onTap: callbacks.onCopyPath,
          child: const Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('Copy Path'),
            ],
          ),
        ),
      ];
    } else {
      // File menu
      return [
        PopupMenuItem<String>(
          onTap: callbacks.onRename,
          child: const Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: callbacks.onDelete,
          child: const Row(
            children: [
              Icon(Icons.delete_outline, size: 18),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          onTap: callbacks.onCopyPath,
          child: const Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('Copy Path'),
            ],
          ),
        ),
      ];
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'dart' => Icons.code_outlined,
      'json' => Icons.data_object_outlined,
      'yaml' || 'yml' => Icons.settings_outlined,
      'md' => Icons.description_outlined,
      'txt' => Icons.text_snippet_outlined,
      'png' || 'jpg' || 'jpeg' || 'gif' || 'svg' => Icons.image_outlined,
      'pdf' => Icons.picture_as_pdf_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }
}
