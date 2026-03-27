// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              'Theme', 
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              )
            ),
            leading: Icon(
              Icons.color_lens_outlined, 
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            children: [
              _buildThemeOption('System', ThemeMode.system, state),
              _buildThemeOption('Light', ThemeMode.light, state),
              _buildThemeOption('Dark', ThemeMode.dark, state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(String title, ThemeMode mode, AppState state) {
    return RadioListTile<ThemeMode>(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
      title: Text(
        title, 
        style: const TextStyle(fontSize: 12),
      ),
      value: mode,
      groupValue: state.themeMode,
      activeColor: Colors.blueAccent,
      onChanged: (m) => state.setThemeMode(m!),
    );
  }
}
