import 'package:flutter/material.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';

/// Widget hiển thị context menu cho file explorer.
///
/// Menu items thay đổi dựa trên loại node:
/// - File: Rename, Copy Path, Delete
/// - Folder: New File, New Folder, Rename, Copy Path, Delete
/// - Empty area (node == null): New File, New Folder
final class FileNodeContextMenu extends StatelessWidget {
  /// Creates a context menu widget.
  const FileNodeContextMenu({
    required this.position,
    required this.onNewFile,
    required this.onNewFolder,
    this.node,
    this.onRename,
    this.onDelete,
    this.onCopyPath,
    super.key,
  });

  /// Node được click (null nếu click vào vùng trống).
  final FileNode? node;

  /// Vị trí hiển thị menu.
  final Offset position;

  /// Callback khi chọn "New File".
  final VoidCallback onNewFile;

  /// Callback khi chọn "New Folder".
  final VoidCallback onNewFolder;

  /// Callback khi chọn "Rename".
  final VoidCallback? onRename;

  /// Callback khi chọn "Delete".
  final VoidCallback? onDelete;

  /// Callback khi chọn "Copy Path".
  final VoidCallback? onCopyPath;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      itemBuilder: (context) => _buildMenuItems(),
      onSelected: _handleMenuSelection,
      popUpAnimationStyle: AnimationStyle.noAnimation,
    );
  }

  /// Build menu items dựa trên node type.
  List<PopupMenuEntry<String>> _buildMenuItems() {
    if (node == null) {
      // Empty area menu: New File, New Folder
      return [
        const PopupMenuItem<String>(
          value: 'new_file',
          child: Row(
            children: [
              Icon(Icons.note_add_outlined, size: 18),
              SizedBox(width: 8),
              Text('New File'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'new_folder',
          child: Row(
            children: [
              Icon(Icons.create_new_folder_outlined, size: 18),
              SizedBox(width: 8),
              Text('New Folder'),
            ],
          ),
        ),
      ];
    } else if (node!.type == FileNodeType.directory) {
      // Folder menu: New File, New Folder, Rename, Copy Path, Delete
      return [
        const PopupMenuItem<String>(
          value: 'new_file',
          child: Row(
            children: [
              Icon(Icons.note_add_outlined, size: 18),
              SizedBox(width: 8),
              Text('New File'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'new_folder',
          child: Row(
            children: [
              Icon(Icons.create_new_folder_outlined, size: 18),
              SizedBox(width: 8),
              Text('New Folder'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'copy_path',
          child: Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('Copy Path'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ];
    } else {
      // File menu: Rename, Copy Path, Delete
      return [
        const PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'copy_path',
          child: Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('Copy Path'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
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

  /// Handle menu selection.
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'new_file':
        onNewFile();
      case 'new_folder':
        onNewFolder();
      case 'rename':
        onRename?.call();
      case 'delete':
        onDelete?.call();
      case 'copy_path':
        onCopyPath?.call();
    }
  }
}
