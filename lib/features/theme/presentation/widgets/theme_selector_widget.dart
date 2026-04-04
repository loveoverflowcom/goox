import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/theme/data/models/theme_mode.dart';
import 'package:goox/features/theme/presentation/blocs/theme_bloc.dart';
import 'package:goox_ui/goox_ui.dart';

/// Widget for selecting theme mode
class ThemeSelectorWidget extends StatefulWidget {
  /// Constructor
  const ThemeSelectorWidget({super.key});

  @override
  State<ThemeSelectorWidget> createState() => _ThemeSelectorWidgetState();
}

class _ThemeSelectorWidgetState extends State<ThemeSelectorWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: AppColors.textColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Text(
                      'Theme',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Options (when expanded)
            if (_isExpanded) ...[
              _buildThemeOption(
                context,
                AppThemeMode.dark,
                state.themeMode,
              ),
              _buildThemeOption(
                context,
                AppThemeMode.light,
                state.themeMode,
              ),
              _buildThemeOption(
                context,
                AppThemeMode.system,
                state.themeMode,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    AppThemeMode mode,
    AppThemeMode currentMode,
  ) {
    final isSelected = mode == currentMode;

    return InkWell(
      onTap: () {
        context.read<ThemeBloc>().add(SelectThemeEvent(mode));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 16,
              color: isSelected ? AppColors.accentColor : AppColors.textColor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              mode.displayName,
              style: TextStyle(
                color: isSelected ? AppColors.accentColor : AppColors.textColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
