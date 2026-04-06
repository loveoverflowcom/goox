/// Terminal size model
library;

/// Represents the size of a terminal in rows and columns
///
/// This class is used to specify the dimensions of a pseudo-terminal.
/// The size affects how text wraps and how terminal applications render.
///
/// Example:
/// ```dart
/// final size = PtySize(rows: 24, cols: 80);
/// ```
class PtySize {
  /// Number of rows (lines) in the terminal
  ///
  /// Must be between 1 and 1000.
  final int rows;

  /// Number of columns (characters per line) in the terminal
  ///
  /// Must be between 1 and 1000.
  final int cols;

  /// Creates a new terminal size
  ///
  /// Throws [ArgumentError] if rows or cols are out of valid range.
  const PtySize({
    required this.rows,
    required this.cols,
  });

  /// Minimum valid size (1x1)
  static const PtySize min = PtySize(rows: 1, cols: 1);

  /// Maximum valid size (1000x1000)
  static const PtySize max = PtySize(rows: 1000, cols: 1000);

  /// Standard 80x24 terminal size
  static const PtySize standard = PtySize(rows: 24, cols: 80);

  /// Large terminal size (40x120)
  static const PtySize large = PtySize(rows: 40, cols: 120);

  /// Validates the size
  ///
  /// Returns true if the size is within valid range.
  bool get isValid {
    return rows >= min.rows &&
        rows <= max.rows &&
        cols >= min.cols &&
        cols <= max.cols;
  }

  /// Validates and throws if invalid
  ///
  /// Throws [ArgumentError] if the size is out of valid range.
  void validate() {
    if (rows < min.rows || rows > max.rows) {
      throw ArgumentError(
        'Rows must be between ${min.rows} and ${max.rows}, got $rows',
      );
    }
    if (cols < min.cols || cols > max.cols) {
      throw ArgumentError(
        'Cols must be between ${min.cols} and ${max.cols}, got $cols',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PtySize && other.rows == rows && other.cols == cols;
  }

  @override
  int get hashCode => Object.hash(rows, cols);

  @override
  String toString() => 'PtySize(rows: $rows, cols: $cols)';
}
