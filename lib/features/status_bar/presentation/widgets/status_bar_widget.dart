import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/editor_content/presentation/blocs/editor_content_bloc.dart';
import 'package:goox/features/editor_content/presentation/blocs/editor_content_state.dart';
import 'package:goox_ui/goox_ui.dart';

final class StatusBarWidget extends StatelessWidget {
  const StatusBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorContentBloc, EditorContentState>(
      builder: (context, state) {
        return Container(
          height: AppSpacing.statusBarHeight,
          color: AppColors.statusBarBackground,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (state.content != null) ...[
                _buildStatusItem(
                  'Ln ${state.cursorPosition.line}, Col ${state.cursorPosition.column}',
                ),
                const SizedBox(width: AppSpacing.lg),
                _buildStatusItem(state.content!.language),
                const SizedBox(width: AppSpacing.lg),
                _buildStatusItem(state.content!.encoding),
                const Spacer(),
                _buildStatusItem('${state.totalLines} lines'),
                if (state.isModified) ...[
                  const SizedBox(width: AppSpacing.lg),
                  _buildStatusItem('Modified'),
                ],
              ] else
                _buildStatusItem('Ready'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
    );
  }
}
