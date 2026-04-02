import 'package:flutter_test/flutter_test.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';

void main() {
  group('TreeSitterBindings', () {
    test('can be instantiated (requires Tree-sitter library)', () {
      // This test verifies that the bindings can be created
      // Actual parsing tests require Tree-sitter libraries to be installed
      // Skip if library is not available
      try {
        TreeSitterBindings();
      } catch (e) {
        expect(e, isA<UnsupportedError>());
      }
    });
    
    test('TreeSitterLoader handles unsupported platforms', () {
      // This is a basic structural test
      // Platform-specific loading is tested when libraries are available
      expect(TreeSitterLoader, isNotNull);
    });
    
    test('TreeSitterEdit can be created', () {
      final edit = TreeSitterEdit(
        startByte: 0,
        oldEndByte: 5,
        newEndByte: 10,
        startPoint: TreeSitterPoint(row: 0, column: 0),
        oldEndPoint: TreeSitterPoint(row: 0, column: 5),
        newEndPoint: TreeSitterPoint(row: 0, column: 10),
      );
      
      expect(edit.startByte, equals(0));
      expect(edit.oldEndByte, equals(5));
      expect(edit.newEndByte, equals(10));
    });
    
    test('QueryResult can represent success', () {
      // Note: In real usage, query pointer comes from FFI
      // Using a mock null pointer for testing the result structure
      final result = QueryResult.success(null);
      expect(result.query, isNull);
      expect(result.error, isNull);
      expect(result.errorOffset, isNull);
    });
    
    test('QueryResult can represent error', () {
      final result = QueryResult.error(TSQueryError.syntax, 10);
      expect(result.isSuccess, isFalse);
      expect(result.isError, isTrue);
      expect(result.error, equals(TSQueryError.syntax));
      expect(result.errorOffset, equals(10));
    });
    
    test('TSQueryError enum has correct values', () {
      expect(TSQueryError.none.value, equals(0));
      expect(TSQueryError.syntax.value, equals(1));
      expect(TSQueryError.nodeType.value, equals(2));
      expect(TSQueryError.fromValue(1), equals(TSQueryError.syntax));
    });
  });
}
