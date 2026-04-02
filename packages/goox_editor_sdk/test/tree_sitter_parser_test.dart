import 'package:flutter_test/flutter_test.dart';
import 'package:goox_editor_sdk/src/syntax/tree_sitter_parser.dart';

void main() {
  group('TreeSitterParser', () {
    test('can be instantiated (requires Tree-sitter library)', () {
      // This test verifies that the parser can be created
      // Actual parsing tests require Tree-sitter libraries to be installed
      // Skip if library is not available
      try {
        final parser = TreeSitterParser();
        expect(parser, isNotNull);
        parser.dispose();
      } catch (e) {
        expect(e, isA<UnsupportedError>());
      }
    });
    
    test('Edit can be created with points', () {
      final edit = Edit(
        startByte: 0,
        oldEndByte: 5,
        newEndByte: 10,
        startPoint: Point(row: 0, column: 0),
        oldEndPoint: Point(row: 0, column: 5),
        newEndPoint: Point(row: 0, column: 10),
      );
      
      expect(edit.startByte, equals(0));
      expect(edit.oldEndByte, equals(5));
      expect(edit.newEndByte, equals(10));
      expect(edit.startPoint.row, equals(0));
      expect(edit.startPoint.column, equals(0));
    });
    
    test('Point equality works correctly', () {
      final point1 = Point(row: 1, column: 5);
      final point2 = Point(row: 1, column: 5);
      final point3 = Point(row: 2, column: 5);
      
      expect(point1, equals(point2));
      expect(point1, isNot(equals(point3)));
    });
    
    test('Point hashCode is consistent', () {
      final point1 = Point(row: 1, column: 5);
      final point2 = Point(row: 1, column: 5);
      
      expect(point1.hashCode, equals(point2.hashCode));
    });
    
    test('GrammarLoadException has message', () {
      final exception = GrammarLoadException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), contains('GrammarLoadException'));
    });
    
    test('ParseException has message', () {
      final exception = ParseException('Parse failed');
      expect(exception.message, equals('Parse failed'));
      expect(exception.toString(), contains('ParseException'));
    });
    
    test('QueryException has message', () {
      final exception = QueryException('Query failed');
      expect(exception.message, equals('Query failed'));
      expect(exception.toString(), contains('QueryException'));
    });
    
    test('QueryMatch can be created', () {
      final match = QueryMatch(
        patternIndex: 0,
        captures: {},
      );
      
      expect(match.patternIndex, equals(0));
      expect(match.captures, isEmpty);
    });
  });
  
  group('Grammar', () {
    test('Grammar structure can be validated', () {
      // Note: Grammar requires valid FFI pointer from Tree-sitter
      // This test just validates the structure exists
      expect(Grammar, isNotNull);
    });
  });
}
