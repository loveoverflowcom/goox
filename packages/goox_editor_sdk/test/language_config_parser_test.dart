import 'package:flutter_test/flutter_test.dart';
import 'package:goox_editor_sdk/src/syntax/language_config_parser.dart';

void main() {
  group('LanguageConfigParser', () {
    late LanguageConfigParser parser;

    setUp(() {
      parser = LanguageConfigParser();
    });

    test('parses minimal valid config', () {
      const toml = '''
name = "TestLang"
grammar = "test"
''';

      final config = parser.parse(toml);

      expect(config.name, 'TestLang');
      expect(config.grammar, 'test');
      expect(config.pathSuffixes, isEmpty);
      expect(config.lineComments, isEmpty);
      expect(config.blockComment, isNull);
      expect(config.autocloseBefore, '');
      expect(config.brackets, isEmpty);
      expect(config.hidden, false);
    });

    test('parses Dart config with all fields', () {
      const toml = '''
name = "Dart"
grammar = "dart"
path_suffixes = ["dart"]
line_comments = ["// ", "/// "]
autoclose_before = ";:.,=}])>"
brackets = [
    { start = "{", end = "}", close = true, newline = true },
    { start = "[", end = "]", close = true, newline = true },
    { start = "(", end = ")", close = true, newline = true },
    { start = "<", end = ">", close = false, newline = false},
    { start = "\\"", end = "\\"", close = true, newline = false, not_in = ["string"] },
    { start = "'", end = "'", close = true, newline = false, not_in = ["string"] },
    { start = "/*", end = " */", close = true, newline = false, not_in = ["string", "comment"] },
    { start = "`", end = "`", close = true, newline = false, not_in = ["string", "comment"] },
]
''';

      final config = parser.parse(toml);

      expect(config.name, 'Dart');
      expect(config.grammar, 'dart');
      expect(config.pathSuffixes, ['dart']);
      expect(config.lineComments, ['// ', '/// ']);
      expect(config.autocloseBefore, ';:.,=}])>');
      expect(config.brackets.length, 8);

      // Check first bracket
      final firstBracket = config.brackets[0];
      expect(firstBracket.start, '{');
      expect(firstBracket.end, '}');
      expect(firstBracket.close, true);
      expect(firstBracket.newline, true);
      expect(firstBracket.notIn, isNull);

      // Check bracket with not_in
      final stringBracket = config.brackets[4];
      expect(stringBracket.start, '"');
      expect(stringBracket.end, '"');
      expect(stringBracket.notIn, ['string']);
    });

    test('parses Lua config with block comments and indent patterns', () {
      const toml = '''
name = "Lua"
grammar = "lua"
path_suffixes = ["lua"]
line_comments = ["-- ", "--- "]
block_comment = ["--[", "]"]
autoclose_before = ";:.,=}])>"
collapsed_placeholder = "--[ ... ]--"
increase_indent_pattern = "^\\\\s*(if|elseif|else|do|while|for|repeat)"
decrease_indent_pattern = "^\\\\s*(elseif|else|end|until)\\\\b"
brackets = [
    { start = "{", end = "}", close = true, newline = true },
]
''';

      final config = parser.parse(toml);

      expect(config.name, 'Lua');
      expect(config.grammar, 'lua');
      expect(config.pathSuffixes, ['lua']);
      expect(config.lineComments, ['-- ', '--- ']);
      expect(config.blockComment, ['--[', ']']);
      expect(config.collapsedPlaceholder, '--[ ... ]--');
      expect(config.increaseIndentPattern, isNotNull);
      expect(config.decreaseIndentPattern, isNotNull);
      expect(config.brackets.length, 1);
    });

    test('parses hidden language config', () {
      const toml = '''
name = "EmmyLuadoc"
grammar = "emmyluadoc"
hidden = true
''';

      final config = parser.parse(toml);

      expect(config.name, 'EmmyLuadoc');
      expect(config.grammar, 'emmyluadoc');
      expect(config.hidden, true);
    });

    test('throws FormatException when name is missing', () {
      const toml = '''
grammar = "test"
''';

      expect(
        () => parser.parse(toml),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('name'),
        )),
      );
    });

    test('throws FormatException when grammar is missing', () {
      const toml = '''
name = "TestLang"
''';

      expect(
        () => parser.parse(toml),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('grammar'),
        )),
      );
    });

    test('throws exception on invalid TOML syntax', () {
      const toml = '''
name = "TestLang
grammar = "test"
''';

      expect(() => parser.parse(toml), throwsException);
    });

    test('validate returns null for valid config', () {
      const toml = '''
name = "TestLang"
grammar = "test"
''';

      final error = parser.validate(toml);
      expect(error, isNull);
    });

    test('validate returns error message for invalid config', () {
      const toml = '''
grammar = "test"
''';

      final error = parser.validate(toml);
      expect(error, isNotNull);
      expect(error, contains('name'));
    });

    test('validate checks grammar name against available grammars', () {
      const toml = '''
name = "TestLang"
grammar = "nonexistent"
''';

      final error = parser.validate(toml, availableGrammars: ['dart', 'lua']);
      expect(error, isNotNull);
      expect(error, contains('nonexistent'));
      expect(error, contains('does not exist'));
    });

    test('validate passes when grammar exists in available list', () {
      const toml = '''
name = "TestLang"
grammar = "dart"
''';

      final error = parser.validate(toml, availableGrammars: ['dart', 'lua']);
      expect(error, isNull);
    });

    test('validate skips grammar check when no list provided', () {
      const toml = '''
name = "TestLang"
grammar = "nonexistent"
''';

      final error = parser.validate(toml);
      expect(error, isNull);
    });

    test('handles empty brackets array', () {
      const toml = '''
name = "TestLang"
grammar = "test"
brackets = []
''';

      final config = parser.parse(toml);
      expect(config.brackets, isEmpty);
    });

    test('handles brackets with default values', () {
      const toml = '''
name = "TestLang"
grammar = "test"
brackets = [
    { start = "(", end = ")" }
]
''';

      final config = parser.parse(toml);
      expect(config.brackets.length, 1);
      expect(config.brackets[0].close, true); // default
      expect(config.brackets[0].newline, false); // default
    });

    test('skips invalid bracket entries', () {
      const toml = '''
name = "TestLang"
grammar = "test"
brackets = [
    { start = "(", end = ")" },
    { start = "{" },
    { end = "}" },
    { start = "[", end = "]" }
]
''';

      final config = parser.parse(toml);
      expect(config.brackets.length, 2); // Only valid entries
      expect(config.brackets[0].start, '(');
      expect(config.brackets[1].start, '[');
    });
  });

  group('LanguageConfig', () {
    test('equality works correctly', () {
      const config1 = LanguageConfig(
        name: 'Test',
        grammar: 'test',
        pathSuffixes: ['test'],
        lineComments: ['//'],
        autocloseBefore: '',
        brackets: [],
      );

      const config2 = LanguageConfig(
        name: 'Test',
        grammar: 'test',
        pathSuffixes: ['test'],
        lineComments: ['//'],
        autocloseBefore: '',
        brackets: [],
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('inequality works correctly', () {
      const config1 = LanguageConfig(
        name: 'Test1',
        grammar: 'test',
        pathSuffixes: [],
        lineComments: [],
        autocloseBefore: '',
        brackets: [],
      );

      const config2 = LanguageConfig(
        name: 'Test2',
        grammar: 'test',
        pathSuffixes: [],
        lineComments: [],
        autocloseBefore: '',
        brackets: [],
      );

      expect(config1, isNot(equals(config2)));
    });
  });

  group('BracketPair', () {
    test('equality works correctly', () {
      const bracket1 = BracketPair(
        start: '{',
        end: '}',
        close: true,
        newline: true,
      );

      const bracket2 = BracketPair(
        start: '{',
        end: '}',
        close: true,
        newline: true,
      );

      expect(bracket1, equals(bracket2));
      expect(bracket1.hashCode, equals(bracket2.hashCode));
    });

    test('equality with notIn field', () {
      const bracket1 = BracketPair(
        start: '"',
        end: '"',
        close: true,
        newline: false,
        notIn: ['string'],
      );

      const bracket2 = BracketPair(
        start: '"',
        end: '"',
        close: true,
        newline: false,
        notIn: ['string'],
      );

      expect(bracket1, equals(bracket2));
    });

    test('inequality works correctly', () {
      const bracket1 = BracketPair(
        start: '{',
        end: '}',
        close: true,
        newline: true,
      );

      const bracket2 = BracketPair(
        start: '(',
        end: ')',
        close: true,
        newline: true,
      );

      expect(bracket1, isNot(equals(bracket2)));
    });
  });
}
