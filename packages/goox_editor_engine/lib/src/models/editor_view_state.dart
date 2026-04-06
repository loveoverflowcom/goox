import 'package:equatable/equatable.dart';
import 'package:goox_editor_engine/src/models/cursor_position.dart';

/// Represents the current state of an editor view.
///
/// This class encapsulates all information about an open file in the editor,
/// including its content, cursor position, language, modification status, and
/// version for optimistic concurrency control.
///
/// This class is immutable and implements value equality through [Equatable].
final class EditorViewState extends Equatable {
  /// Creates an [EditorViewState] with the specified properties.
  ///
  /// All parameters are required.
  const EditorViewState({
    required this.filePath,
    required this.content,
    required this.cursorPosition,
    required this.language,
    required this.isDirty,
    required this.version,
  });

  /// Creates an [EditorViewState] from Rust bridge data.
  ///
  /// This factory constructor is used to convert data received from the
  /// Rust backend via flutter_rust_bridge into a Dart [EditorViewState].
  ///
  /// The [rust] parameter should be an object with `filePath`, `content`,
  /// `cursorPosition`, `language`, `isDirty`, and `version` fields.
  factory EditorViewState.fromRust(Object rust) {
    // Using dynamic access since the exact Rust bridge type isn't defined yet
    // This will be updated when flutter_rust_bridge types are generated
    final rustMap = rust as Map<String, dynamic>;
    return EditorViewState(
      filePath: rustMap['filePath'] as String,
      content: rustMap['content'] as String,
      cursorPosition: CursorPosition.fromRust(rustMap['cursorPosition'] as Object),
      language: rustMap['language'] as String,
      isDirty: rustMap['isDirty'] as bool,
      version: rustMap['version'] as int,
    );
  }

  /// The absolute path to the file.
  ///
  /// This should be a fully qualified path to the file being edited.
  final String filePath;

  /// The current content of the file.
  ///
  /// This represents the complete text content of the file as it currently
  /// appears in the editor, including any unsaved changes.
  final String content;

  /// The current cursor position in the editor.
  ///
  /// This indicates where the user's cursor is currently located within
  /// the file content.
  final CursorPosition cursorPosition;

  /// The programming language of the file.
  ///
  /// This is typically determined by the file extension and is used for
  /// syntax highlighting and language-specific features.
  final String language;

  /// Whether the file has unsaved changes.
  ///
  /// This is `true` if the content has been modified since the last save,
  /// and `false` otherwise.
  final bool isDirty;

  /// Version number for optimistic concurrency control.
  ///
  /// This version number is incremented each time the file content is modified.
  /// It is used to detect conflicts when multiple operations attempt to modify
  /// the same file concurrently.
  final int version;

  /// Creates a copy of this [EditorViewState] with the given fields replaced
  /// with new values.
  ///
  /// If a parameter is not provided, the corresponding field from this
  /// instance is used.
  EditorViewState copyWith({
    String? filePath,
    String? content,
    CursorPosition? cursorPosition,
    String? language,
    bool? isDirty,
    int? version,
  }) {
    return EditorViewState(
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      language: language ?? this.language,
      isDirty: isDirty ?? this.isDirty,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        filePath,
        content,
        cursorPosition,
        language,
        isDirty,
        version,
      ];
}
