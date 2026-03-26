import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
import '../widgets/activity_bar.dart';
import '../widgets/sidebar.dart';
import '../widgets/settings_view.dart';
import 'package:path/path.dart' as p;

class VscodeLayout extends StatefulWidget {
  const VscodeLayout({
    super.key,
    required this.editor,
    required this.statusBar,
    this.sidebarTitle = 'Explorer',
    this.sidebarChild = const ExplorerView(),
  });

  final Widget editor;
  final Widget statusBar;
  final String sidebarTitle;
  final Widget sidebarChild;

  @override
  State<VscodeLayout> createState() => _VscodeLayoutState();
}

class _VscodeLayoutState extends State<VscodeLayout> {
  int _selectedActivityIndex = 0;
  bool _isSidebarVisible = true;

  String _getSidebarTitle(int index) {
    switch (index) {
      case 0: return 'Explorer';
      case 1: return 'Search';
      case 2: return 'Source Control';
      case 3: return 'Run and Debug';
      case 4: return 'Extensions';
      case 5: return 'Settings';
      default: return 'Explorer';
    }
  }

  Widget _getSidebarChild(int index) {
    switch (index) {
      case 0: return const ExplorerView();
      case 1: return const Center(child: Text('Search View'));
      case 2: return const Center(child: Text('Source Control'));
      case 3: return const Center(child: Text('Run and Debug'));
      case 4: return const Center(child: Text('Extensions'));
      case 5: return const SettingsView();
      default: return const ExplorerView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                ActivityBar(
                  selectedIndex: _selectedActivityIndex,
                  onSelectedIndexChanged: (index) {
                    setState(() {
                      if (_selectedActivityIndex == index) {
                        _isSidebarVisible = !_isSidebarVisible;
                      } else {
                        _selectedActivityIndex = index;
                        _isSidebarVisible = true;
                      }
                    });
                  },
                ),
                if (_isSidebarVisible)
                  Sidebar(
                    title: _getSidebarTitle(_selectedActivityIndex),
                    child: _getSidebarChild(_selectedActivityIndex),
                  ),
                Expanded(
                  child: Container(
                    color: colorScheme.surface,
                    child: Column(
                      children: [
                        _EditorTabHeader(),
                        Expanded(child: widget.editor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          widget.statusBar,
        ],
      ),
    );
  }
}

class _EditorTabHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();

    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: state.openFiles.map((path) {
          final title = p.basename(path);
          final isSelected = path == state.activeFile;
          final isDirty = state.isFileDirty(path);
          return _TabItem(
            title: title, 
            isSelected: isSelected,
            isDirty: isDirty,
            onTap: () => state.switchTab(path),
            onClose: () => state.closeFile(path),
          );
        }).toList(),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.title, 
    required this.isSelected,
    this.isDirty = false,
    required this.onTap,
    required this.onClose,
  });

  final String title;
  final bool isSelected;
  final bool isDirty;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : colorScheme.surfaceContainerLow,
          border: Border(
            right: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 0.5,
            ),
            top: BorderSide(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              title.endsWith('.rs') ? Icons.settings_outlined : Icons.description_outlined,
              size: 14,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onClose,
              child: isDirty
                ? Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    ),
                  )
                : Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: isSelected ? colorScheme.onSurface : Colors.transparent,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBar extends StatelessWidget {
  const StatusBar({
    super.key,
    required this.revision,
    required this.line,
    required this.column,
  });

  final int revision;
  final int line;
  final int column;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary,
      ),
      child: Row(
        children: [
          Icon(Icons.sync_rounded, size: 12, color: colorScheme.onPrimary),
          const SizedBox(width: 4),
          Text(
            'main*',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Icon(Icons.error_outline_rounded, size: 12, color: colorScheme.onPrimary),
          const SizedBox(width: 4),
          Text(
            '0',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Icon(Icons.warning_amber_rounded, size: 12, color: colorScheme.onPrimary),
          const SizedBox(width: 4),
          Text(
            '0',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
          ),
          const Spacer(),
          Text(
            'Revision: $revision',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Text(
            'Ln $line, Col $column',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Text(
            'Spaces: 4',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Text(
            'UTF-8',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
          ),
          const SizedBox(width: 12),
          const SizedBox(width: 12),
          Text(
            'Dart',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.read<AppState>().toggleTheme(),
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                IconData iconData;
                switch (appState.themeMode) {
                  case ThemeMode.system:
                    iconData = Icons.brightness_auto_rounded;
                    break;
                  case ThemeMode.light:
                    iconData = Icons.light_mode_rounded;
                    break;
                  case ThemeMode.dark:
                    iconData = Icons.dark_mode_rounded;
                    break;
                }
                return Icon(
                  iconData,
                  size: 14,
                  color: colorScheme.onPrimary,
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.notifications_none_rounded, size: 12, color: colorScheme.onPrimary),
        ],
      ),
    );
  }
}
