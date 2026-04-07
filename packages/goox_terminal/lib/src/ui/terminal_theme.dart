import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart' as xterm;

/// Theme configuration for terminal widget with full ANSI color support
final class TerminalTheme {
  /// Creates a terminal theme
  const TerminalTheme({
    required this.background,
    required this.foreground,
    required this.cursor,
    required this.selection,
    required this.black,
    required this.red,
    required this.green,
    required this.yellow,
    required this.blue,
    required this.magenta,
    required this.cyan,
    required this.white,
    required this.brightBlack,
    required this.brightRed,
    required this.brightGreen,
    required this.brightYellow,
    required this.brightBlue,
    required this.brightMagenta,
    required this.brightCyan,
    required this.brightWhite,
  });

  /// Dark theme (VS Code style)
  factory TerminalTheme.dark() {
    return const TerminalTheme(
      background: Color(0xFF1E1E1E),
      foreground: Color(0xFFCCCCCC),
      cursor: Color(0xFFAEAFAD),
      selection: Color(0xFF264F78),
      // Normal ANSI colors
      black: Color(0xFF000000),
      red: Color(0xFFCD3131),
      green: Color(0xFF0DBC79),
      yellow: Color(0xFFE5E510),
      blue: Color(0xFF2472C8),
      magenta: Color(0xFFBC3FBC),
      cyan: Color(0xFF11A8CD),
      white: Color(0xFFE5E5E5),
      // Bright ANSI colors
      brightBlack: Color(0xFF666666),
      brightRed: Color(0xFFF14C4C),
      brightGreen: Color(0xFF23D18B),
      brightYellow: Color(0xFFF5F543),
      brightBlue: Color(0xFF3B8EEA),
      brightMagenta: Color(0xFFD670D6),
      brightCyan: Color(0xFF29B8DB),
      brightWhite: Color(0xFFFFFFFF),
    );
  }

  /// Light theme
  factory TerminalTheme.light() {
    return const TerminalTheme(
      background: Color(0xFFFFFFFF),
      foreground: Color(0xFF000000),
      cursor: Color(0xFF000000),
      selection: Color(0xFFADD6FF),
      // Normal ANSI colors
      black: Color(0xFF000000),
      red: Color(0xFFCD3131),
      green: Color(0xFF00BC00),
      yellow: Color(0xFF949800),
      blue: Color(0xFF0451A5),
      magenta: Color(0xFFBC05BC),
      cyan: Color(0xFF0598BC),
      white: Color(0xFF555555),
      // Bright ANSI colors
      brightBlack: Color(0xFF666666),
      brightRed: Color(0xFFCD3131),
      brightGreen: Color(0xFF14CE14),
      brightYellow: Color(0xFFB5BA00),
      brightBlue: Color(0xFF0451A5),
      brightMagenta: Color(0xFFBC05BC),
      brightCyan: Color(0xFF0598BC),
      brightWhite: Color(0xFFA5A5A5),
    );
  }

  /// Background color of the terminal
  final Color background;

  /// Default text color
  final Color foreground;

  /// Cursor color
  final Color cursor;

  /// Selection highlight color
  final Color selection;

  // ANSI colors (normal)
  /// ANSI black color
  final Color black;

  /// ANSI red color
  final Color red;

  /// ANSI green color
  final Color green;

  /// ANSI yellow color
  final Color yellow;

  /// ANSI blue color
  final Color blue;

  /// ANSI magenta color
  final Color magenta;

  /// ANSI cyan color
  final Color cyan;

  /// ANSI white color
  final Color white;

  // ANSI colors (bright)
  /// ANSI bright black color (gray)
  final Color brightBlack;

  /// ANSI bright red color
  final Color brightRed;

  /// ANSI bright green color
  final Color brightGreen;

  /// ANSI bright yellow color
  final Color brightYellow;

  /// ANSI bright blue color
  final Color brightBlue;

  /// ANSI bright magenta color
  final Color brightMagenta;

  /// ANSI bright cyan color
  final Color brightCyan;

  /// ANSI bright white color
  final Color brightWhite;

  /// Converts this theme to xterm's TerminalTheme format
  xterm.TerminalTheme toXTermTheme() {
    return xterm.TerminalTheme(
      cursor: cursor,
      selection: selection,
      foreground: foreground,
      background: background,
      black: black,
      red: red,
      green: green,
      yellow: yellow,
      blue: blue,
      magenta: magenta,
      cyan: cyan,
      white: white,
      brightBlack: brightBlack,
      brightRed: brightRed,
      brightGreen: brightGreen,
      brightYellow: brightYellow,
      brightBlue: brightBlue,
      brightMagenta: brightMagenta,
      brightCyan: brightCyan,
      brightWhite: brightWhite,
      searchHitBackground: selection,
      searchHitBackgroundCurrent: selection,
      searchHitForeground: foreground,
    );
  }

  /// Copy with method for customization
  TerminalTheme copyWith({
    Color? background,
    Color? foreground,
    Color? cursor,
    Color? selection,
    Color? black,
    Color? red,
    Color? green,
    Color? yellow,
    Color? blue,
    Color? magenta,
    Color? cyan,
    Color? white,
    Color? brightBlack,
    Color? brightRed,
    Color? brightGreen,
    Color? brightYellow,
    Color? brightBlue,
    Color? brightMagenta,
    Color? brightCyan,
    Color? brightWhite,
  }) {
    return TerminalTheme(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      cursor: cursor ?? this.cursor,
      selection: selection ?? this.selection,
      black: black ?? this.black,
      red: red ?? this.red,
      green: green ?? this.green,
      yellow: yellow ?? this.yellow,
      blue: blue ?? this.blue,
      magenta: magenta ?? this.magenta,
      cyan: cyan ?? this.cyan,
      white: white ?? this.white,
      brightBlack: brightBlack ?? this.brightBlack,
      brightRed: brightRed ?? this.brightRed,
      brightGreen: brightGreen ?? this.brightGreen,
      brightYellow: brightYellow ?? this.brightYellow,
      brightBlue: brightBlue ?? this.brightBlue,
      brightMagenta: brightMagenta ?? this.brightMagenta,
      brightCyan: brightCyan ?? this.brightCyan,
      brightWhite: brightWhite ?? this.brightWhite,
    );
  }
}
