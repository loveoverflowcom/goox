import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/terminal/data/models/terminal_config.dart';
import 'package:goox/features/terminal/presentation/blocs/terminal_bloc.dart';
import 'package:goox_ui/goox_ui.dart';

/// Widget for terminal panel UI
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
    
    return BlocBuilder<TerminalBloc, TerminalState>(
      builder: (context, terminalState) {
        final windowHeight = MediaQuery.of(context).size.height;
        final maxHeight = windowHeight * TerminalConfig.maxHeightRatio;
        final constrainedHeight = terminalState.height.clamp(
          TerminalConfig.minHeight,
          maxHeight,
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: editorTheme.editorBackground,
            border: Border(
              top: BorderSide(color: editorTheme.borderColor),
            ),
          ),
          child: SizedBox(
            height: constrainedHeight,
            child: Column(
              children: [
                _ResizeHandle(currentHeight: terminalState.height),
                const _TerminalHeader(),
                const Expanded(child: _TerminalContent()),
              ],
            ),
          ),
        );
      },
    );
  }
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
          context.read<TerminalBloc>().add(ResizeTerminalEvent(newHeight));
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

final class _TerminalHeader extends StatelessWidget {
  const _TerminalHeader();

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;
    
    return DecoratedBox(
      decoration: BoxDecoration(
        color: editorTheme.tabBarBackground,
        border: Border(
          bottom: BorderSide(color: editorTheme.borderColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Text(
              'TERMINAL',
              style: TextStyle(
                color: editorTheme.textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TerminalContent extends StatelessWidget {
  const _TerminalContent();

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          'Terminal (dummy version - PTY not implemented)',
          style: TextStyle(
            color: editorTheme.textColorDimmed,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
