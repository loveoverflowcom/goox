import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/terminal/data/models/terminal_output.dart';
import 'package:goox/features/terminal/data/models/ansi_style.dart';

void main() {
  group('TerminalOutput', () {
    group('appendText', () {
      test('should append text to empty output', () {
        // Arrange
        final output = TerminalOutput.empty();

        // Act
        final result = output.appendText('Hello World');

        // Assert
        expect(result.lines.length, 1);
        expect(result.lines[0].text, 'Hello World');
      });

      test('should handle newlines and create multiple lines', () {
        // Arrange
        final output = TerminalOutput.empty();

        // Act
        final result = output.appendText('Line 1\nLine 2\nLine 3');

        // Assert
        expect(result.lines.length, 3);
        expect(result.lines[0].text, 'Line 1');
        expect(result.lines[1].text, 'Line 2');
        expect(result.lines[2].text, 'Line 3');
      });

      test('should append to last line when text does not start with newline', () {
        // Arrange
        final output = TerminalOutput.empty().appendText('Hello');

        // Act
        final result = output.appendText(' World');

        // Assert
        expect(result.lines.length, 1);
        expect(result.lines[0].text, 'Hello World');
      });

      test('should create new line when text starts with newline', () {
        // Arrange
        final output = TerminalOutput.empty().appendText('Hello');

        // Act
        final result = output.appendText('\nWorld');

        // Assert
        // When text starts with \n, split creates ["", "World"]
        // So we get: "Hello", "", "World" = 3 lines
        expect(result.lines.length, 3);
        expect(result.lines[0].text, 'Hello');
        expect(result.lines[1].text, '');
        expect(result.lines[2].text, 'World');
      });

      test('should trim to maxLines when exceeded', () {
        // Arrange
        final output = TerminalOutput.empty(maxLines: 3);

        // Act
        final result = output
            .appendText('Line 1\n')
            .appendText('Line 2\n')
            .appendText('Line 3\n')
            .appendText('Line 4\n')
            .appendText('Line 5');

        // Assert
        expect(result.lines.length, 3);
        expect(result.lines[0].text, 'Line 3');
        expect(result.lines[1].text, 'Line 4');
        expect(result.lines[2].text, 'Line 5');
      });

      test('should keep most recent lines when trimming', () {
        // Arrange
        final output = TerminalOutput.empty(maxLines: 2);

        // Act
        final result = output
            .appendText('Old 1\n')
            .appendText('Old 2\n')
            .appendText('New 1\n')
            .appendText('New 2');

        // Assert
        expect(result.lines.length, 2);
        expect(result.lines[0].text, 'New 1');
        expect(result.lines[1].text, 'New 2');
      });

      test('should handle empty text input', () {
        // Arrange
        final output = TerminalOutput.empty().appendText('Hello');

        // Act
        final result = output.appendText('');

        // Assert
        expect(result.lines.length, 1);
        expect(result.lines[0].text, 'Hello');
      });

      test('should handle multiple consecutive newlines', () {
        // Arrange
        final output = TerminalOutput.empty();

        // Act
        final result = output.appendText('Line 1\n\n\nLine 2');

        // Assert
        expect(result.lines.length, 4);
        expect(result.lines[0].text, 'Line 1');
        expect(result.lines[1].text, '');
        expect(result.lines[2].text, '');
        expect(result.lines[3].text, 'Line 2');
      });

      test('should preserve scrollback buffer limit of 1000 lines by default', () {
        // Arrange
        final output = TerminalOutput.empty();
        var result = output;

        // Act - Add 1500 lines
        for (int i = 0; i < 1500; i++) {
          result = result.appendText('Line $i\n');
        }

        // Assert
        expect(result.lines.length, 1000);
        // Each appendText('Line X\n') creates 2 lines: "Line X" and ""
        // So 1500 iterations create 3000 lines, trimmed to 1000
        // The first line should be from iteration 501 (3000 - 1000 = 2000, 2000/2 = 1000, but we start from 0)
        expect(result.lines.first.text, 'Line 501');
        expect(result.lines.last.text, '');
      });

      test('should handle text with only newlines', () {
        // Arrange
        final output = TerminalOutput.empty();

        // Act
        final result = output.appendText('\n\n\n');

        // Assert
        // "\n\n\n" splits into ["", "", "", ""]
        expect(result.lines.length, 4);
        expect(result.lines[0].text, '');
        expect(result.lines[1].text, '');
        expect(result.lines[2].text, '');
        expect(result.lines[3].text, '');
      });
    });

    group('copyWith', () {
      test('should create copy with updated lines', () {
        // Arrange
        final output = TerminalOutput.empty();
        final newLines = [TerminalLine.plain('New line')];

        // Act
        final result = output.copyWith(lines: newLines);

        // Assert
        expect(result.lines, newLines);
        expect(result.maxLines, output.maxLines);
        expect(result.scrollOffset, output.scrollOffset);
      });

      test('should create copy with updated maxLines', () {
        // Arrange
        final output = TerminalOutput.empty();

        // Act
        final result = output.copyWith(maxLines: 500);

        // Assert
        expect(result.maxLines, 500);
        expect(result.lines, output.lines);
        expect(result.scrollOffset, output.scrollOffset);
      });

      test('should create copy with updated scrollOffset', () {
        // Arrange
        final output = TerminalOutput.empty();

        // Act
        final result = output.copyWith(scrollOffset: 10);

        // Assert
        expect(result.scrollOffset, 10);
        expect(result.lines, output.lines);
        expect(result.maxLines, output.maxLines);
      });
    });
  });

  group('TerminalLine', () {
    test('should create plain text line without styling', () {
      // Arrange & Act
      final line = TerminalLine.plain('Hello World');

      // Assert
      expect(line.text, 'Hello World');
      expect(line.styles, isEmpty);
    });

    test('should create line with styles', () {
      // Arrange
      const style = ANSIStyle(
        startIndex: 0,
        endIndex: 5,
        bold: true,
      );

      // Act
      const line = TerminalLine(
        text: 'Hello World',
        styles: [style],
      );

      // Assert
      expect(line.text, 'Hello World');
      expect(line.styles.length, 1);
      expect(line.styles[0], style);
    });
  });
}
