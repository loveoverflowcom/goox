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
            initiallyExpanded: false,
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
              ),
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
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              'Editor',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            leading: Icon(
              Icons.edit_note_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            children: [
              _buildFontSizeOption(state, colorScheme),
              _buildFontWeightOption(state, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeOption(AppState state, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Font Size', style: TextStyle(fontSize: 12)),
              Text(
                '${state.settings.fontSize.toInt()}px',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: state.settings.fontSize,
            min: 8,
            max: 32,
            divisions: 24,
            label: state.settings.fontSize.toInt().toString(),
            onChanged: (value) {
              state.setEditorSettings(fontSize: value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontWeightOption(AppState state, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Font Weight', style: TextStyle(fontSize: 12)),
          DropdownButton<FontWeight>(
            value: state.settings.fontWeight,
            underline: const SizedBox(),
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
            items: const [
              DropdownMenuItem(value: FontWeight.w300, child: Text('Light')),
              DropdownMenuItem(value: FontWeight.w400, child: Text('Normal')),
              DropdownMenuItem(value: FontWeight.w500, child: Text('Medium')),
              DropdownMenuItem(value: FontWeight.w700, child: Text('Bold')),
            ],
            onChanged: (value) {
              if (value != null) {
                state.setEditorSettings(fontWeight: value);
              }
            },
          ),
        ],
      ),
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
