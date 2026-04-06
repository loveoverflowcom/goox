import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/editor_content/presentation/blocs/editor_content_bloc.dart';
import 'package:goox_ui/goox_ui.dart';

final class StatusBarWidget extends StatelessWidget {
  const StatusBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorContentBloc, EditorContentState>(
      builder: (context, state) {
        return Container(
          height: AppSpacing.statusBarHeight,
          color: Theme.of(context).extension<EditorThemeExtension>()!.statusBarBackground,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (state.content != null) ...[
                _buildStatusItem(
                  context,
                  'Ln ${state.cursorPosition.line}, Col ${state.cursorPosition.column}',
                ),
                const SizedBox(width: AppSpacing.lg),
                _buildStatusItem(context, state.content!.language),
                const SizedBox(width: AppSpacing.lg),
                _buildStatusItem(context, state.content!.encoding),
                const Spacer(),
                _buildStatusItem(context, '${state.totalLines} lines'),
                if (state.isModified) ...[
                  const SizedBox(width: AppSpacing.lg),
                  _buildStatusItem(context, 'Modified'),
                ],
              ] else
                _buildStatusItem(context, 'Ready'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontSize: 12,
      ),
    );
  }
}
