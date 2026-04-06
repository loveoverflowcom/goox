import 'package:equatable/equatable.dart';

/// Represents a range in a source file for language server operations.
///
/// A range is defined by:
/// - [startLine]: Zero-based line number where the range starts
/// - [startColumn]: Zero-based column number where the range starts
/// - [endLine]: Zero-based line number where the range ends
/// - [endColumn]: Zero-based column number where the range ends
///
/// This class is used in language server protocol (LSP) operations to
/// specify a region of text in a document.
///
/// This class is immutable and implements value equality through [Equatable].
final class LanguageServerRange extends Equatable {
  /// Creates a [LanguageServerRange] with the specified start and end
  /// coordinates.
  ///
  /// All parameters are required and must be non-negative.
  const LanguageServerRange({
    required this.startLine,
    required this.startColumn,
    required this.endLine,
    required this.endColumn,
  });

  /// Creates a [LanguageServerRange] from Rust bridge data.
  ///
  /// This factory constructor is used to convert data received from the
  /// Rust backend via flutter_rust_bridge into a Dart [LanguageServerRange].
  ///
  /// The [rust] parameter should be an object with `startLine`, `startColumn`,
  /// `endLine`, and `endColumn` fields.
  factory LanguageServerRange.fromRust(Object rust) {
    // Using dynamic access since the exact Rust bridge type isn't defined yet
    // This will be updated when flutter_rust_bridge types are generated
    final rustMap = rust as Map<String, dynamic>;
    return LanguageServerRange(
      startLine: rustMap['startLine'] as int,
      startColumn: rustMap['startColumn'] as int,
      endLine: rustMap['endLine'] as int,
      endColumn: rustMap['endColumn'] as int,
    );
  }

  /// Zero-based line number where the range starts.
  ///
  /// The first line in a file is line 0.
  final int startLine;

  /// Zero-based column number where the range starts.
  ///
  /// The first column in a line is column 0.
  final int startColumn;

  /// Zero-based line number where the range ends.
  ///
  /// The first line in a file is line 0.
  final int endLine;

  /// Zero-based column number where the range ends.
  ///
  /// The first column in a line is column 0.
  final int endColumn;

  /// Creates a copy of this [LanguageServerRange] with the given fields
  /// replaced with new values.
  ///
  /// If a parameter is not provided, the corresponding field from this
  /// instance is used.
  LanguageServerRange copyWith({
    int? startLine,
    int? startColumn,
    int? endLine,
    int? endColumn,
  }) {
    return LanguageServerRange(
      startLine: startLine ?? this.startLine,
      startColumn: startColumn ?? this.startColumn,
      endLine: endLine ?? this.endLine,
      endColumn: endColumn ?? this.endColumn,
    );
  }

  @override
  List<Object?> get props => [startLine, startColumn, endLine, endColumn];
}
