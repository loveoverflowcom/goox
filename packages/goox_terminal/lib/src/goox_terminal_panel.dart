import 'package:flutter/material.dart';

import 'package:goox_terminal/src/goox_terminal_session_view.dart';

const double _terminalResizeHandleHeight = 4;
const double _terminalTabHeaderHeight = 36;
const double _terminalCollapsedHeight =
    _terminalResizeHandleHeight + _terminalTabHeaderHeight;
const double _terminalMinExpandedHeight = 140;

final class GooxTerminalPanel extends StatefulWidget {
  const GooxTerminalPanel({
    super.key,
    this.maxLines = 10000,
    this.enableDebug = false,
    this.backgroundColor,
    this.backgroundOpacity = 0.95,
    this.expandedHeight = 300,
  });

  final int maxLines;
  final bool enableDebug;
  final Color? backgroundColor;
  final double backgroundOpacity;
  final double expandedHeight;

  @override
  State<GooxTerminalPanel> createState() => _GooxTerminalPanelState();
}

final class _GooxTerminalPanelState extends State<GooxTerminalPanel>
    with SingleTickerProviderStateMixin {
  final List<_TerminalSession> _sessions = <_TerminalSession>[];
  int _nextTerminalNumber = 1;
  String? _activeSessionId;
  bool _isCollapsed = false;
  late double _panelHeight;

  @override
  void initState() {
    super.initState();
    _panelHeight = widget.expandedHeight;
    final sessionNumber = _nextTerminalNumber++;
    final session = _TerminalSession(
      id: UniqueKey().toString(),
      title: 'Terminal $sessionNumber',
    );

    _sessions.add(session);
    _activeSessionId = session.id;
  }

  @override
  void dispose() {
    _sessions.clear();
    super.dispose();
  }

  void _createSession() {
    final sessionNumber = _nextTerminalNumber++;
    final session = _TerminalSession(
      id: UniqueKey().toString(),
      title: 'Terminal $sessionNumber',
    );

    setState(() {
      _sessions.add(session);
      _activeSessionId = session.id;
      _isCollapsed = false;
    });
  }

  void _closeSession(String sessionId) {
    final sessionIndex =
        _sessions.indexWhere((session) => session.id == sessionId);
    if (sessionIndex == -1) return;

    setState(() {
      _sessions.removeAt(sessionIndex);

      if (_sessions.isEmpty) {
        _activeSessionId = null;
        return;
      }

      if (_activeSessionId != sessionId) {
        return;
      }

      final nextIndex = sessionIndex >= _sessions.length
          ? _sessions.length - 1
          : sessionIndex;
      _activeSessionId = _sessions[nextIndex].id;
    });
  }

  void _activateSession(String sessionId) {
    if (_activeSessionId == sessionId && !_isCollapsed) return;

    setState(() {
      _isCollapsed = false;
      _activeSessionId = sessionId;
    });
  }

  void _toggleCollapsed() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  void _resizePanel(double deltaDy, BuildContext context) {
    final maxExpandedHeight = MediaQuery.sizeOf(context).height * 0.8;
    final nextHeight = (_panelHeight - deltaDy).clamp(
      _terminalMinExpandedHeight,
      maxExpandedHeight,
    );

    setState(() {
      _panelHeight = nextHeight.toDouble();
      _isCollapsed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = widget.backgroundColor ?? colorScheme.surface;
    final borderColor = colorScheme.outline.withValues(alpha: 0.18);
    final panelHeight = _isCollapsed ? _terminalCollapsedHeight : _panelHeight;
    final terminalBody = _sessions.isEmpty
        ? _EmptyTerminalState(
            onNewTerminal: _createSession,
          )
        : IndexedStack(
            index: (() {
              final activeIndex = _sessions.indexWhere(
                (session) => session.id == _activeSessionId,
              );
              return activeIndex < 0 ? 0 : activeIndex;
            })(),
            children: [
              for (final session in _sessions)
                GooxTerminalSessionView(
                  key: ValueKey(session.id),
                  maxLines: widget.maxLines,
                  enableDebug: widget.enableDebug,
                ),
            ],
          );

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: panelHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border(
              top: BorderSide(color: borderColor),
            ),
          ),
          child: Column(
            children: [
              _TerminalResizeHandle(
                onVerticalDragUpdate: (details) => _resizePanel(
                  details.delta.dy,
                  context,
                ),
              ),
              _TerminalPanelHeader(
                backgroundColor: colorScheme.surfaceContainerHighest,
                borderColor: borderColor,
                sessions: _sessions,
                activeSessionId: _activeSessionId,
                isCollapsed: _isCollapsed,
                onNewTerminal: _createSession,
                onToggleCollapsed: _toggleCollapsed,
                onActivateSession: _activateSession,
                onCloseSession: _closeSession,
              ),
              Expanded(
                child: Visibility(
                  visible: !_isCollapsed,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: false,
                  child: terminalBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TerminalResizeHandle extends StatelessWidget {
  const _TerminalResizeHandle({
    required this.onVerticalDragUpdate,
  });

  final GestureDragUpdateCallback onVerticalDragUpdate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onVerticalDragUpdate,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: SizedBox(
          height: _terminalResizeHandleHeight,
          width: double.infinity,
          child: Center(
            child: Container(
              width: 44,
              height: 2,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _TerminalSession {
  const _TerminalSession({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}

final class _TerminalPanelHeader extends StatelessWidget {
  const _TerminalPanelHeader({
    required this.backgroundColor,
    required this.borderColor,
    required this.sessions,
    required this.activeSessionId,
    required this.isCollapsed,
    required this.onNewTerminal,
    required this.onToggleCollapsed,
    required this.onActivateSession,
    required this.onCloseSession,
  });

  final Color backgroundColor;
  final Color borderColor;
  final List<_TerminalSession> sessions;
  final String? activeSessionId;
  final bool isCollapsed;
  final VoidCallback onNewTerminal;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<String> onActivateSession;
  final ValueChanged<String> onCloseSession;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: _terminalTabHeaderHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sessions.length,
              separatorBuilder: (_, __) => Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: borderColor,
              ),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isActive = session.id == activeSessionId;

                return _TerminalTab(
                  title: session.title,
                  isActive: isActive,
                  onTap: () => onActivateSession(session.id),
                  onClose: () => onCloseSession(session.id),
                  activeColor: colorScheme.primary,
                  inactiveColor: colorScheme.onSurface,
                  backgroundColor: backgroundColor,
                );
              },
            ),
          ),
          IconButton(
            onPressed: onNewTerminal,
            icon: const Icon(Icons.add),
            tooltip: 'New terminal',
            color: colorScheme.onSurface,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          ),
          IconButton(
            onPressed: onToggleCollapsed,
            icon: Icon(isCollapsed ? Icons.keyboard_arrow_up : Icons.remove),
            tooltip: isCollapsed ? 'Show terminal' : 'Hide terminal',
            color: colorScheme.onSurface,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          ),
        ],
      ),
    );
  }
}

final class _TerminalTab extends StatefulWidget {
  const _TerminalTab({
    required this.title,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.activeColor,
    required this.inactiveColor,
    required this.backgroundColor,
  });

  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;

  @override
  State<_TerminalTab> createState() => _TerminalTabState();
}

final class _TerminalTabState extends State<_TerminalTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor =
        widget.isActive ? widget.activeColor : widget.inactiveColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 128, maxWidth: 220),
          color: widget.isActive ? colorScheme.surface : widget.backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.terminal_rounded,
                size: 14,
                color: foregroundColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foregroundColor,
                        fontWeight:
                            widget.isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
              if (_isHovered || widget.isActive)
                GestureDetector(
                  onTap: widget.onClose,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: foregroundColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EmptyTerminalState extends StatelessWidget {
  const _EmptyTerminalState({
    required this.onNewTerminal,
  });

  final VoidCallback onNewTerminal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.terminal_rounded,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No terminal open',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onNewTerminal,
            icon: const Icon(Icons.add),
            label: const Text('New terminal'),
          ),
        ],
      ),
    );
  }
}
