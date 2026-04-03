import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/tab_manager/presentation/blocs/tab_manager_bloc.dart';
import 'package:goox/features/tab_manager/presentation/blocs/tab_manager_event.dart';
import 'package:goox/features/tab_manager/presentation/blocs/tab_manager_state.dart';
import 'package:goox_ui/goox_ui.dart';

final class TabBarWidget extends StatelessWidget {
  const TabBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabManagerBloc, TabManagerState>(
      builder: (context, state) {
        if (state.tabs.isEmpty) {
          return Container(
            height: AppSpacing.tabHeight,
            color: AppColors.tabBarBackground,
          );
        }

        return Container(
          height: AppSpacing.tabHeight,
          decoration: const BoxDecoration(
            color: AppColors.tabBarBackground,
            border: Border(
              bottom: BorderSide(color: AppColors.borderColor),
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
                  onTap: () {
                    context.read<TabManagerBloc>().add(ActivateTabEvent(tab.id));
                  },
                  onClose: () {
                    context.read<TabManagerBloc>().add(CloseTabEvent(tab.id));
                  },
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
                ? AppColors.activeTabBackground
                : AppColors.inactiveTabBackground,
            border: const Border(
              right: BorderSide(color: AppColors.borderColor),
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
                color: AppColors.textColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  widget.fileName,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 13,
                    fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isModified)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: AppSpacing.xs),
                  decoration: const BoxDecoration(
                    color: AppColors.modifiedIndicator,
                    shape: BoxShape.circle,
                  ),
                ),
              if (isHovered || widget.isActive)
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    margin: const EdgeInsets.only(left: AppSpacing.xs),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textColor,
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
