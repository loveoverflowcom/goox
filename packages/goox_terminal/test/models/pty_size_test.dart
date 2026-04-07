import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/goox_terminal.dart';

void main() {
  group('PtySize', () {
    group('constructor', () {
      test('creates instance with valid dimensions', () {
        const size = PtySize(rows: 24, cols: 80);
        expect(size.rows, equals(24));
        expect(size.cols, equals(80));
      });

      test('creates instance with minimum dimensions', () {
        const size = PtySize(rows: 1, cols: 1);
        expect(size.rows, equals(1));
        expect(size.cols, equals(1));
      });

      test('creates instance with maximum dimensions', () {
        const size = PtySize(rows: 1000, cols: 1000);
        expect(size.rows, equals(1000));
        expect(size.cols, equals(1000));
      });
    });

    group('constants', () {
      test('defaultSize is 24x80', () {
        expect(PtySize.defaultSize.rows, equals(24));
        expect(PtySize.defaultSize.cols, equals(80));
      });

      test('standard is 24x80', () {
        expect(PtySize.standard.rows, equals(24));
        expect(PtySize.standard.cols, equals(80));
      });

      test('min is 1x1', () {
        expect(PtySize.min.rows, equals(1));
        expect(PtySize.min.cols, equals(1));
      });

      test('max is 1000x1000', () {
        expect(PtySize.max.rows, equals(1000));
        expect(PtySize.max.cols, equals(1000));
      });

      test('large is 40x120', () {
        expect(PtySize.large.rows, equals(40));
        expect(PtySize.large.cols, equals(120));
      });
    });

    group('validation', () {
      test('isValid returns true for valid dimensions', () {
        const size = PtySize(rows: 24, cols: 80);
        expect(size.isValid, isTrue);
      });

      test('isValid returns true for minimum dimensions', () {
        const size = PtySize(rows: 1, cols: 1);
        expect(size.isValid, isTrue);
      });

      test('isValid returns true for maximum dimensions', () {
        const size = PtySize(rows: 1000, cols: 1000);
        expect(size.isValid, isTrue);
      });

      test('isValid returns false for rows below minimum', () {
        const size = PtySize(rows: 0, cols: 80);
        expect(size.isValid, isFalse);
      });

      test('isValid returns false for rows above maximum', () {
        const size = PtySize(rows: 1001, cols: 80);
        expect(size.isValid, isFalse);
      });

      test('isValid returns false for cols below minimum', () {
        const size = PtySize(rows: 24, cols: 0);
        expect(size.isValid, isFalse);
      });

      test('isValid returns false for cols above maximum', () {
        const size = PtySize(rows: 24, cols: 1001);
        expect(size.isValid, isFalse);
      });

      test('validate() succeeds for valid dimensions', () {
        const size = PtySize(rows: 24, cols: 80);
        expect(() => size.validate(), returnsNormally);
      });

      test('validate() throws ArgumentError for rows below minimum', () {
        const size = PtySize(rows: 0, cols: 80);
        expect(
          () => size.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Rows must be between 1 and 1000'),
            ),
          ),
        );
      });

      test('validate() throws ArgumentError for rows above maximum', () {
        const size = PtySize(rows: 1001, cols: 80);
        expect(
          () => size.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Rows must be between 1 and 1000'),
            ),
          ),
        );
      });

      test('validate() throws ArgumentError for cols below minimum', () {
        const size = PtySize(rows: 24, cols: 0);
        expect(
          () => size.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Cols must be between 1 and 1000'),
            ),
          ),
        );
      });

      test('validate() throws ArgumentError for cols above maximum', () {
        const size = PtySize(rows: 24, cols: 1001);
        expect(
          () => size.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Cols must be between 1 and 1000'),
            ),
          ),
        );
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        const size1 = PtySize(rows: 24, cols: 80);
        const size2 = PtySize(rows: 24, cols: 80);
        expect(size1, equals(size2));
      });

      test('different rows are not equal', () {
        const size1 = PtySize(rows: 24, cols: 80);
        const size2 = PtySize(rows: 25, cols: 80);
        expect(size1, isNot(equals(size2)));
      });

      test('different cols are not equal', () {
        const size1 = PtySize(rows: 24, cols: 80);
        const size2 = PtySize(rows: 24, cols: 81);
        expect(size1, isNot(equals(size2)));
      });

      test('hashCode is consistent', () {
        const size1 = PtySize(rows: 24, cols: 80);
        const size2 = PtySize(rows: 24, cols: 80);
        expect(size1.hashCode, equals(size2.hashCode));
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        const size = PtySize(rows: 24, cols: 80);
        expect(size.toString(), equals('PtySize(rows: 24, cols: 80)'));
      });
    });
  });
}
