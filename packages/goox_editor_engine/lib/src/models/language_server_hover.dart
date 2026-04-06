import 'package:equatable/equatable.dart';
import 'package:goox_editor_engine/src/models/language_server_range.dart';

/// Represents hover information from the language server.
///
/// Hover information is displayed when the user hovers over a symbol in the
/// editor. It typically contains:
/// - [contents]: Documentation or type information (markdown formatted)
/// - [range]: The optional range in the document that this hover applies to
///
/// This class is used for language server protocol (LSP) hover operations.
///
/// This class is immutable and implements value equality through [Equatable].
final class LanguageServerHover extends Equatable {
  /// Creates a [LanguageServerHover] with the specified contents and optional
  /// range.
  ///
  /// The [contents] parameter is required and contains the hover information
  /// (typically markdown formatted text).
  ///
  /// The [range] parameter is optional and specifies the range in the document
  /// that this hover applies to.
  const LanguageServerHover({
    required this.contents,
    this.range,
  });

  /// Creates a [LanguageServerHover] from Rust bridge data.
  ///
  /// This factory constructor is used to convert data received from the
  /// Rust backend via flutter_rust_bridge into a Dart [LanguageServerHover].
  ///
  /// The [rust] parameter should be an object with `contents` and optional
  /// `range` fields.
  factory LanguageServerHover.fromRust(Object rust) {
    // Using dynamic access since the exact Rust bridge type isn't defined yet
    // This will be updated when flutter_rust_bridge types are generated
    final rustMap = rust as Map<String, dynamic>;
    return LanguageServerHover(
      contents: rustMap['contents'] as String,
      range: rustMap['range'] != null
          ? LanguageServerRange.fromRust(rustMap['range'] as Object)
          : null,
    );
  }

  /// The hover contents (markdown formatted).
  ///
  /// This typically contains documentation, type information, or other
  /// contextual information about the symbol being hovered over.
  final String contents;

  /// The range this hover applies to (optional).
  ///
  /// If provided, this specifies the exact range in the document that this
  /// hover information applies to. If null, the hover applies to the position
  /// where it was requested.
  final LanguageServerRange? range;

  /// Creates a copy of this [LanguageServerHover] with the given fields
  /// replaced with new values.
  ///
  /// If a parameter is not provided, the corresponding field from this
  /// instance is used.
  LanguageServerHover copyWith({
    String? contents,
    LanguageServerRange? range,
  }) {
    return LanguageServerHover(
      contents: contents ?? this.contents,
      range: range ?? this.range,
    );
  }

  @override
  List<Object?> get props => [contents, range];
}
