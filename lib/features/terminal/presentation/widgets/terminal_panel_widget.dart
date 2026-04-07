import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/terminal/data/models/terminal_config.dart';
import 'package:goox/features/terminal/data/models/terminal_session.dart';
import 'package:goox/features/terminal/presentation/blocs/terminal_panel_bloc.dart';
import 'package:goox_terminal/goox_terminal.dart';
import 'package:goox_ui/goox_ui.dart';

/// Widget for terminal panel UI
///
/// This widget is simplified to only handle:
/// - Panel visibility and sizing
/// - Integration with goox_terminal widgets
/// - Resize handle
///
/// All terminal UI is delegated to goox_terminal package.
final class TerminalPanelWidget extends StatefulWidget {
  /// Constructor
  const TerminalPanelWidget({super.key});

  @override
  State<TerminalPanelWidget> createState() => _TerminalPanelWidgetState();
}

final class _TerminalPanelWidgetState extends State<TerminalPanelWidget> {
  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;

    return BlocBuilder<TerminalPanelBloc, TerminalPanelState>(
      builder: (context, panelState) {
        // Hide panel when not visible
        if (!panelState.isVisible) {
          return const SizedBox.shrink();
        }

        final windowHeight = MediaQuery.of(context).size.height;
        final maxHeight = windowHeight * TerminalConfig.maxHeightRatio;
        final constrainedHeight = panelState.height.clamp(
          TerminalConfig.minHeight,
          maxHeight,
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: editorTheme.editorBackground,
            border: Border(
              top: BorderSide(color: editorTheme.borderColor),
            ),
            // Add subtle shadow to separate from editor area
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            height: constrainedHeight,
            child: Column(
              children: [
                _ResizeHandle(currentHeight: panelState.height),
                // Terminal tab bar from goox_terminal
                _TerminalTabBarAdapter(
                  sessions: panelState.sessions,
                  activeSessionId: panelState.activeSessionId,
                  canCreateSession: panelState.canCreateSession,
                ),
                // Terminal emulator from goox_terminal
                Expanded(
                  child: panelState.activeSession != null
                      ? _TerminalEmulatorAdapter(
                          session: panelState.activeSession!,
                        )
                      : const _EmptyTerminalView(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Adapter widget for TerminalTabBar from goox_terminal
class _TerminalTabBarAdapter extends StatelessWidget {
  const _TerminalTabBarAdapter({
    required this.sessions,
    required this.activeSessionId,
    required this.canCreateSession,
  });

  final List<TerminalSession> sessions;
  final String? activeSessionId;
  final bool canCreateSession;

  @override
  Widget build(BuildContext context) {
    return TerminalTabBar(
      terminals: sessions.map((s) => _SessionAdapter(s)).toList(),
      activeTerminalId: activeSessionId,
      canCreateTerminal: canCreateSession,
    );
  }
}

/// Adapter widget for TerminalEmulator from goox_terminal
class _TerminalEmulatorAdapter extends StatelessWidget {
  const _TerminalEmulatorAdapter({
    required this.session,
  });

  final TerminalSession session;

  @override
  Widget build(BuildContext context) {
    return TerminalEmulator(
      terminal: _SessionAdapter(session),
    );
  }
}

/// Adapter to make TerminalSession compatible with goox_terminal widgets
class _SessionAdapter {
  _SessionAdapter(this.session);

  final TerminalSession session;

  String get id => session.id;
  String get title => session.title;
  TerminalStatus get status => session.status;
  TerminalOutput get output => session.controller.output;
}

final class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({required this.currentHeight});

  final double currentHeight;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

final class _ResizeHandleState extends State<_ResizeHandle> {
  double? _dragStartHeight;
  double? _dragStartY;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;

    return GestureDetector(
      onVerticalDragStart: (details) {
        setState(() {
          _dragStartHeight = widget.currentHeight;
          _dragStartY = details.globalPosition.dy;
        });
      },
      onVerticalDragUpdate: (details) {
        if (_dragStartHeight != null && _dragStartY != null) {
          final deltaY = _dragStartY! - details.globalPosition.dy;
          final newHeight = _dragStartHeight! + deltaY;
          context.read<TerminalPanelBloc>().add(
                ResizeTerminalPanelEvent(newHeight),
              );
        }
      },
      onVerticalDragEnd: (details) {
        setState(() {
          _dragStartHeight = null;
          _dragStartY = null;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: ColoredBox(
          color: _isHovered
              ? editorTheme.borderColor.withValues(alpha: 0.3)
              : Colors.transparent,
          child: SizedBox(
            height: 8,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: ColoredBox(
                  color: _isHovered
                      ? editorTheme.borderColor.withValues(alpha: 0.8)
                      : editorTheme.borderColor,
                  child: const SizedBox(
                    height: 2,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty terminal view shown when no terminals are active
final class _EmptyTerminalView extends StatelessWidget {
  const _EmptyTerminalView();

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.terminal,
            size: 48,
            color: editorTheme.textColorDimmed,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No active terminal',
            style: TextStyle(
              color: editorTheme.textColorDimmed,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Press Ctrl+Shift+` to create a new terminal',
            style: TextStyle(
              color: editorTheme.textColorDimmed,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
