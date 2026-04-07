import 'package:fpdart/fpdart.dart';
import 'package:goox/core/errors/failures.dart';

/// Validator for file and folder names.
///
/// Validates that names:
/// - Are not empty or whitespace-only
/// - Do not contain invalid characters: / \ : * ? " < > |
class FileNameValidator {
  /// Invalid characters that cannot be used in file/folder names.
  static const List<String> invalidChars = [
    '/',
    '\\',
    ':',
    '*',
    '?',
    '"',
    '<',
    '>',
    '|',
  ];

  /// Validates a file or folder name.
  ///
  /// Returns [Right] with the trimmed name if valid.
  /// Returns [Left] with [ValidationFailure] if invalid.
  static Either<ValidationFailure, String> validate(String name) {
    // Check if name is empty or whitespace-only
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return Left(
        ValidationFailure('File name cannot be empty'),
      );
    }

    // Check for invalid characters
    for (final char in invalidChars) {
      if (name.contains(char)) {
        return Left(
          ValidationFailure('File name cannot contain: $char'),
        );
      }
    }

    return Right(trimmedName);
  }
}
