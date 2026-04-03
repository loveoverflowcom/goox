/// Custom exceptions for file system operations.
final class FileSystemException implements Exception {
  /// Creates a file system exception with a message.
  const FileSystemException(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => 'FileSystemException: $message';
}

/// Custom exceptions for cache operations.
final class CacheException implements Exception {
  /// Creates a cache exception with a message.
  const CacheException(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

/// Exception wrapper for Failure objects.
final class FailureException implements Exception {
  /// Creates a failure exception wrapping a Failure.
  const FailureException(this.failure);

  /// The wrapped failure.
  final Object failure;

  @override
  String toString() => 'FailureException: $failure';
}
