import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
abstract class Failure extends Equatable {
  /// Creates a failure with a message.
  const Failure(this.message);

  /// The error message.
  final String message;

  @override
  List<Object> get props => [message];
}

/// Failure when reading a file fails.
final class FileReadFailure extends Failure {
  /// Creates a file read failure.
  const FileReadFailure([super.message = 'Failed to read file']);
}

/// Failure when writing a file fails.
final class FileWriteFailure extends Failure {
  /// Creates a file write failure.
  const FileWriteFailure([super.message = 'Failed to write file']);
}

/// Failure when a path is invalid.
final class InvalidPathFailure extends Failure {
  /// Creates an invalid path failure.
  const InvalidPathFailure([super.message = 'Invalid path']);
}

/// Failure when a tab is not found.
final class TabNotFoundFailure extends Failure {
  /// Creates a tab not found failure.
  const TabNotFoundFailure([super.message = 'Tab not found']);
}

/// Failure when there is no undo history.
final class NoUndoHistoryFailure extends Failure {
  /// Creates a no undo history failure.
  const NoUndoHistoryFailure([super.message = 'No undo history available']);
}

/// Failure when there is no redo history.
final class NoRedoHistoryFailure extends Failure {
  /// Creates a no redo history failure.
  const NoRedoHistoryFailure([super.message = 'No redo history available']);
}

/// Failure when loading workspace fails.
final class WorkspaceLoadFailure extends Failure {
  /// Creates a workspace load failure.
  const WorkspaceLoadFailure([super.message = 'Failed to load workspace']);
}
