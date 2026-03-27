import 'package:flutter/material.dart';

enum GooxTabAlignment { top, bottom }

abstract interface class GooxTab {
  String get id;
  String get title;
  IconData get icon;
  GooxTabAlignment get alignment;
  Widget build(BuildContext context);
}

class GooxWidgetTab implements GooxTab {
  const GooxWidgetTab({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
    this.alignment = GooxTabAlignment.top,
  });

  @override
  final String id;

  @override
  final String title;

  @override
  final IconData icon;

  final WidgetBuilder builder;

  @override
  final GooxTabAlignment alignment;

  @override
  Widget build(BuildContext context) => builder(context);
}

abstract interface class GooxPanel {
  String get id;
  String get title;
  IconData get icon;
  List<ShortcutActivator> get shortcuts;
  Widget build(BuildContext context);
}

class GooxWidgetPanel implements GooxPanel {
  const GooxWidgetPanel({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
    this.shortcuts = const <ShortcutActivator>[],
  });

  @override
  final String id;

  @override
  final String title;

  @override
  final IconData icon;

  final WidgetBuilder builder;

  @override
  final List<ShortcutActivator> shortcuts;

  @override
  Widget build(BuildContext context) => builder(context);
}

class GooxLayout extends StatefulWidget {
  const GooxLayout({
    super.key,
    required this.editor,
    required this.statusBar,
    this.appBar,
    this.editorHeader,
    this.tabs = const <GooxTab>[],
    this.panels = const <GooxPanel>[],
    this.initialSidebarVisible = true,
    this.initialSidebarWidth = 300,
    this.initialPanelHeight = 220,
  });

  final PreferredSizeWidget? appBar;
  final Widget editor;
  final Widget statusBar;
  final Widget? editorHeader;
  final List<GooxTab> tabs;
  final List<GooxPanel> panels;
  final bool initialSidebarVisible;
  final double initialSidebarWidth;
  final double initialPanelHeight;

  static void togglePanel(BuildContext context, String panelId) {
    context.findAncestorStateOfType<_GooxLayoutState>()?._togglePanel(panelId);
  }

  @override
  State<GooxLayout> createState() => _GooxLayoutState();
}

class _GooxLayoutState extends State<GooxLayout> {
  static const double _minSidebarWidth = 150.0;
  static const double _maxSidebarWidth = 600.0;
  static const double _minPanelHeight = 80.0;
  static const double _maxPanelHeight = 600.0;

  late bool _isSidebarVisible;
  late double _sidebarWidth;
  late double _panelHeight;
  int _selectedTabIndex = 0;
  String? _activePanelId;

  @override
  void initState() {
    super.initState();
    _isSidebarVisible = widget.initialSidebarVisible && widget.tabs.isNotEmpty;
    _sidebarWidth = widget.initialSidebarWidth;
    _panelHeight = widget.initialPanelHeight;
  }

  @override
  void didUpdateWidget(covariant GooxLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabs.isEmpty) {
      _selectedTabIndex = 0;
      _isSidebarVisible = false;
    } else if (_selectedTabIndex >= widget.tabs.length) {
      _selectedTabIndex = widget.tabs.length - 1;
    }

