import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox/features/file_explorer/presentation/blocs/file_explorer_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FileExplorerBloc, FileExplorerState>(
      builder: (context, state) {
        if (state.status == .loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == .error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.errorMessage ?? 'Error loading workspace',
                  style: const TextStyle(color: AppColors.errorColor),
                  textAlign: TextAlign.center,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_open,
                  size: AppSpacing.xxxlg,
                  color: AppColors.textColorDimmed,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'No folder opened',
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Open a folder to start editing',
                  style: TextStyle(
                    color: AppColors.textColorDimmed,
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

        return ListView(
          children: [
            for (final node in state.rootNodes)
              _FileNodeWidget(
                node: node,
                depth: 0,
                state: state,
                onFileSelected: onFileSelected,
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
        backgroundColor: AppColors.statusBarBackground,
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
  });

  final FileNode node;
  final int depth;
  final FileExplorerState state;
  final void Function(String filePath, String fileName) onFileSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = state.selectedPath == node.path;
    final isExpanded = state.expandedFolders.containsKey(node.path);
    final children = state.expandedFolders[node.path] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (node.type == .directory) {
              context.read<FileExplorerBloc>().add(ToggleFolderEvent(node.path));
            } else {
              context.read<FileExplorerBloc>().add(SelectFileEvent(node.path));
              onFileSelected(node.path, node.name);
            }
          },
          hoverColor: AppColors.hoverColor,
          child: Container(
            padding: EdgeInsets.only(
              left: 8.0 + (depth * AppSpacing.fileItemIndent),
              top: 4,
              bottom: 4,
              right: 8,
            ),
            color: isSelected ? AppColors.selectedItemColor : null,
            child: Row(
              children: [
                Icon(
                  _getIcon(node, isExpanded),
                  size: AppSpacing.iconSize,
                  color: AppColors.textColor,
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
        if (node.type == .directory && isExpanded)
          for (final child in children)
            _FileNodeWidget(
              node: child,
              depth: depth + 1,
              state: state,
              onFileSelected: onFileSelected,
            ),
      ],
    );
  }

  IconData _getIcon(FileNode node, bool isExpanded) {
    if (node.type == .directory) {
      return isExpanded ? Icons.folder_open : Icons.folder;
    }

    final extension = node.name.split('.').last.toLowerCase();
    switch (extension) {
      case 'dart':
        return Icons.code;
      case 'json':
        return Icons.data_object;
      case 'yaml':
      case 'yml':
        return Icons.settings;
      case 'md':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}
