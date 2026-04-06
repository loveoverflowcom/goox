import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/tab_manager/presentation/blocs/tab_manager_bloc.dart';
import 'package:goox_ui/goox_ui.dart';

final class TabBarWidget extends StatelessWidget {
  const TabBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return BlocBuilder<TabManagerBloc, TabManagerState>(
      builder: (context, state) {
        if (state.tabs.isEmpty) {
          return Container(
            height: AppSpacing.tabHeight,
            color: colorScheme.surface,
          );
        }

        return Container(
          height: AppSpacing.tabHeight,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final tab in state.tabs)
                _TabItem(
                  fileName: tab.fileName,
                  isActive: tab.id == state.activeTabId,
                  isModified: tab.isModified,
                  onTap: () => context
                      .read<TabManagerBloc>()
                      .add(ActivateTabEvent(tabId: tab.id)),
                  onClose: () => context
                      .read<TabManagerBloc>()
                      .add(CloseTabEvent(tab.id)),
                ),
            ],
          ),
        );
      },
    );
  }
}

final class _TabItem extends StatefulWidget {
  const _TabItem({
    required this.fileName,
    required this.isActive,
    required this.isModified,
    required this.onTap,
    required this.onClose,
  });
  
  final String fileName;
  final bool isActive;
  final bool isModified;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  State<_TabItem> createState() => _TabItemState();
}

final class _TabItemState extends State<_TabItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.tabMinWidth,
            maxWidth: AppSpacing.tabMaxWidth,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(
                color: widget.isActive
                    ? colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
              right: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.tabPadding,
            vertical: 8,
          ),
          child: Row(
            children: [
              Icon(
                _getFileIcon(widget.fileName),
                size: 14,
                color: colorScheme.onSurface,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  widget.fileName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: widget.isActive
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isModified)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              if (isHovered || widget.isActive)
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    margin: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'dart' => Icons.code,
      'json' => Icons.data_object,
      'yaml' || 'yml' => Icons.settings,
      'md' => Icons.description,
      _ => Icons.insert_drive_file,
    };
  }
}
