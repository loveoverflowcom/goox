import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/terminal/data/models/terminal_instance.dart';
import 'package:goox/features/terminal/presentation/blocs/terminal_bloc.dart';
import 'package:goox_ui/goox_ui.dart';

/// Individual terminal tab widget that displays in the tab bar
final class TerminalTab extends StatefulWidget {
  /// Creates a terminal tab
  const TerminalTab({
    required this.terminal,
    required this.isActive,
    super.key,
  });

  /// The terminal instance this tab represents
  final TerminalInstance terminal;

  /// Whether this tab is currently active
  final bool isActive;

  @override
  State<TerminalTab> createState() => _TerminalTabState();
}

final class _TerminalTabState extends State<TerminalTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editorTheme = theme.extension<EditorThemeExtension>();

    // Determine background color based on active/hover state
    final backgroundColor = widget.isActive
        ? AppColors.activeTabBackground
        : _isHovered
            ? AppColors.hoverColor
            : AppColors.inactiveTabBackground;

    // Determine text color based on active state
    final textColor = widget.isActive
        ? (editorTheme?.textColor ?? AppColors.textColor)
        : (editorTheme?.textColorDimmed ?? AppColors.textColorDimmed);

    // Get status icon based on terminal state
    final statusIcon = _getStatusIcon();
    final statusColor = _getStatusColor();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: _getTooltipMessage(),
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: () {
            context.read<TerminalBloc>().add(
                  SwitchTerminalEvent(widget.terminal.id),
                );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            constraints: const BoxConstraints(
              minWidth: 120,
              maxWidth: 200,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                right: BorderSide(
                  color: editorTheme?.borderColor ?? AppColors.borderColor,
                ),
              ),
            ),
            child: Row(
              children: [
                // Status icon
                if (statusIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      statusIcon,
                      size: 14,
                      color: statusColor,
                    ),
                  ),
                // Terminal title with ellipsis overflow
                Expanded(
                  child: Text(
                    widget.terminal.title,
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
                      onTap: () {
                        context.read<TerminalBloc>().add(
                              CloseTerminalEvent(widget.terminal.id),
                            );
                      },
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
      ),
    );
  }

  /// Get status icon based on terminal state
  IconData? _getStatusIcon() {
    switch (widget.terminal.status) {
      case TerminalInstanceStatus.initializing:
        return Icons.hourglass_empty;
      case TerminalInstanceStatus.running:
        return Icons.terminal;
      case TerminalInstanceStatus.exited:
        return Icons.check_circle_outline;
      case TerminalInstanceStatus.error:
        return Icons.error_outline;
    }
  }

  /// Get status color based on terminal state
  Color _getStatusColor() {
    switch (widget.terminal.status) {
      case TerminalInstanceStatus.initializing:
        return AppColors.warningColor;
      case TerminalInstanceStatus.running:
        return const Color(0xFF0DBC79); // Green
      case TerminalInstanceStatus.exited:
        return AppColors.textColorDimmed;
      case TerminalInstanceStatus.error:
        return AppColors.errorColor;
    }
  }

  /// Get tooltip message for the tab
  String _getTooltipMessage() {
    final statusText = _getStatusText();
    return '${widget.terminal.title} - $statusText';
  }

  /// Get human-readable status text
  String _getStatusText() {
    switch (widget.terminal.status) {
      case TerminalInstanceStatus.initializing:
        return 'Initializing';
      case TerminalInstanceStatus.running:
        return 'Running';
      case TerminalInstanceStatus.exited:
        return 'Exited';
      case TerminalInstanceStatus.error:
        return 'Error';
    }
  }
}
