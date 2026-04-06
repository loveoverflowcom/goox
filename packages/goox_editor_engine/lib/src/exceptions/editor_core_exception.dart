/// Exception thrown when editor core operations fail.
///
/// This exception wraps errors that occur during editor core operations,
/// providing a descriptive message along with the original error and stack trace
/// for debugging purposes.
final class EditorCoreException implements Exception {
  /// Creates an [EditorCoreException] with the given [message].
  ///
  /// Optionally includes the [originalError] that caused this exception
  /// and the [stackTrace] where the error occurred.
  const EditorCoreException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  /// Human-readable error message describing what went wrong.
  final String message;

  /// The original error that caused this exception, if any.
  final Object? originalError;

  /// Stack trace captured when the error occurred, if available.
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('EditorCoreException: $message');
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    return buffer.toString();
  }
}
