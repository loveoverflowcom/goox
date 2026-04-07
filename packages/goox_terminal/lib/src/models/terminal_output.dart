import 'package:equatable/equatable.dart';
import 'package:goox/features/terminal/data/models/ansi_style.dart';

/// Represents the output buffer for a terminal instance
class TerminalOutput extends Equatable {
  /// List of terminal lines with styling
  final List<TerminalLine> lines;

  /// Maximum number of lines to keep in scrollback buffer
  final int maxLines;

  /// Maximum characters per line (truncate longer lines)
  final int maxLineLength;

  /// Current scroll offset (0 = bottom)
  final int scrollOffset;

  const TerminalOutput({
    required this.lines,
    this.maxLines = 1000,
    this.maxLineLength = 10000,
    this.scrollOffset = 0,
  });

  /// Create an empty terminal output
  factory TerminalOutput.empty({int maxLines = 1000, int maxLineLength = 10000}) {
    return TerminalOutput(
      lines: const [],
      maxLines: maxLines,
      maxLineLength: maxLineLength,
    );
  }

  /// Append text to the output buffer
  /// Handles newlines and trims to maxLines if exceeded
  TerminalOutput appendText(String text, {List<ANSIStyle>? styles}) {
    if (text.isEmpty) return this;

    final newLines = <TerminalLine>[];
    final textLines = text.split('\n');

    // Start with existing lines
    newLines.addAll(lines);

    // If we have existing lines and the first new text doesn't start with newline,
    // append to the last line
    if (newLines.isNotEmpty && !text.startsWith('\n')) {
      final lastLine = newLines.removeLast();
      final combinedText = lastLine.text + textLines.first;
      // Truncate if exceeds max line length
      final truncatedText = combinedText.length > maxLineLength
          ? combinedText.substring(0, maxLineLength)
          : combinedText;
      newLines.add(TerminalLine(
        text: truncatedText,
        styles: lastLine.styles,
      ));

      // Add remaining lines
      for (int i = 1; i < textLines.length; i++) {
        final lineText = textLines[i];
        // Truncate if exceeds max line length
        final truncatedText = lineText.length > maxLineLength
            ? lineText.substring(0, maxLineLength)
            : lineText;
        newLines.add(TerminalLine(
          text: truncatedText,
          styles: styles ?? const [],
        ));
      }
    } else {
      // Add all new lines
      for (final line in textLines) {
        // Truncate if exceeds max line length
        final truncatedText = line.length > maxLineLength
            ? line.substring(0, maxLineLength)
            : line;
        newLines.add(TerminalLine(
          text: truncatedText,
          styles: styles ?? const [],
        ));
      }
    }

    // Trim to maxLines if exceeded (keep most recent lines)
    final trimmedLines = newLines.length > maxLines
        ? newLines.sublist(newLines.length - maxLines)
        : newLines;

    return TerminalOutput(
      lines: trimmedLines,
      maxLines: maxLines,
      maxLineLength: maxLineLength,
      scrollOffset: scrollOffset,
    );
  }

  /// Append already-parsed terminal lines to the output buffer
  /// Trims to maxLines if exceeded and truncates long lines
  TerminalOutput appendLines(List<TerminalLine> newLines) {
    if (newLines.isEmpty) return this;

    // Truncate long lines
    final truncatedNewLines = newLines.map((line) {
      if (line.text.length > maxLineLength) {
        return TerminalLine(
          text: line.text.substring(0, maxLineLength),
          styles: line.styles,
        );
      }
      return line;
    }).toList();

    // Combine existing and new lines
    final combinedLines = [...lines, ...truncatedNewLines];

    // Trim to maxLines if exceeded (keep most recent lines)
    final trimmedLines = combinedLines.length > maxLines
        ? combinedLines.sublist(combinedLines.length - maxLines)
        : combinedLines;

    return TerminalOutput(
      lines: trimmedLines,
      maxLines: maxLines,
      maxLineLength: maxLineLength,
      scrollOffset: scrollOffset,
    );
  }

  /// Create a copy with updated fields
  TerminalOutput copyWith({
    List<TerminalLine>? lines,
    int? maxLines,
    int? maxLineLength,
    int? scrollOffset,
  }) {
    return TerminalOutput(
      lines: lines ?? this.lines,
      maxLines: maxLines ?? this.maxLines,
      maxLineLength: maxLineLength ?? this.maxLineLength,
      scrollOffset: scrollOffset ?? this.scrollOffset,
    );
  }

  @override
  List<Object?> get props => [lines, maxLines, maxLineLength, scrollOffset];
}

/// Represents a single line of terminal output with styling
class TerminalLine extends Equatable {
  /// The text content of the line
  final String text;

  /// List of ANSI styles applied to this line
  final List<ANSIStyle> styles;

  const TerminalLine({
    required this.text,
    required this.styles,
  });

  /// Create a plain text line without styling
  factory TerminalLine.plain(String text) {
    return TerminalLine(
      text: text,
      styles: const [],
    );
  }

  @override
  List<Object?> get props => [text, styles];
}
