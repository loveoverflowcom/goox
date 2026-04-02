import 'package:flutter_test/flutter_test.dart';
import 'package:goox_editor_sdk/src/syntax/query_parser.dart';
import 'package:goox_editor_sdk/src/syntax/tree_sitter_parser.dart';

void main() {
  group('QueryParser', () {
    test('can be instantiated', () {
      final queryParser = QueryParser();
      expect(queryParser, isNotNull);
    });
    
    test('ValidationResult can be created for valid query', () {
      final result = ValidationResult(isValid: true);
      expect(result.isValid, isTrue);
      expect(result.error, isNull);
      expect(result.toString(), contains('valid'));
    });
    
    test('ValidationResult can be created for invalid query', () {
      final result = ValidationResult(
        isValid: false,
        error: 'Syntax error',
        errorLine: 5,
        errorColumn: 10,
        errorOffset: 42,
      );
      
      expect(result.isValid, isFalse);
      expect(result.error, equals('Syntax error'));
      expect(result.errorLine, equals(5));
      expect(result.errorColumn, equals(10));
      expect(result.errorOffset, equals(42));
      expect(result.toString(), contains('invalid'));
      expect(result.toString(), contains('line 5'));
    });
    
    test('QueryParseException has message', () {
      final exception = QueryParseException('Invalid syntax');
      expect(exception.message, equals('Invalid syntax'));
      expect(exception.toString(), contains('QueryParseException'));
    });
    
    test('QueryParseException includes line and column', () {
      final exception = QueryParseException(
        'Invalid syntax',
        line: 3,
        column: 7,
      );
      
      expect(exception.line, equals(3));
      expect(exception.column, equals(7));
      expect(exception.toString(), contains('line 3'));
      expect(exception.toString(), contains('column 7'));
    });
  });
  
  group('QueryParser with Tree-sitter (requires library)', () {
    late TreeSitterParser parser;
    late QueryParser queryParser;
    Grammar? dartGrammar;
    
    setUpAll(() async {
      try {
        parser = TreeSitterParser();
        queryParser = QueryParser();
        dartGrammar = await parser.loadGrammar('dart');
      } catch (e) {
        // Tree-sitter library not available, tests will be skipped
        print('Tree-sitter library not available: $e');
      }
    });
    
    tearDown(() {
      try {
        parser.dispose();
      } catch (e) {
        // Ignore disposal errors if library wasn't loaded
      }
    });
    
    test('parse valid highlights query', () {
      if (dartGrammar == null) {
        print('Skipping: Dart grammar not available');
        return;
      }
      
      const querySource = '''
; Keywords
[
  "if"
  "else"
  "return"
] @keyword

; Identifiers
(identifier) @variable
''';
      
      final parsedQuery = queryParser.parse(querySource, dartGrammar!);
      expect(parsedQuery, isNotNull);
      expect(parsedQuery.patternCount, greaterThan(0));
      
      parsedQuery.dispose();
    });
    
    test('parse valid brackets query', () {
      if (dartGrammar == null) {
        print('Skipping: Dart grammar not available');
        return;
      }
      
      const querySource = '''
("(" @open
  ")" @close)

("[" @open
  "]" @close)

("{" @open
  "}" @close)
''';
      
      final parsedQuery = queryParser.parse(querySource, dartGrammar!);
      expect(parsedQuery, isNotNull);
      expect(parsedQuery.patternCount, equals(3));
      
      parsedQuery.dispose();
    });
    
    test('validate valid query', () {
      if (dartGrammar == null) {
        print('Skipping: Dart grammar not available');
        return;
      }
      
      const querySource = '''
(identifier) @variable
(string_literal) @string
''';
      
      final result = queryParser.validate(querySource, dartGrammar!);
      expect(result.isValid, isTrue);
      expect(result.error, isNull);
    });
    
    test('validate invalid query syntax', () {
      if (dartGrammar == null) {
        print('Skipping: Dart grammar not available');
        return;
      }
      
      const querySource = '''
(identifier @variable
'''; // Missing closing parenthesis
      
      final result = queryParser.validate(querySource, dartGrammar!);
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
      expect(result.errorLine, isNotNull);
      expect(result.errorColumn, isNotNull);
    });
    
    test('parse throws exception for invalid query', () {
      if (dartGrammar == null) {
        print('Skipping: Dart grammar not available');
        return;
      }
      
      const querySource = '''
(invalid_node_type) @test
''';
      
      expect(
        () => queryParser.parse(querySource, dartGrammar!),
        throwsA(isA<QueryParseException>()),
      );
    });
    
    test('execute query on syntax tree', () {
      if (dartGrammar == null) {
        print('Skipping: Dart grammar not available');
        return;
      }
      
      const code = '''
void main() {
  var x = 42;
  if (x > 0) {
    print("positive");
  }
}
''';
      
      const querySource = '''
[
  "if"
  "void"
  "var"
] @keyword
''';
      
      final tree = parser.parse(code, dartGrammar!);
      final parsedQuery = queryParser.parse(querySource, dartGrammar!);
      
      final matches = queryParser.execute(parsedQuery, tree);
      
      expect(matches, isNotEmpty);
      expect(matches.every((m) => m.captures.containsKey('keyword')), isTrue);
      
      parsedQuery.dispose();
      tree.dispose();
    });
    
    test('execute query with multiple captures', () {
      if (dartGrammar == null) {
        print('Skipping: Dart grammar not available');
        return;
      }
      
      const code = '''
String name = "test";
int count = 42;
''';
      
      const querySource = '''
(identifier) @variable
(string_literal) @string
(decimal_integer_literal) @number
''';
      
      final tree = parser.parse(code, dartGrammar!);
      final parsedQuery = queryParser.parse(querySource, dartGrammar!);
      
      final matches = queryParser.execute(parsedQuery, tree);
      
      expect(matches, isNotEmpty);
      
      // Check that we have different capture types
      final captureTypes = matches
          .expand((m) => m.captures.keys)
          .toSet();
      
      expect(captureTypes.length, greaterThan(1));
      
      parsedQuery.dispose();
      tree.dispose();
    });
    
    test('support all query file types', () {
      if (dartGrammar == null) {
        print('Skipping: Dart grammar not available');
        return;
      }
      
      // Test highlights.scm style
      const highlightsQuery = '(identifier) @variable';
      final highlightsResult = queryParser.validate(highlightsQuery, dartGrammar!);
      expect(highlightsResult.isValid, isTrue);
      
      // Test brackets.scm style
      const bracketsQuery = '("(" @open ")" @close)';
      final bracketsResult = queryParser.validate(bracketsQuery, dartGrammar!);
      expect(bracketsResult.isValid, isTrue);
      
      // Test indents.scm style
      const indentsQuery = '(_ "{" "}" @end) @indent';
      final indentsResult = queryParser.validate(indentsQuery, dartGrammar!);
      expect(indentsResult.isValid, isTrue);
    });
  });
}