    if (_activePanelId != null &&
        widget.panels.every((panel) => panel.id != _activePanelId)) {
      _activePanelId = null;
    }
  }

  GooxTab? get _activeTab {
    if (widget.tabs.isEmpty) {
      return null;
    }
    return widget.tabs[_selectedTabIndex.clamp(0, widget.tabs.length - 1)];
  }

  GooxPanel? get _activePanel {
    final panelId = _activePanelId;
    if (panelId == null) {
      return null;
    }
    for (final panel in widget.panels) {
      if (panel.id == panelId) {
        return panel;
      }
    }
    return null;
  }

  Map<ShortcutActivator, VoidCallback> get _shortcutBindings {
    final bindings = <ShortcutActivator, VoidCallback>{};
    for (final panel in widget.panels) {
      for (final shortcut in panel.shortcuts) {
        bindings[shortcut] = () => _togglePanel(panel.id);
      }
    }
    return bindings;
  }

  void _selectTab(int index) {
    if (_selectedTabIndex == index) {
      setState(() {
        _isSidebarVisible = !_isSidebarVisible;
      });
      return;
    }

    setState(() {
      _selectedTabIndex = index;
      _isSidebarVisible = true;
    });
  }

  void _togglePanel(String panelId) {
    setState(() {
      _activePanelId = _activePanelId == panelId ? null : panelId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeTab = _activeTab;
    final activePanel = _activePanel;

    return CallbackShortcuts(
      bindings: _shortcutBindings,
      child: Scaffold(
        appBar: widget.appBar,
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (widget.tabs.isNotEmpty)
                    _GooxActivityBar(
                      tabs: widget.tabs,
                      selectedIndex: _selectedTabIndex,
                      onSelectedIndexChanged: _selectTab,
                    ),
                  if (_isSidebarVisible && activeTab != null) ...[
                    _GooxSidebar(
                      title: activeTab.title,
                      width: _sidebarWidth,
                      child: activeTab.build(context),
                    ),
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
                        child: Container(width: 4, color: Colors.transparent),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Container(
                      color: colorScheme.surface,
                      child: Column(
                        children: [
                          if (widget.editorHeader != null) widget.editorHeader!,
                          Expanded(child: widget.editor),
                          if (activePanel != null)
                            MouseRegion(
                              cursor: SystemMouseCursors.resizeUpDown,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onVerticalDragUpdate: (details) {
                                  setState(() {
                                    _panelHeight = (_panelHeight - details.delta.dy)
                                        .clamp(_minPanelHeight, _maxPanelHeight);
                                  });
                                },
                                child: Container(
                                  height: 6,
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Container(
                                      height: 2,
                                      width: 56,
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
                          Offstage(
                            offstage: activePanel == null,
                            child: SizedBox(
                              height: _panelHeight,
                              child: Stack(
                                children: [
                                  for (final panel in widget.panels)
                                    Offstage(
                                      offstage: activePanel?.id != panel.id,
                                      child: panel.build(context),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _GooxStatusBarShell(
              statusBar: widget.statusBar,
              panels: widget.panels,
              activePanelId: _activePanelId,
              onTogglePanel: _togglePanel,
            ),
          ],
        ),
      ),
    );
  }
}

class _GooxActivityBar extends StatelessWidget {
  const _GooxActivityBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
  });

  final List<GooxTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 52,
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
          for (var index = 0; index < tabs.length; index++)
            if (tabs[index].alignment == GooxTabAlignment.top)
              _GooxActivityIcon(
                icon: tabs[index].icon,
                label: tabs[index].title,
                isSelected: selectedIndex == index,
                onTap: () => onSelectedIndexChanged(index),
              ),
          const Spacer(),
          for (var index = 0; index < tabs.length; index++)
            if (tabs[index].alignment == GooxTabAlignment.bottom)
              _GooxActivityIcon(
                icon: tabs[index].icon,
                label: tabs[index].title,
                isSelected: selectedIndex == index,
                onTap: () => onSelectedIndexChanged(index),
              ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _GooxActivityIcon extends StatelessWidget {
  const _GooxActivityIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
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
            color: isSelected
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _GooxSidebar extends StatelessWidget {
  const _GooxSidebar({
    required this.title,
    required this.width,
    required this.child,
  });

  final String title;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border(
            right: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _GooxStatusBarShell extends StatelessWidget {
  const _GooxStatusBarShell({
    required this.statusBar,
    required this.panels,
    required this.activePanelId,
    required this.onTogglePanel,
  });

  final Widget statusBar;
  final List<GooxPanel> panels;
  final String? activePanelId;
  final ValueChanged<String> onTogglePanel;

  @override
  Widget build(BuildContext context) {
    if (panels.isEmpty) {
      return statusBar;
    }

    return Stack(
      children: [
        statusBar,
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Wrap(
              spacing: 8,
              children: [
                for (final panel in panels)
                  _GooxPanelButton(
                    panel: panel,
                    isActive: activePanelId == panel.id,
                    onTap: () => onTogglePanel(panel.id),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GooxPanelButton extends StatelessWidget {
  const _GooxPanelButton({
    required this.panel,
    required this.isActive,
    required this.onTap,
  });

  final GooxPanel panel;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isActive
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isActive
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Tooltip(
      message: panel.shortcuts.isEmpty
          ? panel.title
          : '${panel.title} (${_shortcutLabel(panel.shortcuts.first)})',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? colorScheme.primary.withValues(alpha: 0.35)
                    : colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(panel.icon, size: 16, color: foregroundColor),
                const SizedBox(width: 6),
                Text(
                  panel.title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _shortcutLabel(ShortcutActivator activator) {
    if (activator is! SingleActivator) {
      return panel.title;
    }

    final pieces = <String>[
      if (activator.control) 'Ctrl',
      if (activator.meta) 'Cmd',
      if (activator.alt) 'Alt',
      if (activator.shift) 'Shift',
      activator.trigger.keyLabel.isEmpty
          ? activator.trigger.debugName ?? panel.title
          : activator.trigger.keyLabel,
    ];
    return pieces.join('+');
  }
}
