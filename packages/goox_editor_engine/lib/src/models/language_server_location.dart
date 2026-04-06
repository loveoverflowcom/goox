import 'package:equatable/equatable.dart';

/// Represents a location in a source file for language server operations.
///
/// A location is defined by:
/// - [filePath]: The absolute or relative path to the file
/// - [line]: Zero-based line number within the file
/// - [column]: Zero-based column number within the line
///
/// This class is used for language server protocol (LSP) operations such as
/// hover information, go-to-definition, and diagnostics.
///
/// This class is immutable and implements value equality through [Equatable].
final class LanguageServerLocation extends Equatable {
  /// Creates a [LanguageServerLocation] with the specified file path and
  /// coordinates.
  ///
  /// All parameters are required. The [line] and [column] must be non-negative.
  const LanguageServerLocation({
    required this.filePath,
    required this.line,
    required this.column,
  });

  /// The file path.
  ///
  /// This can be an absolute path or a relative path depending on the context.
  final String filePath;

  /// Zero-based line number.
  ///
  /// The first line in a file is line 0.
  final int line;

  /// Zero-based column number.
  ///
  /// The first column in a line is column 0.
  final int column;

  /// Creates a copy of this [LanguageServerLocation] with the given fields
  /// replaced with new values.
  ///
  /// If a parameter is not provided, the corresponding field from this
  /// instance is used.
  LanguageServerLocation copyWith({
    String? filePath,
    int? line,
    int? column,
  }) {
    return LanguageServerLocation(
      filePath: filePath ?? this.filePath,
      line: line ?? this.line,
      column: column ?? this.column,
    );
  }

  /// Converts this [LanguageServerLocation] to Rust bridge format.
  ///
  /// This method is used to convert a Dart [LanguageServerLocation] into a
  /// format that can be passed to the Rust backend via flutter_rust_bridge.
  ///
  /// Returns a map with the location data.
  Map<String, dynamic> toRust() {
    return {
      'filePath': filePath,
      'line': line,
      'column': column,
    };
  }

  @override
  List<Object?> get props => [filePath, line, column];
}
