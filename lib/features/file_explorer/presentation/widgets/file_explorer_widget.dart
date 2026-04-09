import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox/features/file_explorer/presentation/blocs/file_explorer_bloc.dart';
import 'package:goox/features/file_explorer/presentation/widgets/file_explorer_toolbar_callbacks.dart';
import 'package:goox/features/file_explorer/presentation/widgets/helpers/context_menu_action_handler.dart';
import 'package:goox_ui/goox_ui.dart';
import 'package:path/path.dart' as path_helper;

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

  /// Opens a folder picker and loads the selected workspace.
  Future<void> _pickWorkspaceFolder(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && context.mounted) {
      context.read<FileExplorerBloc>().add(LoadWorkspaceEvent(result));
    }
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
        popUpAnimationStyle: AnimationStyle.noAnimation,
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
              Icon(Icons.note_add_outlined, size: 18),
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
      ];
    } else if (node.type == FileNodeType.directory) {
      // Folder menu
      return [
        PopupMenuItem<String>(
          onTap: callbacks.onNewFile,
          child: const Row(
            children: [
              Icon(Icons.note_add_outlined, size: 18),
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
          onTap: callbacks.onCopyPath,
          child: const Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('Copy Path'),
            ],
          ),
        ),
        const PopupMenuDivider(),
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
          onTap: callbacks.onCopyPath,
          child: const Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('Copy Path'),
            ],
          ),
        ),
        const PopupMenuDivider(),
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
                    context.read<FileExplorerBloc>().add(
                      LoadWorkspaceEvent(path),
                    );
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
                  color: Theme.of(
                    context,
                  ).extension<EditorThemeExtension>()!.textColorDimmed,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No folder opened',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).extension<EditorThemeExtension>()!.textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Open a folder to start editing',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).extension<EditorThemeExtension>()!.textColorDimmed,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.xlg),
                _OpenFolderButton(
                  onFolderSelected: (path) {
                    context.read<FileExplorerBloc>().add(
                      LoadWorkspaceEvent(path),
                    );
                  },
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _WorkspaceHeader(
              workspacePath: state.workspacePath ?? '',
              onOpenFolder: () => _pickWorkspaceFolder(context),
              onNewFile: () =>
                  FileExplorerToolbarCallbacks.handleNewFile(context),
              onNewFolder: () =>
                  FileExplorerToolbarCallbacks.handleNewFolder(context),
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

/// Header row for the opened workspace root.
final class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.workspacePath,
    required this.onOpenFolder,
    required this.onNewFile,
    required this.onNewFolder,
  });

  final String workspacePath;
  final VoidCallback onOpenFolder;
  final VoidCallback onNewFile;
  final VoidCallback onNewFolder;

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final workspaceName = path_helper.basename(workspacePath).isNotEmpty
        ? path_helper.basename(workspacePath)
        : workspacePath;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: editorTheme.borderColor),
        ),
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: AppSpacing.iconSize,
            color: editorTheme.textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              workspaceName,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.fileExplorer.copyWith(
                color: editorTheme.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _WorkspaceHeaderAction(
            icon: Icons.folder_open_outlined,
            tooltip: 'Open Folder',
            onPressed: onOpenFolder,
            color: editorTheme.textColor,
          ),
          _WorkspaceHeaderAction(
            icon: Icons.note_add_outlined,
            tooltip: 'New File',
            onPressed: onNewFile,
            color: editorTheme.textColor,
          ),
          _WorkspaceHeaderAction(
            icon: Icons.create_new_folder_outlined,
            tooltip: 'New Folder',
            onPressed: onNewFolder,
            color: editorTheme.textColor,
          ),
        ],
      ),
    );
  }
}

final class _WorkspaceHeaderAction extends StatelessWidget {
  const _WorkspaceHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      iconSize: AppSpacing.iconSize,
      color: color,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
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
        backgroundColor: Theme.of(
          context,
        ).extension<EditorThemeExtension>()!.statusBarBackground,
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
final class _FileNodeWidget extends StatefulWidget {
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
  State<_FileNodeWidget> createState() => _FileNodeWidgetState();
}

final class _FileNodeWidgetState extends State<_FileNodeWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.state.selectedPath == widget.node.path;
    final isExpanded = widget.state.expandedFolders.containsKey(
      widget.node.path,
    );
    final children = widget.state.expandedFolders[widget.node.path] ?? [];
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;
    final backgroundColor = isSelected
        ? editorTheme.selectedItemColor
        : _isHovered
        ? editorTheme.hoverColor
        : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleTap(context),
            onSecondaryTapDown: (details) {
              _selectNode(context);
              _showNodeContextMenu(
                context: context,
                position: details.globalPosition,
              );
            },
            child: Container(
              color: backgroundColor,
              padding: EdgeInsets.only(
                left: 8.0 + (widget.depth * AppSpacing.fileItemIndent),
                top: 4,
                bottom: 4,
                right: 8,
              ),
              child: Row(
                children: [
                  if (widget.node.type == .directory)
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 18,
                      color: editorTheme.textColor,
                    )
                  else
                    Icon(
                      _getFileIcon(widget.node.name),
                      size: AppSpacing.iconSize,
                      color: editorTheme.textColor,
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      widget.node.name,
                      style: AppTextStyles.fileExplorer.copyWith(
                        color: editorTheme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.node.type == .directory && isExpanded)
          for (final child in children)
            _FileNodeWidget(
              node: child,
              depth: widget.depth + 1,
              state: widget.state,
              onFileSelected: widget.onFileSelected,
              workspacePath: widget.workspacePath,
            ),
      ],
    );
  }

  void _handleTap(BuildContext context) {
    _selectNode(context);
    if (widget.node.type == .directory) {
      context.read<FileExplorerBloc>().add(ToggleFolderEvent(widget.node.path));
    } else {
      widget.onFileSelected(widget.node.path, widget.node.name);
    }
  }

  void _selectNode(BuildContext context) {
    context.read<FileExplorerBloc>().add(SelectFileEvent(widget.node.path));
  }

  void _showNodeContextMenu({
    required BuildContext context,
    required Offset position,
  }) {
    final callbacks = _contextMenuCallbacks(context);

    unawaited(
      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx,
          position.dy,
        ),
        items: _buildContextMenuItems(widget.node, callbacks),
        popUpAnimationStyle: AnimationStyle.noAnimation,
      ),
    );
  }

  ContextMenuCallbacks _contextMenuCallbacks(BuildContext context) {
    final handler = ContextMenuActionHandler(
      context: context,
      workspacePath: widget.workspacePath,
    );
    return handler.getCallbacks(node: widget.node);
  }

  List<PopupMenuEntry<String>> _buildContextMenuItems(
    FileNode node,
    ContextMenuCallbacks callbacks,
  ) {
    if (node.type == FileNodeType.directory) {
      return [
        PopupMenuItem<String>(
          onTap: callbacks.onNewFile,
          child: const Row(
            children: [
              Icon(Icons.note_add_outlined, size: 18),
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
    }

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
