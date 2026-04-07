import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/file_explorer/data/validators/file_name_validator.dart';

void main() {
  group('FileNameValidator', () {
    group('validate', () {
      test('should reject empty name', () {
        // Arrange
        const name = '';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure.message,
            'File name cannot be empty',
          ),
          (_) => fail('Should return Left'),
        );
      });

      test('should reject whitespace-only name', () {
        // Arrange
        const name = '   ';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure.message,
            'File name cannot be empty',
          ),
          (_) => fail('Should return Left'),
        );
      });

      test('should reject name with forward slash', () {
        // Arrange
        const name = 'file/name';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure.message,
            'File name cannot contain: /',
          ),
          (_) => fail('Should return Left'),
        );
      });

      test('should reject name with backslash', () {
        // Arrange
        const name = 'file\\name';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure.message,
            'File name cannot contain: \\',
          ),
          (_) => fail('Should return Left'),
        );
      });

      test('should reject name with colon', () {
        // Arrange
        const name = 'file:name';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure.message,
            'File name cannot contain: :',
          ),
          (_) => fail('Should return Left'),
        );
      });

      test('should reject name with asterisk', () {
        // Arrange
        const name = 'file*name';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure.message,
            'File name cannot contain: *',
          ),
          (_) => fail('Should return Left'),
        );
      });

      test('should reject name with question mark', () {
        // Arrange
        const name = 'file?name';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure.message,
            'File name cannot contain: ?',
          ),
          (_) => fail('Should return Left'),
        );
      });

      test('should reject name with double quote', () {
        // Arrange
        const name = 'file"name';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure.message,
            'File name cannot contain: "',
          ),
          (_) => fail('Should return Left'),
        );
      });

      test('should reject name with less than', () {
        // Arrange
        const name = 'file<name';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure.message,
            'File name cannot contain: <',
          ),
          (_) => fail('Should return Left'),
        );
      });

      test('should reject name with greater than', () {
        // Arrange
        const name = 'file>name';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure.message,
            'File name cannot contain: >',
          ),
          (_) => fail('Should return Left'),
        );
      });

      test('should reject name with pipe', () {
        // Arrange
        const name = 'file|name';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(
            failure.message,
            'File name cannot contain: |',
          ),
          (_) => fail('Should return Left'),
        );
      });

      test('should accept valid file name with extension', () {
        // Arrange
        const name = 'file.txt';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (validName) => expect(validName, 'file.txt'),
        );
      });

      test('should accept valid file name with hyphen', () {
        // Arrange
        const name = 'my-file.dart';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (validName) => expect(validName, 'my-file.dart'),
        );
      });

      test('should accept valid file name with underscore', () {
        // Arrange
        const name = 'file_name.json';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (validName) => expect(validName, 'file_name.json'),
        );
      });

      test('should accept valid file name with numbers', () {
        // Arrange
        const name = 'file123.md';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (validName) => expect(validName, 'file123.md'),
        );
      });

      test('should accept valid file name with multiple dots', () {
        // Arrange
        const name = 'file.name.with.dots.txt';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (validName) => expect(validName, 'file.name.with.dots.txt'),
        );
      });

      test('should trim whitespace from valid name', () {
        // Arrange
        const name = '  file.txt  ';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (validName) => expect(validName, 'file.txt'),
        );
      });

      test('should accept folder name without extension', () {
        // Arrange
        const name = 'my_folder';

        // Act
        final result = FileNameValidator.validate(name);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should return Right'),
          (validName) => expect(validName, 'my_folder'),
        );
      });
    });
  });
}
