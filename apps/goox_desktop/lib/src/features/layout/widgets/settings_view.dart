// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      children: [
        ExpansionTile(
          initiallyExpanded: true,
          title: const Text('Theme'),
          leading: const Icon(Icons.color_lens_outlined),
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: state.themeMode,
              onChanged: (mode) => state.setThemeMode(mode!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: state.themeMode,
              onChanged: (mode) => state.setThemeMode(mode!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: state.themeMode,
              onChanged: (mode) => state.setThemeMode(mode!),
            ),
          ],
        ),
      ],
    );
  }
}
