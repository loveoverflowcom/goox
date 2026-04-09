import 'package:flutter/material.dart';

import 'package:goox_terminal/src/controllers/terminal_controller.dart';
import 'package:goox_terminal/src/controllers/terminal_session_manager.dart';
import 'package:goox_terminal/src/models/terminal_status.dart';
import 'package:goox_terminal/src/ui/terminal_theme.dart';

/// Tab bar widget that displays all terminal tabs and the create button.
///
/// This widget provides:
/// - Display tab for each session
/// - Show active tab indicator
/// - Show terminal status indicators (running, exited, error)
/// - Display terminal title in tab
/// - Handle tab click to switch active session
/// - Handle close button click to close session
/// - Handle new terminal button click to create session
/// - Disable new terminal button when at limit
/// - Show tooltip when at session limit
///
/// Example:
/// ```dart
/// TerminalTabBar(
///   sessionManager: TerminalSessionManager.instance,
///   theme: TerminalTheme.dark(),
/// )
/// ```
class TerminalTabBar extends StatelessWidget {
  /// Creates a terminal tab bar widget.
  ///
  /// Parameters:
  /// - [sessionManager]: The session manager to observe for terminal sessions
  /// - [theme]: Optional theme for tab bar appearance
  const TerminalTabBar({
    required this.sessionManager,
    this.theme,
    super.key,
  });

  /// The terminal session manager.
  final TerminalSessionManager sessionManager;

  /// Theme for tab bar appearance.
  final TerminalTheme? theme;

