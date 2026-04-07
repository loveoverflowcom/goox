import 'package:flutter/material.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';
import 'package:goox_ui/goox_ui.dart';

/// Dialog for confirming file or folder deletion.
///
/// Provides:
/// - Warning message with file/folder name
/// - Different messages for file vs folder
/// - Cancel and Delete buttons
/// - Destructive action styling
final class DeleteConfirmationDialog extends StatelessWidget {
  /// Creates a delete confirmation dialog.
  const DeleteConfirmationDialog({
    required this.nodeName,
    required this.nodeType,
    super.key,
  });

  /// The name of the file or folder to be deleted.
  final String nodeName;

  /// The type of the node (file or directory).
  final FileNodeType nodeType;

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;
    final isDirectory = nodeType == FileNodeType.directory;
    
    return AlertDialog(
      backgroundColor: editorTheme.sidebarBackground,
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isDirectory ? 'Delete Folder' : 'Delete File',
            style: TextStyle(
              color: editorTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDirectory
                  ? 'Are you sure you want to delete the folder "$nodeName" and all its contents?'
                  : 'Are you sure you want to delete "$nodeName"?',
              style: TextStyle(
                color: editorTheme.textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      isDirectory
                          ? 'This action cannot be undone. All files and subfolders will be permanently deleted.'
                          : 'This action cannot be undone.',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: editorTheme.textColorDimmed,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
