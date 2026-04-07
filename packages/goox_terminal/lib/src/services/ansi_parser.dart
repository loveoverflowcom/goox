import 'package:flutter/material.dart';
import 'package:goox/features/terminal/data/models/ansi_style.dart';
import 'package:goox/features/terminal/data/models/terminal_output.dart';

/// Parser for ANSI escape codes in terminal output
/// 
/// Supports:
/// - Basic 16 colors (30-37, 40-47, 90-97, 100-107)
/// - 256-color palette (38;5;n, 48;5;n)
/// - RGB colors (38;2;r;g;b, 48;2;r;g;b)
/// - Text styles: bold (1), italic (3), underline (4)
/// - Reset codes (0, 22, 23, 24, 39, 49)
class ANSIParser {
  // Current style state that persists across lines
  Color? _currentForeground;
  Color? _currentBackground;
  bool _currentBold = false;
  bool _currentItalic = false;
  bool _currentUnderline = false;

  /// Parse raw text with ANSI escape codes into styled terminal lines
  List<TerminalLine> parse(String text) {
    if (text.isEmpty) return [];

    final lines = <TerminalLine>[];
    final textLines = text.split('\n');

    for (final line in textLines) {
      lines.add(_parseLine(line));
    }

    return lines;
  }

  /// Parse a single line of text with ANSI codes
  TerminalLine _parseLine(String line) {
    final styles = <ANSIStyle>[];
    final buffer = StringBuffer();
    int textStartIndex = 0;
    int i = 0;

    while (i < line.length) {
      if (line[i] == '\x1b' && i + 1 < line.length && line[i + 1] == '[') {
        // Found escape sequence start
        final endIndex = line.indexOf('m', i + 2);
        if (endIndex == -1) {
          // Invalid sequence, skip the escape character
          buffer.write(line[i]);
          i++;
          continue;
        }

        // Save current style before processing codes
        final styleBeforeCode = _createCurrentStyle(textStartIndex, buffer.length);
        
        // Extract and process the codes
        final codes = line.substring(i + 2, endIndex);
        _processCodes(codes);

        // If we had text before this code and style changed, add the style
        if (buffer.length > textStartIndex && styleBeforeCode != null) {
          styles.add(styleBeforeCode);
        }

        // Update text start index for next style segment
        textStartIndex = buffer.length;

        // Move past the escape sequence
        i = endIndex + 1;
      } else {
        // Regular character
        buffer.write(line[i]);
        i++;
      }
    }

    // Add final style segment if there's remaining text
    if (buffer.length > textStartIndex) {
      final finalStyle = _createCurrentStyle(textStartIndex, buffer.length);
      if (finalStyle != null) {
        styles.add(finalStyle);
      }
    }

    return TerminalLine(
      text: buffer.toString(),
      styles: styles,
    );
  }

  /// Process ANSI SGR (Select Graphic Rendition) codes
  void _processCodes(String codes) {
    if (codes.isEmpty) return;

    final parts = codes.split(';');
    int i = 0;

    while (i < parts.length) {
      final code = int.tryParse(parts[i]);
      if (code == null) {
        i++;
        continue;
      }

      switch (code) {
        // Reset all
        case 0:
          _resetAll();
          break;

        // Text styles
        case 1:
          _currentBold = true;
          break;
        case 3:
          _currentItalic = true;
          break;
        case 4:
          _currentUnderline = true;
          break;

        // Reset text styles
        case 22:
          _currentBold = false;
          break;
        case 23:
          _currentItalic = false;
          break;
        case 24:
          _currentUnderline = false;
          break;

        // Basic foreground colors (30-37)
        case 30:
        case 31:
        case 32:
        case 33:
        case 34:
        case 35:
        case 36:
        case 37:
          _currentForeground = _getBasicColor(code - 30);
          break;

        // 256-color or RGB foreground
        case 38:
          i = _process256OrRgbColor(parts, i, isForeground: true);
          break;

        // Reset foreground
        case 39:
          _currentForeground = null;
          break;

        // Basic background colors (40-47)
        case 40:
        case 41:
        case 42:
        case 43:
        case 44:
        case 45:
        case 46:
        case 47:
          _currentBackground = _getBasicColor(code - 40);
          break;

        // 256-color or RGB background
        case 48:
          i = _process256OrRgbColor(parts, i, isForeground: false);
          break;

        // Reset background
        case 49:
          _currentBackground = null;
          break;

        // Bright foreground colors (90-97)
        case 90:
        case 91:
        case 92:
        case 93:
        case 94:
        case 95:
        case 96:
        case 97:
          _currentForeground = _getBrightColor(code - 90);
          break;

        // Bright background colors (100-107)
        case 100:
        case 101:
        case 102:
        case 103:
        case 104:
        case 105:
        case 106:
        case 107:
          _currentBackground = _getBrightColor(code - 100);
          break;

        default:
          // Unknown code, skip it
          break;
      }

      i++;
    }
  }

