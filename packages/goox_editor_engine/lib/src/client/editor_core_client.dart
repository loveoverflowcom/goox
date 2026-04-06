import 'package:goox_editor_engine/src/exceptions/editor_core_exception.dart';
import 'package:goox_editor_engine/src/models/editor_patch.dart';
import 'package:goox_editor_engine/src/models/editor_view_state.dart';
import 'package:goox_editor_engine/src/models/language_server_hover.dart';
import 'package:goox_editor_engine/src/models/language_server_location.dart';

/// Abstract interface for editor core operations.
///
/// This interface defines all operations for interacting with the editor
/// backend, including file operations, content editing, and language server
/// features.
///
/// All methods are asynchronous to accommodate communication with the Rust
/// backend via FFI (Foreign Function Interface).
///
/// ## Error Handling
///
/// All methods may throw [EditorCoreException] when operations fail. Common
/// failure scenarios include:
/// - File not found or inaccessible
/// - Permission denied
/// - Invalid file path
/// - FFI communication errors
/// - Version conflicts (for patch operations)
/// - Language server request failures
///
/// ## Example Usage
///
/// ```dart
/// final client = RustEditorCoreClient(rustBridge);
///
/// try {
///   // Open a file
///   final viewState = await client.openFile('/path/to/file.dart');
///   print('Opened file: ${viewState.filePath}');
///
///   // Apply a patch
///   final patch = EditorPatch(
///     filePath: '/path/to/file.dart',
///     startOffset: 0,
///     endOffset: 5,
///     newText: 'Hello',
///     version: viewState.version,
///   );
///   final updatedState = await client.applyPatch(patch);
///
///   // Get hover information
///   final location = LanguageServerLocation(
///     filePath: '/path/to/file.dart',
///     line: 10,
///     column: 5,
///   );
///   final hover = await client.getHover('/path/to/file.dart', location);
///
///   // Close the file
///   await client.closeFile('/path/to/file.dart');
/// } on EditorCoreException catch (e) {
///   print('Editor operation failed: ${e.message}');
/// } finally {
///   await client.dispose();
/// }
/// ```
abstract interface class EditorCoreClient {
  /// Opens a file in the editor and returns its initial view state.
  ///
  /// This method loads the file content from disk, initializes the editor
  /// state, and prepares it for editing. The returned [EditorViewState]
  /// contains the file content, cursor position, language information, and
  /// version number for optimistic concurrency control.
  ///
  /// ## Parameters
  ///
  /// - [filePath]: The absolute path to the file to open. Must be a valid,
  ///   accessible file path.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with an [EditorViewState] containing the
  /// initial state of the opened file.
  ///
  /// ## Exceptions
  ///
  /// Throws [EditorCoreException] if:
  /// - The file does not exist
  /// - The file cannot be read (permission denied)
  /// - The file path is invalid
  /// - The file is already open
  /// - An FFI communication error occurs
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   final viewState = await client.openFile('/home/user/project/main.dart');
  ///   print('File opened: ${viewState.filePath}');
  ///   print('Content length: ${viewState.content.length}');
  ///   print('Language: ${viewState.language}');
  /// } on EditorCoreException catch (e) {
  ///   print('Failed to open file: ${e.message}');
  /// }
  /// ```
  Future<EditorViewState> openFile(String filePath);

  /// Applies a patch to the editor content and returns the updated view state.
  ///
  /// This method modifies the content of an open file by replacing a range of
  /// text with new text. The patch includes version information for optimistic
  /// concurrency control to prevent conflicting edits.
  ///
  /// ## Parameters
  ///
  /// - [patch]: The [EditorPatch] describing the change to apply. Must include:
  ///   - `filePath`: The file to modify (must be open)
  ///   - `startOffset`: Starting character offset of the range to replace
  ///   - `endOffset`: Ending character offset of the range to replace
  ///   - `newText`: The text to insert
  ///   - `version`: Expected version number (must match current version)
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with an [EditorViewState] containing the
  /// updated state after applying the patch. The version number will be
  /// incremented.
  ///
  /// ## Exceptions
  ///
  /// Throws [EditorCoreException] if:
  /// - The file is not open
  /// - The version number does not match (concurrent modification detected)
  /// - The offset range is invalid (out of bounds)
  /// - An FFI communication error occurs
  ///
  /// ## Example
  ///
  /// ```dart
  /// final patch = EditorPatch(
  ///   filePath: '/home/user/project/main.dart',
  ///   startOffset: 0,
  ///   endOffset: 5,
  ///   newText: 'import',
  ///   version: currentState.version,
  /// );
  ///
  /// try {
  ///   final updatedState = await client.applyPatch(patch);
  ///   print('Patch applied. New version: ${updatedState.version}');
  /// } on EditorCoreException catch (e) {
  ///   if (e.message.contains('Version conflict')) {
  ///     print('Concurrent modification detected. Please refresh and retry.');
  ///   } else {
  ///     print('Failed to apply patch: ${e.message}');
  ///   }
  /// }
  /// ```
  Future<EditorViewState> applyPatch(EditorPatch patch);

