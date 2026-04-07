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
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;

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
