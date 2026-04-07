import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/terminal/data/models/terminal_instance.dart';
import 'package:goox/features/terminal/presentation/blocs/terminal_bloc.dart';
import 'terminal_tab.dart';
import 'package:goox_ui/goox_ui.dart';

/// Tab bar widget that displays all terminal tabs and the create button
final class TerminalTabBar extends StatelessWidget {
  /// Creates a terminal tab bar
  const TerminalTabBar({
    required this.terminals,
    required this.activeTerminalId,
    required this.canCreateTerminal,
    super.key,
  });

  /// List of all terminal instances
  final List<TerminalInstance> terminals;

  /// ID of the currently active terminal
  final String? activeTerminalId;

  /// Whether a new terminal can be created (count < 10)
  final bool canCreateTerminal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editorTheme = theme.extension<EditorThemeExtension>();

    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: editorTheme?.tabBarBackground ?? AppColors.tabBarBackground,
        border: Border(
          bottom: BorderSide(
            color: editorTheme?.borderColor ?? AppColors.borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Horizontal scrollable list of terminal tabs
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: terminals.length,
              itemBuilder: (context, index) {
                final terminal = terminals[index];
                return TerminalTab(
                  terminal: terminal,
                  isActive: terminal.id == activeTerminalId,
                );
              },
            ),
          ),
          // "+" button to create new terminal
          Tooltip(
            message: 'New Terminal (Ctrl+Shift+`)',
            child: IconButton(
              icon: Icon(
                Icons.add,
                size: 18,
                color: canCreateTerminal
                    ? (editorTheme?.textColor ?? AppColors.textColor)
                    : (editorTheme?.textColorDimmed ??
                        AppColors.textColorDimmed),
              ),
              onPressed: canCreateTerminal
                  ? () {
                      context.read<TerminalBloc>().add(
                            const CreateTerminalEvent(),
                          );
                    }
                  : null,
              splashRadius: 18,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}