  /// Gets the current view state for an open file.
  ///
  /// This method retrieves the current state of a file that has been opened
  /// in the editor. It returns the latest content, cursor position, and
  /// version information.
  ///
  /// ## Parameters
  ///
  /// - [filePath]: The absolute path to the file. The file must be currently
  ///   open in the editor.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with an [EditorViewState] containing the
  /// current state of the file.
  ///
  /// ## Exceptions
  ///
  /// Throws [EditorCoreException] if:
  /// - The file is not currently open
  /// - The file path is invalid
  /// - An FFI communication error occurs
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   final viewState = await client.getViewState('/home/user/project/main.dart');
  ///   print('Current version: ${viewState.version}');
  ///   print('Is dirty: ${viewState.isDirty}');
  ///   print('Cursor at line ${viewState.cursorPosition.line}');
  /// } on EditorCoreException catch (e) {
  ///   print('Failed to get view state: ${e.message}');
  /// }
  /// ```
  Future<EditorViewState> getViewState(String filePath);

  /// Closes a file in the editor and releases associated resources.
  ///
  /// This method closes an open file, discarding any unsaved changes and
  /// freeing memory and other resources associated with the file. After
  /// closing, the file must be reopened with [openFile] before it can be
  /// edited again.
  ///
  /// ## Parameters
  ///
  /// - [filePath]: The absolute path to the file to close. The file must be
  ///   currently open in the editor.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes when the file has been closed.
  ///
  /// ## Exceptions
  ///
  /// Throws [EditorCoreException] if:
  /// - The file is not currently open
  /// - The file path is invalid
  /// - An FFI communication error occurs
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   await client.closeFile('/home/user/project/main.dart');
  ///   print('File closed successfully');
  /// } on EditorCoreException catch (e) {
  ///   print('Failed to close file: ${e.message}');
  /// }
  /// ```
  Future<void> closeFile(String filePath);

  /// Gets hover information at a specific location in a file.
  ///
  /// This method queries the language server for hover information (such as
  /// type information, documentation, or signatures) at a specific position
  /// in the source code. This is typically used to implement hover tooltips
  /// in the editor UI.
  ///
  /// ## Parameters
  ///
  /// - [filePath]: The absolute path to the file. The file must be currently
  ///   open in the editor.
  /// - [location]: The [LanguageServerLocation] specifying the position to
  ///   query. Includes line and column numbers (zero-based).
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with:
  /// - A [LanguageServerHover] containing the hover information if available
  /// - `null` if no hover information is available at the specified location
  ///
  /// ## Exceptions
  ///
  /// Throws [EditorCoreException] if:
  /// - The file is not currently open
  /// - The location is invalid (out of bounds)
  /// - The language server request fails
  /// - An FFI communication error occurs
  ///
  /// ## Example
  ///
  /// ```dart
  /// final location = LanguageServerLocation(
  ///   filePath: '/home/user/project/main.dart',
  ///   line: 10,
  ///   column: 15,
  /// );
  ///
  /// try {
  ///   final hover = await client.getHover(location.filePath, location);
  ///   if (hover != null) {
  ///     print('Hover contents: ${hover.contents}');
  ///   } else {
  ///     print('No hover information available');
  ///   }
  /// } on EditorCoreException catch (e) {
  ///   print('Failed to get hover: ${e.message}');
  /// }
  /// ```
  Future<LanguageServerHover?> getHover(
    String filePath,
    LanguageServerLocation location,
  );

  /// Gets diagnostics (errors, warnings, hints) for a file.
  ///
  /// This method retrieves all diagnostics reported by the language server
  /// for a specific file. Diagnostics include syntax errors, type errors,
  /// warnings, and hints that help developers identify and fix issues in
  /// their code.
  ///
  /// ## Parameters
  ///
  /// - [filePath]: The absolute path to the file. The file must be currently
  ///   open in the editor.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes with a [List] of diagnostics. Returns an empty
  /// list if no diagnostics are available for the file.
  ///
  /// Note: The Diagnostic type will be defined in a future task. For now,
  /// this method signature uses dynamic to allow compilation.
  ///
  /// ## Exceptions
  ///
  /// Throws [EditorCoreException] if:
  /// - The file is not currently open
  /// - The file path is invalid
  /// - The language server request fails
  /// - An FFI communication error occurs
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   final diagnostics = await client.getDiagnostics('/home/user/project/main.dart');
  ///   print('Found ${diagnostics.length} diagnostics');
  ///   for (final diagnostic in diagnostics) {
  ///     print('${diagnostic.severity}: ${diagnostic.message}');
  ///   }
  /// } on EditorCoreException catch (e) {
  ///   print('Failed to get diagnostics: ${e.message}');
  /// }
  /// ```
  Future<List<dynamic>> getDiagnostics(String filePath);

  /// Disposes resources used by the client and closes all open files.
  ///
  /// This method performs cleanup operations, including:
  /// - Closing all open files
  /// - Releasing FFI resources
  /// - Shutting down language server connections
  /// - Freeing memory
  ///
  /// After calling [dispose], the client instance should not be used anymore.
  /// Any subsequent method calls will result in undefined behavior or
  /// exceptions.
  ///
  /// ## Returns
  ///
  /// A [Future] that completes when all resources have been released.
  ///
  /// ## Exceptions
  ///
  /// Throws [EditorCoreException] if cleanup operations fail. However, the
  /// client will still be in a disposed state and should not be used.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final client = RustEditorCoreClient(rustBridge);
  ///
  /// try {
  ///   // Use the client...
  ///   await client.openFile('/path/to/file.dart');
  ///   // ... perform operations ...
  /// } finally {
  ///   // Always dispose in a finally block to ensure cleanup
  ///   await client.dispose();
  /// }
  /// ```
  Future<void> dispose();
}
