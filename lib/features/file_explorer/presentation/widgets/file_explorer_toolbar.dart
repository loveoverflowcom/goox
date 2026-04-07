import 'package:flutter/material.dart';
import 'package:goox_ui/goox_ui.dart';

/// Toolbar widget for file explorer with action buttons.
///
/// Displays a toolbar with buttons for creating new files and folders.
/// The toolbar has a fixed height of 40px and a bottom border.
///
/// **Validates: Requirements 1.1, 1.2, 1.3**
final class FileExplorerToolbar extends StatelessWidget {
  /// Creates a file explorer toolbar.
  const FileExplorerToolbar({
    required this.onNewFile,
    required this.onNewFolder,
    super.key,
  });

  /// Callback when the "New File" button is pressed.
  final VoidCallback onNewFile;

  /// Callback when the "New Folder" button is pressed.
  final VoidCallback onNewFolder;

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: editorTheme.borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.insert_drive_file_outlined),
            tooltip: 'New File',
            iconSize: AppSpacing.iconSize,
            color: editorTheme.textColor,
            onPressed: onNewFile,
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New Folder',
            iconSize: AppSpacing.iconSize,
            color: editorTheme.textColor,
            onPressed: onNewFolder,
          ),
        ],
      ),
    );
  }
}
