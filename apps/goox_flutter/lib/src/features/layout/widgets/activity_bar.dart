import 'package:flutter/material.dart';

class ActivityBar extends StatelessWidget {
  const ActivityBar({
    super.key,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _ActivityIcon(
            icon: Icons.copy_rounded,
            isSelected: selectedIndex == 0,
            onTap: () => onSelectedIndexChanged(0),
            label: 'Explorer',
          ),
          _ActivityIcon(
            icon: Icons.search_rounded,
            isSelected: selectedIndex == 1,
            onTap: () => onSelectedIndexChanged(1),
            label: 'Search',
          ),
          _ActivityIcon(
            icon: Icons.account_tree_outlined,
            isSelected: selectedIndex == 2,
            onTap: () => onSelectedIndexChanged(2),
            label: 'Source Control',
          ),
          _ActivityIcon(
            icon: Icons.play_arrow_outlined,
            isSelected: selectedIndex == 3,
            onTap: () => onSelectedIndexChanged(3),
            label: 'Run and Debug',
          ),
          _ActivityIcon(
            icon: Icons.extension_outlined,
            isSelected: selectedIndex == 4,
            onTap: () => onSelectedIndexChanged(4),
            label: 'Extensions',
          ),
          const Spacer(),
          _ActivityIcon(
            icon: Icons.settings_outlined,
            isSelected: selectedIndex == 5,
            onTap: () => onSelectedIndexChanged(5),
            label: 'Settings',
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.label,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
