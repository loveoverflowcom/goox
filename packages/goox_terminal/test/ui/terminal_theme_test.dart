import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/src/ui/terminal_theme.dart';

void main() {
  group('TerminalTheme', () {
    test('dark() factory creates theme with correct colors', () {
      final theme = TerminalTheme.dark();

      expect(theme.background, const Color(0xFF1E1E1E));
      expect(theme.foreground, const Color(0xFFCCCCCC));
      expect(theme.cursor, const Color(0xFFAEAFAD));
      expect(theme.selection, const Color(0xFF264F78));

      // Normal ANSI colors
      expect(theme.black, const Color(0xFF000000));
      expect(theme.red, const Color(0xFFCD3131));
      expect(theme.green, const Color(0xFF0DBC79));
      expect(theme.yellow, const Color(0xFFE5E510));
      expect(theme.blue, const Color(0xFF2472C8));
      expect(theme.magenta, const Color(0xFFBC3FBC));
      expect(theme.cyan, const Color(0xFF11A8CD));
      expect(theme.white, const Color(0xFFE5E5E5));

      // Bright ANSI colors
      expect(theme.brightBlack, const Color(0xFF666666));
      expect(theme.brightRed, const Color(0xFFF14C4C));
      expect(theme.brightGreen, const Color(0xFF23D18B));
      expect(theme.brightYellow, const Color(0xFFF5F543));
      expect(theme.brightBlue, const Color(0xFF3B8EEA));
      expect(theme.brightMagenta, const Color(0xFFD670D6));
      expect(theme.brightCyan, const Color(0xFF29B8DB));
      expect(theme.brightWhite, const Color(0xFFFFFFFF));
    });

    test('light() factory creates theme with correct colors', () {
      final theme = TerminalTheme.light();

      expect(theme.background, const Color(0xFFFFFFFF));
      expect(theme.foreground, const Color(0xFF000000));
      expect(theme.cursor, const Color(0xFF000000));
      expect(theme.selection, const Color(0xFFADD6FF));

      // Normal ANSI colors
      expect(theme.black, const Color(0xFF000000));
      expect(theme.red, const Color(0xFFCD3131));
      expect(theme.green, const Color(0xFF00BC00));
      expect(theme.yellow, const Color(0xFF949800));
      expect(theme.blue, const Color(0xFF0451A5));
      expect(theme.magenta, const Color(0xFFBC05BC));
      expect(theme.cyan, const Color(0xFF0598BC));
      expect(theme.white, const Color(0xFF555555));

      // Bright ANSI colors
      expect(theme.brightBlack, const Color(0xFF666666));
      expect(theme.brightRed, const Color(0xFFCD3131));
      expect(theme.brightGreen, const Color(0xFF14CE14));
      expect(theme.brightYellow, const Color(0xFFB5BA00));
      expect(theme.brightBlue, const Color(0xFF0451A5));
      expect(theme.brightMagenta, const Color(0xFFBC05BC));
      expect(theme.brightCyan, const Color(0xFF0598BC));
      expect(theme.brightWhite, const Color(0xFFA5A5A5));
    });

    test('toXTermTheme() converts to xterm TerminalTheme', () {
      final theme = TerminalTheme.dark();
      final xtermTheme = theme.toXTermTheme();

      expect(xtermTheme.background, theme.background);
      expect(xtermTheme.foreground, theme.foreground);
      expect(xtermTheme.cursor, theme.cursor);
      expect(xtermTheme.selection, theme.selection);

      // Normal ANSI colors
      expect(xtermTheme.black, theme.black);
      expect(xtermTheme.red, theme.red);
      expect(xtermTheme.green, theme.green);
      expect(xtermTheme.yellow, theme.yellow);
      expect(xtermTheme.blue, theme.blue);
      expect(xtermTheme.magenta, theme.magenta);
      expect(xtermTheme.cyan, theme.cyan);
      expect(xtermTheme.white, theme.white);

      // Bright ANSI colors
      expect(xtermTheme.brightBlack, theme.brightBlack);
      expect(xtermTheme.brightRed, theme.brightRed);
      expect(xtermTheme.brightGreen, theme.brightGreen);
      expect(xtermTheme.brightYellow, theme.brightYellow);
      expect(xtermTheme.brightBlue, theme.brightBlue);
      expect(xtermTheme.brightMagenta, theme.brightMagenta);
      expect(xtermTheme.brightCyan, theme.brightCyan);
      expect(xtermTheme.brightWhite, theme.brightWhite);

      // Search hit colors should use selection and foreground
      expect(xtermTheme.searchHitBackground, theme.selection);
      expect(xtermTheme.searchHitBackgroundCurrent, theme.selection);
      expect(xtermTheme.searchHitForeground, theme.foreground);
    });

    test('copyWith() creates new theme with updated colors', () {
      final theme = TerminalTheme.dark();
      final newBackground = const Color(0xFF000000);
      final newForeground = const Color(0xFFFFFFFF);

      final updatedTheme = theme.copyWith(
        background: newBackground,
        foreground: newForeground,
      );

      expect(updatedTheme.background, newBackground);
      expect(updatedTheme.foreground, newForeground);
      // Other colors should remain unchanged
      expect(updatedTheme.cursor, theme.cursor);
      expect(updatedTheme.selection, theme.selection);
      expect(updatedTheme.red, theme.red);
    });

    test('all colors are non-null', () {
      final theme = TerminalTheme.dark();

      expect(theme.background, isNotNull);
      expect(theme.foreground, isNotNull);
      expect(theme.cursor, isNotNull);
      expect(theme.selection, isNotNull);
      expect(theme.black, isNotNull);
      expect(theme.red, isNotNull);
      expect(theme.green, isNotNull);
      expect(theme.yellow, isNotNull);
      expect(theme.blue, isNotNull);
      expect(theme.magenta, isNotNull);
      expect(theme.cyan, isNotNull);
      expect(theme.white, isNotNull);
      expect(theme.brightBlack, isNotNull);
      expect(theme.brightRed, isNotNull);
      expect(theme.brightGreen, isNotNull);
      expect(theme.brightYellow, isNotNull);
      expect(theme.brightBlue, isNotNull);
      expect(theme.brightMagenta, isNotNull);
      expect(theme.brightCyan, isNotNull);
      expect(theme.brightWhite, isNotNull);
    });
  });
}