  @override
  Widget build(BuildContext context) {
    // Listen to session manager changes
    return ListenableBuilder(
      listenable: sessionManager,
      builder: (context, child) {
        final sessions = sessionManager.allSessions;
        final activeSessionId = sessionManager.activeSessionId;
        final canCreateSession = sessionManager.canCreateSession;

        return Container(
          height: 35,
          decoration: BoxDecoration(
            color: _getBackgroundColor(context),
            border: Border(
              bottom: BorderSide(
                color: _getBorderColor(context),
              ),
            ),
          ),
          child: Row(
            children: [
              // Horizontal scrollable list of terminal tabs
              Expanded(
                child: sessions.isEmpty
                    ? Center(
                        child: Text(
                          'No terminals',
                          style: TextStyle(
                            color: _getTextColorDimmed(context),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final controller = sessions[index];
                          final isActive = controller.id == activeSessionId;

                          return _TerminalTab(
                            controller: controller,
                            isActive: isActive,
                            onTap: () {
                              sessionManager.activeSessionId = controller.id;
                            },
                            onClose: () async {
                              await sessionManager.closeSession(controller.id);
                            },
                            theme: theme,
                          );
                        },
                      ),
              ),
              // "+" button to create new terminal
              Tooltip(
                message: canCreateSession
                    ? 'New Terminal (Ctrl+Shift+`)'
                    : 'Maximum 10 terminals reached',
                child: IconButton(
                  icon: Icon(
                    Icons.add,
                    size: 18,
                    color: canCreateSession
                        ? _getTextColor(context)
                        : _getTextColorDimmed(context),
                  ),
                  onPressed: canCreateSession
                      ? () async {
                          await sessionManager.createSession();
                        }
                      : null,
                  splashRadius: 18,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final theme = this.theme ?? TerminalTheme.dark();
    return theme.background;
  }

  Color _getBorderColor(BuildContext context) {
    final theme = this.theme ?? TerminalTheme.dark();
    // Use a slightly lighter color for border
    return Color.alphaBlend(
      theme.foreground.withOpacity(0.2),
      theme.background,
    );
  }

  Color _getTextColor(BuildContext context) {
    final theme = this.theme ?? TerminalTheme.dark();
    return theme.foreground;
  }

  Color _getTextColorDimmed(BuildContext context) {
    final theme = this.theme ?? TerminalTheme.dark();
    return theme.foreground.withOpacity(0.6);
  }
}

/// Individual terminal tab widget that displays in the tab bar.
class _TerminalTab extends StatefulWidget {
  const _TerminalTab({
    required this.controller,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    this.theme,
  });

  final TerminalController controller;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final TerminalTheme? theme;

  @override
  State<_TerminalTab> createState() => _TerminalTabState();
}

class _TerminalTabState extends State<_TerminalTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? TerminalTheme.dark();

    // Determine background color based on active/hover state
    final backgroundColor = widget.isActive
        ? _getActiveTabBackground(theme)
        : _isHovered
            ? _getHoverBackground(theme)
            : _getInactiveTabBackground(theme);

    // Determine text color based on active state
    final textColor = widget.isActive
        ? theme.foreground
        : theme.foreground.withOpacity(0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ValueListenableBuilder<String>(
        valueListenable: widget.controller.titleNotifier,
        builder: (context, title, child) {
          return StreamBuilder<TerminalStatus>(
            stream: widget.controller.statusStream,
            initialData: widget.controller.status,
            builder: (context, snapshot) {
              final status = snapshot.data ?? TerminalStatus.initializing;

              return Tooltip(
                message: _getTooltipMessage(title, status),
                waitDuration: const Duration(milliseconds: 500),
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                    constraints: const BoxConstraints(
                      minWidth: 120,
                      maxWidth: 200,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border(
                        right: BorderSide(
                          color: _getBorderColor(theme),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Status icon
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            _getStatusIcon(status),
                            size: 14,
                            color: _getStatusColor(status, theme),
                          ),
                        ),
                        // Terminal title with ellipsis overflow
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        // Close button - only visible on hover
                        if (_isHovered)
                          Tooltip(
                            message: 'Close Terminal',
                            waitDuration: const Duration(milliseconds: 500),
                            child: GestureDetector(
                              onTap: widget.onClose,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getActiveTabBackground(TerminalTheme theme) {
    // Slightly lighter than background for active tab
    return Color.alphaBlend(
      theme.foreground.withOpacity(0.1),
      theme.background,
    );
  }

  Color _getInactiveTabBackground(TerminalTheme theme) {
    // Slightly darker than background for inactive tab
    return Color.alphaBlend(
      Colors.black.withOpacity(0.1),
      theme.background,
    );
  }

  Color _getHoverBackground(TerminalTheme theme) {
    // Between active and inactive
    return Color.alphaBlend(
      theme.foreground.withOpacity(0.05),
      theme.background,
    );
  }

  Color _getBorderColor(TerminalTheme theme) {
    return Color.alphaBlend(
      theme.foreground.withOpacity(0.2),
      theme.background,
    );
  }

  /// Get status icon based on terminal state
  IconData _getStatusIcon(TerminalStatus status) {
    switch (status) {
      case TerminalStatus.initializing:
        return Icons.hourglass_empty;
      case TerminalStatus.running:
        return Icons.terminal;
      case TerminalStatus.exited:
        return Icons.check_circle_outline;
      case TerminalStatus.error:
        return Icons.error_outline;
    }
  }

  /// Get status color based on terminal state
  Color _getStatusColor(TerminalStatus status, TerminalTheme theme) {
    switch (status) {
      case TerminalStatus.initializing:
        return theme.yellow; // Warning color
      case TerminalStatus.running:
        return theme.green; // Success color
      case TerminalStatus.exited:
        return theme.foreground.withOpacity(0.6); // Dimmed
      case TerminalStatus.error:
        return theme.red; // Error color
    }
  }

  /// Get tooltip message for the tab
  String _getTooltipMessage(String title, TerminalStatus status) {
    final statusText = _getStatusText(status);
    return '$title - $statusText';
  }

  /// Get human-readable status text
  String _getStatusText(TerminalStatus status) {
    switch (status) {
      case TerminalStatus.initializing:
        return 'Initializing';
      case TerminalStatus.running:
        return 'Running';
      case TerminalStatus.exited:
        return 'Exited';
      case TerminalStatus.error:
        return 'Error';
    }
  }
}
