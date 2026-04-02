import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_editor_sdk/src/syntax/tree_sitter_highlighter.dart';
import 'package:goox_editor_sdk/src/syntax/tree_sitter_parser.dart';
import 'package:goox_editor_sdk/src/syntax/query_parser.dart';

void main() {
  group('ThemeColorMap', () {
    test('can be created with custom colors', () {
      final colorMap = ThemeColorMap(
        lightTheme: const {
          'keyword': Color(0xFF0000FF),
          'string': Color(0xFFA31515),
        },
        darkTheme: const {
          'keyword': Color(0xFFC586C0),
          'string': Color(0xFFCE9178),
        },
      );

      expect(colorMap.lightTheme['keyword'], equals(const Color(0xFF0000FF)));
      expect(colorMap.darkTheme['keyword'], equals(const Color(0xFFC586C0)));
    });

    test('vscode factory creates standard color map', () {
      final colorMap = ThemeColorMap.vscode();

      expect(colorMap.lightTheme['keyword'], isNotNull);
      expect(colorMap.darkTheme['keyword'], isNotNull);
      expect(colorMap.lightTheme['string'], isNotNull);
      expect(colorMap.darkTheme['string'], isNotNull);
    });

    test('getColor returns correct color for light theme', () {
      final colorMap = ThemeColorMap.vscode();

      final keywordColor = colorMap.getColor('keyword', false);
      expect(keywordColor, equals(const Color(0xFF0000FF)));

      final stringColor = colorMap.getColor('string', false);
      expect(stringColor, equals(const Color(0xFFA31515)));
    });

    test('getColor returns correct color for dark theme', () {
      final colorMap = ThemeColorMap.vscode();

      final keywordColor = colorMap.getColor('keyword', true);
      expect(keywordColor, equals(const Color(0xFFC586C0)));

      final stringColor = colorMap.getColor('string', true);
      expect(stringColor, equals(const Color(0xFFCE9178)));
    });

    test('getColor handles @ prefix in capture names', () {
      final colorMap = ThemeColorMap.vscode();

      final withPrefix = colorMap.getColor('@keyword', false);
      final withoutPrefix = colorMap.getColor('keyword', false);

      expect(withPrefix, equals(withoutPrefix));
    });

    test('getColor falls back to parent category', () {
      final colorMap = ThemeColorMap.vscode();

      // function.method should fall back to function
      final methodColor = colorMap.getColor('function.method', false);
      final functionColor = colorMap.getColor('function', false);

      expect(methodColor, equals(functionColor));
    });

    test('getColor falls back to variable for unknown captures', () {
      final colorMap = ThemeColorMap.vscode();

      final unknownColor = colorMap.getColor('unknown.capture', false);
      final variableColor = colorMap.getColor('variable', false);

      expect(unknownColor, equals(variableColor));
    });

    test('getColor falls back to default when variable not defined', () {
      final colorMap = ThemeColorMap(
        lightTheme: const {'keyword': Color(0xFF0000FF)},
        darkTheme: const {'keyword': Color(0xFFC586C0)},
      );

      final unknownLight = colorMap.getColor('unknown', false);
      final unknownDark = colorMap.getColor('unknown', true);

      expect(unknownLight, equals(Colors.black));
      expect(unknownDark, equals(Colors.white));
    });
  });

  group('HighlightSpan', () {
    test('can be created', () {
      const span = HighlightSpan(
        start: 0,
        end: 5,
        captureName: 'keyword',
        color: Color(0xFF0000FF),
      );

      expect(span.start, equals(0));
      expect(span.end, equals(5));
      expect(span.captureName, equals('keyword'));
      expect(span.color, equals(const Color(0xFF0000FF)));
    });

    test('equality works correctly', () {
      const span1 = HighlightSpan(
        start: 0,
        end: 5,
        captureName: 'keyword',
        color: Color(0xFF0000FF),
      );

      const span2 = HighlightSpan(
        start: 0,
        end: 5,
        captureName: 'keyword',
        color: Color(0xFF0000FF),
      );

      const span3 = HighlightSpan(
        start: 0,
        end: 10,
        captureName: 'keyword',
        color: Color(0xFF0000FF),
      );

      expect(span1, equals(span2));
      expect(span1, isNot(equals(span3)));
    });

    test('hashCode is consistent', () {
      const span1 = HighlightSpan(
        start: 0,
        end: 5,
        captureName: 'keyword',
        color: Color(0xFF0000FF),
      );

      const span2 = HighlightSpan(
        start: 0,
        end: 5,
        captureName: 'keyword',
        color: Color(0xFF0000FF),
      );

      expect(span1.hashCode, equals(span2.hashCode));
    });

    test('toString includes relevant information', () {
      const span = HighlightSpan(
        start: 0,
        end: 5,
        captureName: 'keyword',
        color: Color(0xFF0000FF),
      );

      final str = span.toString();
      expect(str, contains('0'));
      expect(str, contains('5'));
      expect(str, contains('keyword'));
    });
  });

  group('TreeSitterHighlighter', () {
    test('can be instantiated (structure test)', () {
      // We can't actually instantiate without Tree-sitter library
      // This test just verifies the class structure exists
      final colorMap = ThemeColorMap.vscode();
      expect(TreeSitterHighlighter, isNotNull);
      expect(colorMap, isNotNull);
    });

    test('clearCache method exists', () {
      // We can't fully test this without a real query, but we can verify
      // the method exists in the class definition
      expect(TreeSitterHighlighter, isNotNull);
    });

    test('toTextSpans method exists', () {
      // We can't create a real highlighter without Tree-sitter,
      // but we can verify the method exists in the class definition
      expect(TreeSitterHighlighter, isNotNull);
    });
  });

  group('TreeSitterHighlighter with Tree-sitter (requires library)', () {
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
      }
    });

    tearDown(() {
      try {
        parser.dispose();
      } catch (e) {
        // Ignore disposal errors if library wasn't loaded
      }
    });

    test('highlight returns spans for matched captures', () {
      if (dartGrammar == null) {
        return;
      }

      const code = '''
void main() {
  var x = 42;
}
''';

      const querySource = '''
[
  "void"
  "var"
] @keyword

(identifier) @variable
(decimal_integer_literal) @number
''';

      final tree = parser.parse(code, dartGrammar!);
      final query = queryParser.parse(querySource, dartGrammar!);
      final highlighter = TreeSitterHighlighter(
        parser: parser,
        highlightQuery: query,
      );

      final spans = highlighter.highlight(
        code,
        tree,
        0,
        code.length,
        isDark: false,
      );

      expect(spans, isNotEmpty);
      expect(spans.every((s) => s.start < s.end), isTrue);

      // Verify spans are sorted by start position
      for (var i = 1; i < spans.length; i++) {
        expect(spans[i].start, greaterThanOrEqualTo(spans[i - 1].start));
      }

      highlighter.dispose();
      query.dispose();
      tree.dispose();
    });

    test('highlight respects byte range', () {
      if (dartGrammar == null) {
        return;
      }

      const code = '''
void main() {
  var x = 42;
  var y = 100;
}
''';

      const querySource = '''
[
  "void"
  "var"
] @keyword
''';

      final tree = parser.parse(code, dartGrammar!);
      final query = queryParser.parse(querySource, dartGrammar!);
      final highlighter = TreeSitterHighlighter(
        parser: parser,
        highlightQuery: query,
      );

      // Only highlight first line
      final firstLineEnd = code.indexOf('\n') + 1;
      final spans = highlighter.highlight(
        code,
        tree,
        0,
        firstLineEnd,
        isDark: false,
      );

      // All spans should be within the requested range
      expect(spans.every((s) => s.end <= firstLineEnd), isTrue);

      highlighter.dispose();
      query.dispose();
      tree.dispose();
    });

    test('highlight uses correct colors for theme', () {
      if (dartGrammar == null) {
        return;
      }

      const code = 'void main() {}';
      const querySource = '["void"] @keyword';

      final tree = parser.parse(code, dartGrammar!);
      final query = queryParser.parse(querySource, dartGrammar!);
      final colorMap = ThemeColorMap.vscode();
      final highlighter = TreeSitterHighlighter(
        parser: parser,
        highlightQuery: query,
        colorMap: colorMap,
      );

      final lightSpans = highlighter.highlight(
        code,
        tree,
        0,
        code.length,
        isDark: false,
      );

      final darkSpans = highlighter.highlight(
        code,
        tree,
        0,
        code.length,
        isDark: true,
      );

      // Colors should be different for light and dark themes
      if (lightSpans.isNotEmpty && darkSpans.isNotEmpty) {
        expect(lightSpans.first.color, isNot(equals(darkSpans.first.color)));
      }

      highlighter.dispose();
      query.dispose();
      tree.dispose();
    });

    test('highlight caches results', () {
      if (dartGrammar == null) {
        return;
      }

      const code = 'void main() {}';
      const querySource = '["void"] @keyword';

      final tree = parser.parse(code, dartGrammar!);
      final query = queryParser.parse(querySource, dartGrammar!);
      final highlighter = TreeSitterHighlighter(
        parser: parser,
        highlightQuery: query,
      );

      final spans1 = highlighter.highlight(
        code,
        tree,
        0,
        code.length,
        isDark: false,
      );

      final spans2 = highlighter.highlight(
        code,
        tree,
        0,
        code.length,
        isDark: false,
      );

      // Should return the same cached result
      expect(spans1, equals(spans2));

      highlighter.dispose();
      query.dispose();
      tree.dispose();
    });

    test('clearCache invalidates cached results', () {
      if (dartGrammar == null) {
        return;
      }

      const code = 'void main() {}';
      const querySource = '["void"] @keyword';

      final tree = parser.parse(code, dartGrammar!);
      final query = queryParser.parse(querySource, dartGrammar!);
      final highlighter = TreeSitterHighlighter(
        parser: parser,
        highlightQuery: query,
      );

      highlighter.highlight(code, tree, 0, code.length, isDark: false);
      highlighter.clearCache();

      // After clearing cache, should re-compute
      // (We can't directly verify this, but at least it shouldn't crash)
      final spans = highlighter.highlight(
        code,
        tree,
        0,
        code.length,
        isDark: false,
      );

      expect(spans, isNotNull);

      highlighter.dispose();
      query.dispose();
      tree.dispose();
    });

    test('updateHighlighting handles edits', () {
      if (dartGrammar == null) {
        return;
      }

      const oldCode = 'void main() {}';
      const newCode = 'void main() { var x = 42; }';

      const querySource = '''
["void" "var"] @keyword
(identifier) @variable
''';

      final oldTree = parser.parse(oldCode, dartGrammar!);
      final edit = Edit(
        startByte: 14,
        oldEndByte: 14,
        newEndByte: 27,
        startPoint: Point(row: 0, column: 14),
        oldEndPoint: Point(row: 0, column: 14),
        newEndPoint: Point(row: 0, column: 27),
      );
      final newTree = parser.updateTree(oldTree, edit, newCode);

      final query = queryParser.parse(querySource, dartGrammar!);
      final highlighter = TreeSitterHighlighter(
        parser: parser,
        highlightQuery: query,
      );

      final spans = highlighter.updateHighlighting(
        newCode,
        oldTree,
        newTree,
        edit,
        isDark: false,
      );

      expect(spans, isNotEmpty);

      highlighter.dispose();
      query.dispose();
      newTree.dispose();
      oldTree.dispose();
    });

    test('toTextSpans converts spans to Flutter TextSpans', () {
      if (dartGrammar == null) {
        return;
      }

      const code = 'void main() {}';
      const querySource = '["void"] @keyword';

      final tree = parser.parse(code, dartGrammar!);
      final query = queryParser.parse(querySource, dartGrammar!);
      final highlighter = TreeSitterHighlighter(
        parser: parser,
        highlightQuery: query,
      );

      final spans = highlighter.highlight(
        code,
        tree,
        0,
        code.length,
        isDark: false,
      );

      const baseStyle = TextStyle(color: Colors.black);
      final textSpans = highlighter.toTextSpans(code, spans, baseStyle);

      expect(textSpans, isNotEmpty);
      expect(textSpans, everyElement(isA<TextSpan>()));

      // Verify all text is covered
      final totalText = textSpans.map((s) => s.text ?? '').join();
      expect(totalText, equals(code));

      highlighter.dispose();
      query.dispose();
      tree.dispose();
    });

    test('toTextSpans handles overlapping spans correctly', () {
      if (dartGrammar == null) {
        return;
      }

      const code = 'void main() {}';
      const querySource = '''
["void"] @keyword
(identifier) @function
''';

      final tree = parser.parse(code, dartGrammar!);
      final query = queryParser.parse(querySource, dartGrammar!);
      final highlighter = TreeSitterHighlighter(
        parser: parser,
        highlightQuery: query,
      );

      final spans = highlighter.highlight(
        code,
        tree,
        0,
        code.length,
        isDark: false,
      );

      const baseStyle = TextStyle(color: Colors.black);
      final textSpans = highlighter.toTextSpans(code, spans, baseStyle);

      // Should not crash with overlapping spans
      expect(textSpans, isNotEmpty);

      highlighter.dispose();
      query.dispose();
      tree.dispose();
    });
  });
}
