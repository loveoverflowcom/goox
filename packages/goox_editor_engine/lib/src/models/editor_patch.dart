import 'package:equatable/equatable.dart';

/// Represents a patch to apply to editor content.
///
/// An editor patch defines a text replacement operation with:
/// - [filePath]: The file to modify
/// - [startOffset]: Starting position of the range to replace
/// - [endOffset]: Ending position of the range to replace
/// - [newText]: The text to insert in place of the range
/// - [version]: Expected version for optimistic concurrency control
///
/// This class is immutable and implements value equality through [Equatable].
final class EditorPatch extends Equatable {
  /// Creates an [EditorPatch] with the specified parameters.
  ///
  /// All parameters are required:
  /// - [filePath]: The absolute path to the file to patch
  /// - [startOffset]: The starting character offset (inclusive)
  /// - [endOffset]: The ending character offset (exclusive)
  /// - [newText]: The text to insert
  /// - [version]: The expected version number for conflict detection
  const EditorPatch({
    required this.filePath,
    required this.startOffset,
    required this.endOffset,
    required this.newText,
    required this.version,
  });

  /// The absolute path to the file to patch.
  final String filePath;

  /// Starting offset of the range to replace.
  ///
  /// This is the absolute character offset from the start of the file
  /// where the replacement begins (inclusive).
  final int startOffset;

  /// Ending offset of the range to replace.
  ///
  /// This is the absolute character offset from the start of the file
  /// where the replacement ends (exclusive).
  final int endOffset;

  /// The new text to insert.
  ///
  /// This text will replace the content between [startOffset] and [endOffset].
  /// Can be empty to delete text without inserting anything.
  final String newText;

  /// Expected version for optimistic concurrency control.
  ///
  /// This version number is used to detect conflicts when multiple edits
  /// are made concurrently. If the actual file version doesn't match this
  /// expected version, the patch operation will fail.
  final int version;

  /// Creates a copy of this [EditorPatch] with the given fields replaced
  /// with new values.
  ///
  /// If a parameter is not provided, the corresponding field from this
  /// instance is used.
  EditorPatch copyWith({
    String? filePath,
    int? startOffset,
    int? endOffset,
    String? newText,
    int? version,
  }) {
    return EditorPatch(
      filePath: filePath ?? this.filePath,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      newText: newText ?? this.newText,
      version: version ?? this.version,
    );
  }

  /// Converts this [EditorPatch] to Rust bridge format.
  ///
  /// This method is used to convert a Dart [EditorPatch] into a format
  /// that can be passed to the Rust backend via flutter_rust_bridge.
  ///
  /// Returns a map with the patch data.
  Map<String, dynamic> toRust() {
    return {
      'filePath': filePath,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'newText': newText,
      'version': version,
    };
  }

  @override
  List<Object?> get props => [
    filePath,
    startOffset,
    endOffset,
    newText,
    version,
  ];
}
