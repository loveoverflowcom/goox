import 'package:flutter/material.dart';

import 'goox_layout.dart';

class GooxSearchTab extends GooxWidgetTab {
  GooxSearchTab({
    super.id = 'search',
    super.title = 'Search',
  }) : super(
          icon: Icons.search_rounded,
          builder: _buildTab,
        );

  static Widget _buildTab(BuildContext context) {
    return const GooxSearchTabView();
  }
}

class GooxSearchTabView extends StatelessWidget {
  const GooxSearchTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Search across your workspace',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This shared search tab can be reused by any Goox-based app and replaced with a richer implementation later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
