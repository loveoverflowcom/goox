import 'package:equatable/equatable.dart';

/// Represents a cursor position in the editor.
///
/// A cursor position is defined by three coordinates:
/// - [line]: Zero-based line number
/// - [column]: Zero-based column number within the line
/// - [offset]: Absolute character offset from the start of the file
///
/// This class is immutable and implements value equality through [Equatable].
final class CursorPosition extends Equatable {
  /// Creates a [CursorPosition] with the specified coordinates.
  ///
  /// All parameters are required and must be non-negative.
  const CursorPosition({
    required this.line,
    required this.column,
    required this.offset,
  });

  /// Creates a [CursorPosition] from Rust bridge data.
  ///
  /// This factory constructor is used to convert data received from the
  /// Rust backend via flutter_rust_bridge into a Dart [CursorPosition].
  ///
  /// The [rust] parameter should be an object with `line`, `column`, and
  /// `offset` fields.
  factory CursorPosition.fromRust(Object rust) {
    // Using dynamic access since the exact Rust bridge type isn't defined yet
    // This will be updated when flutter_rust_bridge types are generated
    final rustMap = rust as Map<String, dynamic>;
    return CursorPosition(
      line: rustMap['line'] as int,
      column: rustMap['column'] as int,
      offset: rustMap['offset'] as int,
    );
  }

  /// Zero-based line number.
  ///
  /// The first line in a file is line 0.
  final int line;

  /// Zero-based column number.
  ///
  /// The first column in a line is column 0.
  final int column;

  /// Absolute character offset from the start of the file.
  ///
  /// This is the total number of characters from the beginning of the file
  /// to this cursor position, including newline characters.
  final int offset;

  /// Creates a copy of this [CursorPosition] with the given fields replaced
  /// with new values.
  ///
  /// If a parameter is not provided, the corresponding field from this
  /// instance is used.
  CursorPosition copyWith({
    int? line,
    int? column,
    int? offset,
  }) {
    return CursorPosition(
      line: line ?? this.line,
      column: column ?? this.column,
      offset: offset ?? this.offset,
    );
  }

  /// Converts this [CursorPosition] to Rust bridge format.
  ///
  /// This method is used to convert a Dart [CursorPosition] into a format
  /// that can be passed to the Rust backend via flutter_rust_bridge.
  ///
  /// Returns a map with the cursor position data.
  Map<String, dynamic> toRust() {
    return {
      'line': line,
      'column': column,
      'offset': offset,
    };
  }

  @override
  List<Object?> get props => [line, column, offset];
}
