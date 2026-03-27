import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
import '../../terminal/terminal.dart';
import '../widgets/activity_bar.dart';
import '../widgets/settings_view.dart';
import '../widgets/sidebar.dart';


class GooxLayout extends StatefulWidget {
  const GooxLayout({
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
  State<GooxLayout> createState() => _GooxLayoutState();
}

class _GooxLayoutState extends State<GooxLayout> {
  int _selectedActivityIndex = 0;
  bool _isSidebarVisible = true;
  bool _isTerminalVisible = false;

  double _terminalHeight = 220.0;
  static const double _minTerminalHeight = 80.0;
  static const double _maxTerminalHeight = 600.0;

  double _sidebarWidth = 300.0;
  static const double _minSidebarWidth = 150.0;
  static const double _maxSidebarWidth = 600.0;

  String _getSidebarTitle(int index) {
    switch (index) {
      case 0:
        return 'Explorer';
      case 1:
        return 'Search';
      case 2:
        return 'Source Control';
      case 3:
        return 'Run and Debug';
      case 4:
        return 'Extensions';
      case 5:
        return 'Settings';
      default:
        return 'Explorer';
    }
  }

  Widget _getSidebarChild(int index) {
    switch (index) {
      case 0:
        return const ExplorerView();
      case 1:
        return const Center(child: Text('Search View'));
      case 2:
        return const Center(child: Text('Source Control'));
      case 3:
        return const Center(child: Text('Run and Debug'));
      case 4:
        return const Center(child: Text('Extensions'));
      case 5:
        return const SettingsView();
      default:
        return const ExplorerView();
    }
  }

  void _toggleTerminal() {
    setState(() => _isTerminalVisible = !_isTerminalVisible);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appState = context.watch<AppState>();

    return CallbackShortcuts(
      bindings: {
        // Ctrl+` to toggle terminal
        const SingleActivator(LogicalKeyboardKey.backquote, control: true):
            _toggleTerminal,
        const SingleActivator(LogicalKeyboardKey.backquote, meta: true):
            _toggleTerminal,
      },
      child: Scaffold(
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
                  if (_isSidebarVisible) ...[
                    Sidebar(
                      title: _getSidebarTitle(_selectedActivityIndex),
                      width: _sidebarWidth,
                      child: _getSidebarChild(_selectedActivityIndex),
                    ),
                    // Sidebar resize handle
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _sidebarWidth = (_sidebarWidth + details.delta.dx)
                                .clamp(_minSidebarWidth, _maxSidebarWidth);
                          });
                        },
                        child: Container(
                          width: 4,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Container(
                      color: colorScheme.surface,
                      child: Column(
                        children: [
                          const _EditorTabHeader(),
                          Expanded(child: widget.editor),
                          // ── Terminal panel ─────────────────────
                          if (_isTerminalVisible) ...[
                            // Resize drag handle for Terminal
                            MouseRegion(
                              cursor: SystemMouseCursors.resizeUpDown,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onVerticalDragUpdate: (details) {
                                  setState(() {
                                    _terminalHeight = (_terminalHeight -
                                            details.delta.dy)
                                        .clamp(
                                            _minTerminalHeight,
                                            _maxTerminalHeight);
                                  });
                                },
                                child: Container(
                                  height: 6,
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Container(
                                      height: 2,
                                      width: 48,
                                      decoration: BoxDecoration(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: _terminalHeight,
                              child: TerminalPanel(
                                workingDirectory: appState.rootPath,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Status bar (with terminal toggle button) ──────────────
            _WrappedStatusBar(
              statusBar: widget.statusBar,
              isTerminalVisible: _isTerminalVisible,
              onToggleTerminal: _toggleTerminal,
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps the existing status bar widget and injects a terminal toggle button.
class _WrappedStatusBar extends StatelessWidget {
  final Widget statusBar;
  final bool isTerminalVisible;
  final VoidCallback onToggleTerminal;

  const _WrappedStatusBar({
    required this.statusBar,
    required this.isTerminalVisible,
    required this.onToggleTerminal,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        statusBar,
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Tooltip(
            message: 'Toggle Terminal (Ctrl+`)',
            child: InkWell(
              onTap: onToggleTerminal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.terminal_rounded,
                  size: 13,
                  color: isTerminalVisible
                      ? const Color(0xFF2C6A84)
                      : const Color(0xFFAAAAAA),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _EditorTabHeader extends StatelessWidget {
  const _EditorTabHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();
    final hasOpenFiles = state.openFiles.isNotEmpty;

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
      child: hasOpenFiles
          ? ListView(
              scrollDirection: Axis.horizontal,
              children: state.openFiles
                  .map(
                    (itemPath) => _TabItem(
                      title: path.basename(itemPath),
                      isSelected: itemPath == state.activeFile,
                      isDirty: state.isFileDirty(itemPath),
                      onTap: () => state.switchTab(itemPath),
                      onClose: () => state.closeFile(itemPath),
                    ),
                  )
                  .toList(growable: false),
            )
          : Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No file open',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.title,
    required this.isSelected,
    required this.isDirty,
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
          color: isSelected
              ? colorScheme.surface
              : colorScheme.surfaceContainerLow,
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
              title.endsWith('.rs')
                  ? Icons.settings_outlined
                  : Icons.description_outlined,
              size: 14,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
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
                        color: isSelected
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: isSelected
                          ? colorScheme.onSurface
                          : Colors.transparent,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
