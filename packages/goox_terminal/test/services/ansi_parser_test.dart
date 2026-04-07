import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/terminal/data/models/ansi_style.dart';
import 'package:goox/features/terminal/data/models/terminal_output.dart';
import '../../lib/src/services/ansi_parser.dart';

void main() {
  group('ANSIParser', () {
    late ANSIParser parser;

    setUp(() {
      parser = ANSIParser();
    });

    group('Basic 16 Colors', () {
      test('parses foreground colors (30-37)', () {
        // Test basic foreground colors
        final result = parser.parse('\x1b[31mRed text\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Red text');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].foregroundColor, isNotNull);
        expect(result[0].styles[0].startIndex, 0);
        expect(result[0].styles[0].endIndex, 8);
      });

      test('parses background colors (40-47)', () {
        final result = parser.parse('\x1b[42mGreen background\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Green background');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].backgroundColor, isNotNull);
      });

      test('parses bright foreground colors (90-97)', () {
        final result = parser.parse('\x1b[91mBright red\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Bright red');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].foregroundColor, isNotNull);
      });

      test('parses bright background colors (100-107)', () {
        final result = parser.parse('\x1b[103mBright yellow bg\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Bright yellow bg');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].backgroundColor, isNotNull);
      });

      test('parses combined foreground and background colors', () {
        final result = parser.parse('\x1b[31;42mRed on green\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Red on green');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].foregroundColor, isNotNull);
        expect(result[0].styles[0].backgroundColor, isNotNull);
      });
    });

    group('256-Color Palette', () {
      test('parses 256-color foreground (38;5;n)', () {
        final result = parser.parse('\x1b[38;5;196mColor 196\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Color 196');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].foregroundColor, isNotNull);
      });

      test('parses 256-color background (48;5;n)', () {
        final result = parser.parse('\x1b[48;5;21mColor 21 bg\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Color 21 bg');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].backgroundColor, isNotNull);
      });

      test('parses combined 256-color foreground and background', () {
        final result = parser.parse('\x1b[38;5;226;48;5;18mYellow on blue\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Yellow on blue');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].foregroundColor, isNotNull);
        expect(result[0].styles[0].backgroundColor, isNotNull);
      });
    });

    group('RGB Colors', () {
      test('parses RGB foreground color (38;2;r;g;b)', () {
        final result = parser.parse('\x1b[38;2;255;100;50mRGB text\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'RGB text');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].foregroundColor, isNotNull);
        expect(result[0].styles[0].foregroundColor, const Color.fromRGBO(255, 100, 50, 1.0));
      });

      test('parses RGB background color (48;2;r;g;b)', () {
        final result = parser.parse('\x1b[48;2;10;20;30mRGB bg\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'RGB bg');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].backgroundColor, isNotNull);
        expect(result[0].styles[0].backgroundColor, const Color.fromRGBO(10, 20, 30, 1.0));
      });

      test('parses combined RGB foreground and background', () {
        final result = parser.parse('\x1b[38;2;255;0;0;48;2;0;255;0mRed on green\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Red on green');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].foregroundColor, const Color.fromRGBO(255, 0, 0, 1.0));
        expect(result[0].styles[0].backgroundColor, const Color.fromRGBO(0, 255, 0, 1.0));
      });
    });

    group('Text Styles', () {
      test('parses bold text (1)', () {
        final result = parser.parse('\x1b[1mBold text\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Bold text');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].bold, true);
      });

      test('parses italic text (3)', () {
        final result = parser.parse('\x1b[3mItalic text\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Italic text');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].italic, true);
      });

      test('parses underlined text (4)', () {
        final result = parser.parse('\x1b[4mUnderlined text\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Underlined text');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].underline, true);
      });

      test('parses combined text styles', () {
        final result = parser.parse('\x1b[1;3;4mBold italic underline\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Bold italic underline');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].bold, true);
        expect(result[0].styles[0].italic, true);
        expect(result[0].styles[0].underline, true);
      });

      test('parses text styles with colors', () {
        final result = parser.parse('\x1b[1;31mBold red\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Bold red');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].bold, true);
        expect(result[0].styles[0].foregroundColor, isNotNull);
      });
    });

    group('Reset Codes', () {
      test('reset code (0) clears all styles', () {
        final result = parser.parse('\x1b[1;31mBold red\x1b[0mNormal');
        
        expect(result.length, 1);
        expect(result[0].text, 'Bold redNormal');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].endIndex, 8); // Only "Bold red" is styled
      });

      test('reset bold (22) clears bold only', () {
        final result = parser.parse('\x1b[1;31mBold red\x1b[22mNot bold red');
        
        expect(result.length, 1);
        expect(result[0].text, 'Bold redNot bold red');
        // Should have two style segments
        expect(result[0].styles.length, 2);
        expect(result[0].styles[0].bold, true);
        expect(result[0].styles[1].bold, false);
        expect(result[0].styles[1].foregroundColor, isNotNull);
      });

      test('reset italic (23) clears italic only', () {
        final result = parser.parse('\x1b[3;31mItalic red\x1b[23mNot italic red');
        
        expect(result.length, 1);
        expect(result[0].text, 'Italic redNot italic red');
        expect(result[0].styles.length, 2);
        expect(result[0].styles[0].italic, true);
        expect(result[0].styles[1].italic, false);
        expect(result[0].styles[1].foregroundColor, isNotNull);
      });

      test('reset underline (24) clears underline only', () {
        final result = parser.parse('\x1b[4;31mUnderline red\x1b[24mNot underline red');
        
        expect(result.length, 1);
        expect(result[0].text, 'Underline redNot underline red');
        expect(result[0].styles.length, 2);
        expect(result[0].styles[0].underline, true);
        expect(result[0].styles[1].underline, false);
        expect(result[0].styles[1].foregroundColor, isNotNull);
      });

      test('reset foreground color (39) clears foreground only', () {
        final result = parser.parse('\x1b[31;42mRed on green\x1b[39mDefault on green');
        
        expect(result.length, 1);
        expect(result[0].text, 'Red on greenDefault on green');
        expect(result[0].styles.length, 2);
        expect(result[0].styles[0].foregroundColor, isNotNull);
        expect(result[0].styles[0].backgroundColor, isNotNull);
        expect(result[0].styles[1].foregroundColor, isNull);
        expect(result[0].styles[1].backgroundColor, isNotNull);
      });

      test('reset background color (49) clears background only', () {
        final result = parser.parse('\x1b[31;42mRed on green\x1b[49mRed on default');
        
        expect(result.length, 1);
        expect(result[0].text, 'Red on greenRed on default');
        expect(result[0].styles.length, 2);
        expect(result[0].styles[0].foregroundColor, isNotNull);
        expect(result[0].styles[0].backgroundColor, isNotNull);
        expect(result[0].styles[1].foregroundColor, isNotNull);
        expect(result[0].styles[1].backgroundColor, isNull);
      });
    });

    group('Invalid Escape Sequences', () {
      test('skips invalid escape sequences', () {
        final result = parser.parse('\x1b[999mText\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Text');
        // Should not crash, may have no styles or default styles
      });

      test('skips malformed escape sequences', () {
        final result = parser.parse('\x1b[31;mText\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Text');
        // Should handle gracefully
      });

      test('skips incomplete escape sequences', () {
        final result = parser.parse('\x1b[31Text\x1b[0m');
        
        expect(result.length, 1);
        // Should handle gracefully, text may include the incomplete sequence
      });

      test('handles text with no escape sequences', () {
        final result = parser.parse('Plain text');
        
        expect(result.length, 1);
        expect(result[0].text, 'Plain text');
        expect(result[0].styles, isEmpty);
      });
    });

    group('Multi-line Style State', () {
      test('maintains style state across multiple lines', () {
        final result = parser.parse('\x1b[31mRed line 1\nRed line 2\x1b[0m');
        
        expect(result.length, 2);
        expect(result[0].text, 'Red line 1');
        expect(result[1].text, 'Red line 2');
        // Both lines should have red foreground
        expect(result[0].styles.length, greaterThan(0));
        expect(result[1].styles.length, greaterThan(0));
        expect(result[0].styles[0].foregroundColor, isNotNull);
        expect(result[1].styles[0].foregroundColor, isNotNull);
      });

      test('style changes persist across lines', () {
        final result = parser.parse('\x1b[1mBold line 1\n\x1b[31mBold red line 2\x1b[0m');
        
        expect(result.length, 2);
        expect(result[0].text, 'Bold line 1');
        expect(result[1].text, 'Bold red line 2');
        // First line should be bold
        expect(result[0].styles[0].bold, true);
        // Second line should be bold and red
        expect(result[1].styles[0].bold, true);
        expect(result[1].styles[0].foregroundColor, isNotNull);
      });

      test('reset code affects subsequent lines', () {
        final result = parser.parse('\x1b[31mRed line 1\x1b[0m\nNormal line 2');
        
        expect(result.length, 2);
        expect(result[0].text, 'Red line 1');
        expect(result[1].text, 'Normal line 2');
        // First line should be styled
        expect(result[0].styles.length, greaterThan(0));
        // Second line should have no styles
        expect(result[1].styles, isEmpty);
      });
    });

    group('Mixed Styled and Unstyled Text', () {
      test('handles styled text followed by unstyled text', () {
        final result = parser.parse('\x1b[31mRed\x1b[0m Normal');
        
        expect(result.length, 1);
        expect(result[0].text, 'Red Normal');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].startIndex, 0);
        expect(result[0].styles[0].endIndex, 3);
      });

      test('handles unstyled text followed by styled text', () {
        final result = parser.parse('Normal \x1b[31mRed\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Normal Red');
        expect(result[0].styles.length, 1);
        expect(result[0].styles[0].startIndex, 7);
        expect(result[0].styles[0].endIndex, 10);
      });

      test('handles multiple styled segments in one line', () {
        final result = parser.parse('\x1b[31mRed\x1b[0m \x1b[32mGreen\x1b[0m \x1b[34mBlue\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Red Green Blue');
        expect(result[0].styles.length, 3);
        // Each color segment should have its own style
        expect(result[0].styles[0].foregroundColor, isNotNull);
        expect(result[0].styles[1].foregroundColor, isNotNull);
        expect(result[0].styles[2].foregroundColor, isNotNull);
      });

      test('handles overlapping style changes', () {
        final result = parser.parse('\x1b[31mRed \x1b[1mbold red\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text, 'Red bold red');
        // Should have at least 2 style segments
        expect(result[0].styles.length, greaterThanOrEqualTo(2));
      });
    });

    group('Edge Cases', () {
      test('handles empty string', () {
        final result = parser.parse('');
        
        expect(result, isEmpty);
      });

      test('handles only escape sequences with no text', () {
        final result = parser.parse('\x1b[31m\x1b[0m');
        
        // May return empty or a line with empty text
        expect(result.length, lessThanOrEqualTo(1));
      });

      test('handles very long text with styles', () {
        final longText = 'A' * 10000;
        final result = parser.parse('\x1b[31m$longText\x1b[0m');
        
        expect(result.length, 1);
        expect(result[0].text.length, 10000);
        expect(result[0].styles.length, greaterThan(0));
      });

      test('handles multiple consecutive reset codes', () {
        final result = parser.parse('\x1b[31mRed\x1b[0m\x1b[0m\x1b[0mNormal');
        
        expect(result.length, 1);
        expect(result[0].text, 'RedNormal');
      });
    });
  });
}
