import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/theme/data/models/theme_mode.dart';
import 'package:goox/features/theme/presentation/blocs/theme_bloc.dart';
import 'package:goox_ui/goox_ui.dart';

/// Widget for selecting theme mode
final class ThemeSelectorWidget extends StatelessWidget {
  const ThemeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
          ),
          expansionAnimationStyle: const AnimationStyle(duration: .zero),
          childrenPadding: EdgeInsets.zero,
          title: const Text(
            'Theme',
            style: TextStyle(
              color: AppColors.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          iconColor: AppColors.textColor,
          collapsedIconColor: AppColors.textColor,
          children: [
            for (final mode in <AppThemeMode>[
              .system,
              .light,
              .dark,
            ])
              _ThemeOption(
                mode: mode,
                currentMode: state.themeMode,
              ),
          ],
        );
      },
    );
  }
}

final class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.currentMode,
  });

  final AppThemeMode mode;
  final AppThemeMode currentMode;

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;
    final colorScheme = Theme.of(context).colorScheme;

    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurfaceVariant;

    return ListTile(
      dense: true,
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 16,
        color: isSelected ? selectedColor : unselectedColor,
      ),
      title: Text(
        mode.displayName,
        style: TextStyle(
          color: isSelected ? selectedColor : unselectedColor,
          fontSize: 13,
        ),
      ),
      onTap: () {
        context.read<ThemeBloc>().add(SelectThemeEvent(mode));
      },
    );
  }
}
