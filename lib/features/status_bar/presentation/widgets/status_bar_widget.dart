import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/editor_content/presentation/blocs/editor_content_bloc.dart';
import 'package:goox/features/terminal.dart';
import 'package:goox_ui/goox_ui.dart';

final class StatusBarWidget extends StatelessWidget {
  const StatusBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BlocBuilder<EditorContentBloc, EditorContentState>(
      builder: (context, state) {
        return ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: SizedBox(
            height: AppSpacing.statusBarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (state.fileContent != null) ...[
                    _StatusItem(
                      text: 'Ln ${state.cursorPosition.line}, Col ${state.cursorPosition.column}',
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _StatusItem(text: state.fileContent!.language),
                    const SizedBox(width: AppSpacing.lg),
                    _StatusItem(text: state.fileContent!.encoding),
                    const Spacer(),
                    _StatusItem(text: '${state.totalLines} lines'),
                    if (state.isModified) ...[
                      const SizedBox(width: AppSpacing.lg),
                      _StatusItem(
                        text: 'Modified',
                        color: colorScheme.primary,
                      ),
                    ],
                  ] else ...[
                    const _StatusItem(text: 'Ready'),
                    const Spacer(),
                  ],
                  const SizedBox(width: AppSpacing.lg),
                  const _TerminalButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.text,
    this.color,
  });

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Text(
      text,
      style: TextStyle(
        color: color ?? colorScheme.onSurface.withValues(alpha: 0.7),
        fontSize: 12,
      ),
    );
  }
}

final class _TerminalButton extends StatelessWidget {
  const _TerminalButton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BlocBuilder<TerminalBloc, TerminalState>(
      builder: (context, terminalState) {
        return InkWell(
          onTap: () {
            context.read<TerminalBloc>().add(const ToggleTerminalEvent());
          },
          borderRadius: BorderRadius.circular(4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: terminalState.isVisible
                ? colorScheme.primary.withValues(alpha: 0.2)
                : colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.terminal,
                    size: 16,
                    color: terminalState.isVisible
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Terminal',
                    style: TextStyle(
                      color: terminalState.isVisible
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: terminalState.isVisible 
                        ? FontWeight.w500 
                        : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
