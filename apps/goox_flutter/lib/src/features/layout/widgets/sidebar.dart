import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../../../state/app_state.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.title,
    required this.child,
    this.width = 300, // Task 5: Cho cây thư mục to hơn một chút
  });

  final String title;
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarHeader(title: title),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (title.toLowerCase() == 'explorer')
            InkWell(
              onTap: () => context.read<AppState>().pickDirectory(),
              child: Icon(
                Icons.create_new_folder_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Icon(
              Icons.more_horiz_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class ExplorerView extends StatelessWidget {
  const ExplorerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (state.rootPath == null) {
          return const Center(child: Text('No Folder Opened'));
        }

        final rootName = p.basename(state.rootPath!).toUpperCase();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ExplorerSection(
                title: rootName,
                isExpanded: state.isFolderExpanded(state.rootPath!),
                path: state.rootPath!,
                onToggle: () => state.toggleFolder(state.rootPath!),
                children: state.files.map((e) => _buildTree(e, context, state, 1)).toList(),
              ),
              // OUTLINE removed (Task 2)
            ],
          ),
        );
      },
    );
  }

  Widget _buildTree(FileSystemEntity entity, BuildContext context, AppState state, int level) {
    if (entity is Directory) {
      final isExpanded = state.isFolderExpanded(entity.path);
      List<Widget> children = [];
      if (isExpanded) {
        final childrenEntities = state.getChildren(entity.path);
        children = childrenEntities.map((e) => _buildTree(e, context, state, level + 1)).toList();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FileItem(
            name: p.basename(entity.path),
            path: entity.path,
            isDirectory: true,
            isExpanded: isExpanded,
            level: level,
            onTap: () => state.toggleFolder(entity.path),
            onNewFile: () => state.createNewFile(entity.path),
            onNewFolder: () => state.createNewFolder(entity.path),
          ),
          if (isExpanded) ...children,
        ],
      );
    } else {
      return _FileItem(
        name: p.basename(entity.path),
        path: entity.path,
        isDirectory: false,
        level: level,
        onTap: () => state.openFile(entity.path),
        isSelected: state.activeFile == entity.path,
      );
    }
  }
}

class _ExplorerSection extends StatelessWidget {
  const _ExplorerSection({
    required this.title,
    required this.children,
    required this.path,
    required this.onToggle,
    this.isExpanded = true,
  });

  final String title;
  final List<Widget> children;
  final bool isExpanded;
  final String path;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.read<AppState>();

    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            height: 28,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            padding: const EdgeInsets.only(left: 4, right: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Task 1: tuỳ chọn thêm thư mục, thêm file
                InkWell(
                  onTap: () => state.createNewFile(path),
                  child: const Icon(Icons.note_add_outlined, size: 16),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => state.createNewFolder(path),
                  child: const Icon(Icons.create_new_folder_outlined, size: 16),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...children,
      ],
    );
  }
}

class _FileItem extends StatefulWidget {
  const _FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.isExpanded = false,
    this.level = 0,
    required this.onTap,
    this.isSelected = false,
    this.onNewFile,
    this.onNewFolder,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final bool isExpanded;
  final int level;
  final VoidCallback onTap;
  final bool isSelected;
  final VoidCallback? onNewFile;
  final VoidCallback? onNewFolder;

  @override
  State<_FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<_FileItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: widget.isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : _isHovered
                  ? colorScheme.onSurface.withValues(alpha: 0.05)
                  : Colors.transparent,
          padding: EdgeInsets.only(
            left: 16.0 + (widget.level * 12.0), 
            top: 6, 
            bottom: 6, 
            right: 8,
          ),
          child: Row(
            children: [
              if (widget.isDirectory)
                Icon(
                  widget.isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              if (!widget.isDirectory)
                const SizedBox(width: 4),
              Icon(
                widget.isDirectory ? Icons.folder_open_rounded : Icons.description_outlined,
                size: 18,
                color: widget.isDirectory ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: widget.isSelected ? colorScheme.primary : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Options for creating files/folders locally within this component if hovered/active
              if (widget.isDirectory && _isHovered) ...[
                if (widget.onNewFile != null)
                  InkWell(
                    onTap: widget.onNewFile,
                    child: Icon(Icons.note_add_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(width: 8),
                if (widget.onNewFolder != null)
                  InkWell(
                    onTap: widget.onNewFolder,
                    child: Icon(Icons.create_new_folder_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