  /// Process 256-color or RGB color codes
  /// Returns the new index position after processing
  int _process256OrRgbColor(List<String> parts, int currentIndex, {required bool isForeground}) {
    if (currentIndex + 1 >= parts.length) return currentIndex;

    final colorType = int.tryParse(parts[currentIndex + 1]);
    if (colorType == null) return currentIndex;

    if (colorType == 5) {
      // 256-color palette: 38;5;n or 48;5;n
      if (currentIndex + 2 >= parts.length) return currentIndex;
      
      final colorIndex = int.tryParse(parts[currentIndex + 2]);
      if (colorIndex != null && colorIndex >= 0 && colorIndex <= 255) {
        final color = _get256Color(colorIndex);
        if (isForeground) {
          _currentForeground = color;
        } else {
          _currentBackground = color;
        }
      }
      return currentIndex + 2;
    } else if (colorType == 2) {
      // RGB color: 38;2;r;g;b or 48;2;r;g;b
      if (currentIndex + 4 >= parts.length) return currentIndex;

      final r = int.tryParse(parts[currentIndex + 2]);
      final g = int.tryParse(parts[currentIndex + 3]);
      final b = int.tryParse(parts[currentIndex + 4]);

      if (r != null && g != null && b != null &&
          r >= 0 && r <= 255 &&
          g >= 0 && g <= 255 &&
          b >= 0 && b <= 255) {
        final color = Color.fromRGBO(r, g, b, 1);
        if (isForeground) {
          _currentForeground = color;
        } else {
          _currentBackground = color;
        }
      }
      return currentIndex + 4;
    }

    return currentIndex;
  }

  /// Create an ANSIStyle from current state, or null if no styling
  ANSIStyle? _createCurrentStyle(int startIndex, int endIndex) {
    if (startIndex >= endIndex) return null;

    // Only create style if there's actual styling applied
    if (_currentForeground == null &&
        _currentBackground == null &&
        !_currentBold &&
        !_currentItalic &&
        !_currentUnderline) {
      return null;
    }

    return ANSIStyle(
      startIndex: startIndex,
      endIndex: endIndex,
      foregroundColor: _currentForeground,
      backgroundColor: _currentBackground,
      bold: _currentBold,
      italic: _currentItalic,
      underline: _currentUnderline,
    );
  }

  /// Reset all style state
  void _resetAll() {
    _currentForeground = null;
    _currentBackground = null;
    _currentBold = false;
    _currentItalic = false;
    _currentUnderline = false;
  }

  /// Get basic ANSI color (0-7)
  /// Colors adjusted for WCAG AA contrast compliance on dark backgrounds
  Color _getBasicColor(int index) {
    const colors = [
      Color(0xFF2E3436), // Black - slightly lighter for visibility
      Color(0xFFEF2929), // Red - brighter for better contrast
      Color(0xFF4EDD82), // Green - adjusted for WCAG AA
      Color(0xFFFCE94F), // Yellow - high contrast
      Color(0xFF729FCF), // Blue - adjusted for readability
      Color(0xFFE879F9), // Magenta - brighter
      Color(0xFF34E2E2), // Cyan - high contrast
      Color(0xFFEEEEEC), // White - slightly dimmed
    ];
    return colors[index % 8];
  }

  /// Get bright ANSI color (8-15)
  /// Colors adjusted for WCAG AA contrast compliance on dark backgrounds
  Color _getBrightColor(int index) {
    const colors = [
      Color(0xFF888A85), // Bright Black (Gray) - lighter
      Color(0xFFFF6B6B), // Bright Red - high contrast
      Color(0xFF5FE88E), // Bright Green - WCAG AA compliant
      Color(0xFFFFF176), // Bright Yellow - excellent contrast
      Color(0xFF8AB4F8), // Bright Blue - readable
      Color(0xFFF48FB1), // Bright Magenta - adjusted
      Color(0xFF4DD0E1), // Bright Cyan - high contrast
      Color(0xFFFFFFFF), // Bright White
    ];
    return colors[index % 8];
  }

  /// Get 256-color palette color
  Color _get256Color(int index) {
    // 0-15: Basic colors
    if (index < 8) {
      return _getBasicColor(index);
    } else if (index < 16) {
      return _getBrightColor(index - 8);
    }

    // 16-231: 6x6x6 color cube
    if (index >= 16 && index <= 231) {
      final cubeIndex = index - 16;
      final r = (cubeIndex ~/ 36) * 51;
      final g = ((cubeIndex % 36) ~/ 6) * 51;
      final b = (cubeIndex % 6) * 51;
      return Color.fromRGBO(r, g, b, 1);
    }

    // 232-255: Grayscale
    if (index >= 232 && index <= 255) {
      final gray = 8 + (index - 232) * 10;
      return Color.fromRGBO(gray, gray, gray, 1);
    }

    // Fallback
    return const Color(0xFFFFFFFF);
  }
}
