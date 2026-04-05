import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/terminal/data/models/terminal_config.dart';
import 'package:goox/features/terminal/presentation/blocs/terminal_bloc.dart';
import 'package:goox_ui/goox_ui.dart';

/// Widget for terminal panel UI
class TerminalPanelWidget extends StatefulWidget {
  /// Constructor
  const TerminalPanelWidget({super.key});

  @override
  State<TerminalPanelWidget> createState() => _TerminalPanelWidgetState();
}

class _TerminalPanelWidgetState extends State<TerminalPanelWidget> {
  double? _dragStartHeight;

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

        return Container(
          height: constrainedHeight,
          decoration: BoxDecoration(
            color: editorTheme.editorBackground,
            border: Border(
              top: BorderSide(color: editorTheme.borderColor),
            ),
          ),
          child: Column(
            children: [
              // Resize handle
              _buildResizeHandle(context, terminalState.height),

              // Header
              _buildHeader(context),

              // Content area
              Expanded(
                child: _buildContent(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResizeHandle(BuildContext context, double currentHeight) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;
    
    return GestureDetector(
      onVerticalDragStart: (details) {
        _dragStartHeight = currentHeight;
      },
      onVerticalDragUpdate: (details) {
        if (_dragStartHeight != null) {
          final newHeight = _dragStartHeight! - details.delta.dy;
          context.read<TerminalBloc>().add(ResizeTerminalEvent(newHeight));
        }
      },
      onVerticalDragEnd: (details) {
        _dragStartHeight = null;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: Container(
          height: 4,
          color: Colors.transparent,
          child: Center(
            child: Container(
              height: 1,
              color: editorTheme.borderColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: editorTheme.tabBarBackground,
        border: Border(
          bottom: BorderSide(color: editorTheme.borderColor),
        ),
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
    );
  }

  Widget _buildContent(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;
    
    return Container(
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
