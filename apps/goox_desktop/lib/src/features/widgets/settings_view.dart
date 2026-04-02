// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import 'package:goox_ui_shared/goox_ui_shared.dart';

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
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 0,
            ),
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
              _buildThemeOption(context, 'System', ThemeMode.system, state),
              _buildThemeOption(context, 'Light', ThemeMode.light, state),
              _buildThemeOption(context, 'Dark', ThemeMode.dark, state),
            ],
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 0,
            ),
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
              _buildFontFamilyOption(context, state, colorScheme),
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

  Widget _buildFontFamilyOption(
    BuildContext context,
    AppState state,
    ColorScheme colorScheme,
  ) {
    final currentFont = state.settings.fontFamily ?? 'System Monospace';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Font Family', style: TextStyle(fontSize: 12)),
              TextButton(
                onPressed: () => _showFontPicker(context, state),
                child: const Text('Choose'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentFont,
                  style: _fontPreviewStyle(
                    context,
                    colorScheme,
                    state.settings.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The quick brown fox jumps over 0123456789',
                  style: _fontPreviewStyle(
                    context,
                    colorScheme,
                    state.settings.fontFamily,
                    fontSize: 13,
                    fontWeight: state.settings.fontWeight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFontPicker(BuildContext context, AppState state) async {
    final allFonts = editorFontChoices();
    var search = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = allFonts
                .where(
                  (font) => font.toLowerCase().contains(search.toLowerCase()),
                )
                .toList(growable: false);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Editor Font',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search fonts',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          search = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 360,
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final font = filtered[index];
                          final selected = state.settings.fontFamily == font;
                          return ListTile(
                            dense: true,
                            selected: selected,
                            title: Text(
                              font,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                fontFamily: font,
                                fontFamilyFallback: const ['monospace'],
                              ),
                            ),
                            subtitle: Text(
                              isGoogleMonospaceFont(font)
                                  ? 'Google Fonts'
                                  : 'System / fallback',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: selected
                                ? Icon(
                                    Icons.check,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              state.setEditorSettings(fontFamily: font);
                              Navigator.of(sheetContext).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  TextStyle _fontPreviewStyle(
    BuildContext context,
    ColorScheme colorScheme,
    String? fontFamily, {
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    final base = TextStyle(
      color: colorScheme.onSurface,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );

    if (fontFamily == null || fontFamily.trim().isEmpty) {
      return base.copyWith(fontFamily: 'monospace');
    }

    if (isGoogleMonospaceFont(fontFamily)) {
      return GoogleFonts.getFont(fontFamily, textStyle: base);
    }

    return base.copyWith(
      fontFamily: fontFamily,
      fontFamilyFallback: const ['monospace'],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    ThemeMode mode,
    AppState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return RadioListTile<ThemeMode>(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
      title: Text(title, style: const TextStyle(fontSize: 12)),
      value: mode,
      groupValue: state.themeMode,
      activeColor: colorScheme.primary,
      onChanged: (m) => state.setThemeMode(m!),
    );
  }
}
