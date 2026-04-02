import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'textmate_grammar.dart';

class TextMateThemeColorMap {
  const TextMateThemeColorMap({
    required this.lightTheme,
    required this.darkTheme,
  });

  factory TextMateThemeColorMap.vscode() {
    return TextMateThemeColorMap(
      lightTheme: const {
        'keyword': Color(0xFF0000FF),
        'type': Color(0xFF267F99),
        'string': Color(0xFFA31515),
        'comment': Color(0xFF008000),
        'number': Color(0xFF098658),
        'constant': Color(0xFF0000FF),
        'function': Color(0xFF795E26),
        'operator': Color(0xFF000000),
        'punctuation': Color(0xFF000000),
        'variable': Color(0xFF001080),
      },
      darkTheme: const {
        'keyword': Color(0xFFC586C0),
        'type': Color(0xFF4EC9B0),
        'string': Color(0xFFCE9178),
        'comment': Color(0xFF6A9955),
        'number': Color(0xFFB5CEA8),
        'constant': Color(0xFF569CD6),
        'function': Color(0xFFDCDCAA),
        'operator': Color(0xFFD4D4D4),
        'punctuation': Color(0xFFD4D4D4),
        'variable': Color(0xFF9CDCFE),
      },
    );
  }

  final Map<String, Color> lightTheme;
  final Map<String, Color> darkTheme;

  Color getColor(String scope, bool isDark) {
    final palette = isDark ? darkTheme : lightTheme;
    final category = _categoryForScope(scope);
    return palette[category] ?? palette['variable'] ?? Colors.black;
  }

  String _categoryForScope(String scope) {
    final normalized = scope.toLowerCase();
    if (normalized.contains('comment')) return 'comment';
    if (normalized.contains('string')) return 'string';
    if (normalized.contains('keyword')) return 'keyword';
    if (normalized.contains('type') || normalized.contains('class')) {
      return 'type';
    }
    if (normalized.contains('number') ||
        normalized.contains('constant.numeric')) {
      return 'number';
    }
    if (normalized.contains('constant')) return 'constant';
    if (normalized.contains('function') || normalized.contains('method')) {
      return 'function';
    }
    if (normalized.contains('operator')) return 'operator';
    if (normalized.contains('punctuation')) return 'punctuation';
    return 'variable';
  }
}

class TextMateSyntaxHighlighter {
  TextMateSyntaxHighlighter({
    required this.grammar,
    TextMateThemeColorMap? colorMap,
  }) : colorMap = colorMap ?? TextMateThemeColorMap.vscode();

  final TextMateGrammar grammar;
  final TextMateThemeColorMap colorMap;

  List<TextSpan> highlight(
    String text, {
    required ThemeData theme,
    required TextStyle baseStyle,
  }) {
    if (text.isEmpty) {
      return const [];
    }

    final isDark = theme.brightness == Brightness.dark;
    final result = <TextSpan>[];
    var index = 0;
    final stack = <_ActiveBlock>[];
    final topLevelPatterns = _expandPatterns(
      grammar.patterns,
      grammar.patterns,
    );

    while (index < text.length) {
      final active = stack.isNotEmpty ? stack.last : null;

      if (active != null) {
        final endMatch = active.endRegex.matchAsPrefix(text, index);
        if (endMatch != null) {
          result.add(
            TextSpan(
              text: text.substring(index, endMatch.end),
              style: _styleForScope(
                baseStyle,
                active.pattern.name ?? grammar.scopeName,
                isDark,
              ),
            ),
          );
          index = endMatch.end;
          stack.removeLast();
          continue;
        }
      }

      final searchPatterns = active?.childPatterns ?? topLevelPatterns;
      final candidate = _bestCandidate(text, index, searchPatterns);
      if (candidate == null) {
        result.add(TextSpan(text: text[index], style: baseStyle));
        index++;
        continue;
      }

      final tokenStyle = _styleForScope(
        baseStyle,
        candidate.pattern.name ?? grammar.scopeName,
        isDark,
      );

      if (candidate.pattern.isBeginEnd) {
        result.add(
          TextSpan(
            text: text.substring(index, candidate.match.end),
            style: tokenStyle,
          ),
        );
        final childPatterns = _expandPatterns(
          candidate.pattern.patterns ?? <TextMatePattern>[],
          searchPatterns,
        );
        stack.add(
          _ActiveBlock(
            pattern: candidate.pattern,
            endRegex: _toRegex(candidate.pattern.end!),
            childPatterns: childPatterns,
          ),
        );
        index = candidate.match.end;
        continue;
      }

      if (candidate.pattern.captures != null &&
          candidate.pattern.captures!.isNotEmpty) {
        result.addAll(
          _spansForCaptureMatch(
            text: text,
            match: candidate.match,
            baseStyle: baseStyle,
            scopeName: candidate.pattern.name ?? grammar.scopeName,
            captures: candidate.pattern.captures!,
            isDark: isDark,
          ),
        );
      } else {
        result.add(
          TextSpan(
            text: text.substring(index, candidate.match.end),
            style: tokenStyle,
          ),
        );
      }

      index = candidate.match.end;
    }

    return result;
  }

  List<TextMatePattern> _expandPatterns(
    List<TextMatePattern> source,
    List<TextMatePattern> inherited,
  ) {
    final result = <TextMatePattern>[];
    for (final pattern in source) {
      final include = pattern.include?.trim();
      if (include != null && include.isNotEmpty) {
        final included = _resolveInclude(include, inherited);
        result.addAll(included);
        continue;
      }
      result.add(pattern);
    }
    return result;
  }

  List<TextMatePattern> _resolveInclude(
    String include,
    List<TextMatePattern> inherited,
  ) {
    if (include == r'$self' || include == 'self') {
      return inherited;
    }

    if (include.startsWith('#')) {
      final key = include.substring(1);
      final referenced = grammar.repository[key];
      if (referenced == null) {
        return const [];
      }
      return [referenced];
    }

    return const [];
  }

  _Candidate? _bestCandidate(
    String text,
    int index,
    List<TextMatePattern> patterns,
  ) {
    _Candidate? best;
    for (var patternIndex = 0; patternIndex < patterns.length; patternIndex++) {
      final pattern = patterns[patternIndex];
      final regex = _patternRegex(pattern);
      if (regex == null) {
        continue;
      }

      final match = regex.matchAsPrefix(text, index);
      if (match == null || match.end <= index) {
        continue;
      }

      final candidate = _Candidate(
        pattern: pattern,
        match: match,
        specificity: _specificity(pattern) * 100000 + match.end - index,
        order: patternIndex,
      );

      if (best == null ||
          candidate.specificity > best.specificity ||
          (candidate.specificity == best.specificity &&
              candidate.order < best.order)) {
        best = candidate;
      }
    }
    return best;
  }

  RegExp? _patternRegex(TextMatePattern pattern) {
    final source = pattern.match ?? pattern.begin;
    if (source == null || source.isEmpty) {
      return null;
    }
    return _toRegex(source);
  }

  RegExp _toRegex(String source) {
    try {
      return RegExp(source, multiLine: true, dotAll: true);
    } catch (_) {
      return RegExp(RegExp.escape(source), multiLine: true, dotAll: true);
    }
  }

  int _specificity(TextMatePattern pattern) {
    if (pattern.isBeginEnd) {
      return 3;
    }
    if (pattern.match != null) {
      return 2;
    }
    return 1;
  }

  List<TextSpan> _spansForCaptureMatch({
    required String text,
    required Match match,
    required TextStyle baseStyle,
    required String scopeName,
    required Map<String, TextMateCapture> captures,
    required bool isDark,
  }) {
    final spans = <TextSpan>[];
    var cursor = match.start;

    for (
      var captureIndex = 1;
      captureIndex <= match.groupCount;
      captureIndex++
    ) {
      final groupText = match.group(captureIndex);
      if (groupText == null || groupText.isEmpty) {
        continue;
      }

      final groupStart = _groupStart(match, captureIndex, cursor);
      final groupEnd = groupStart + groupText.length;
      if (groupStart > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, groupStart),
            style: _styleForScope(baseStyle, scopeName, isDark),
          ),
        );
      }

      final capture = captures[captureIndex.toString()];
      final captureStyle = _styleForScope(
        baseStyle,
        capture?.name ?? scopeName,
        isDark,
      );

      if (capture?.patterns != null && capture!.patterns!.isNotEmpty) {
        spans.addAll(
          highlight(
            groupText,
            theme: ThemeData(
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
            baseStyle: captureStyle,
          ),
        );
      } else {
        spans.add(TextSpan(text: groupText, style: captureStyle));
      }

      cursor = math.max(cursor, groupEnd);
    }

    if (cursor < match.end) {
      spans.add(
        TextSpan(
          text: text.substring(cursor, match.end),
          style: _styleForScope(baseStyle, scopeName, isDark),
        ),
      );
    }

    return spans;
  }

  int _groupStart(Match match, int groupIndex, int fallback) {
    return fallback;
  }

  TextStyle _styleForScope(TextStyle baseStyle, String scope, bool isDark) {
    final color = colorMap.getColor(scope, isDark);
    return baseStyle.copyWith(color: color);
  }
}

class _ActiveBlock {
  _ActiveBlock({
    required this.pattern,
    required this.endRegex,
    required this.childPatterns,
  });

  final TextMatePattern pattern;
  final RegExp endRegex;
  final List<TextMatePattern> childPatterns;
}

class _Candidate {
  _Candidate({
    required this.pattern,
    required this.match,
    required this.specificity,
    required this.order,
  });

  final TextMatePattern pattern;
  final Match match;
  final int specificity;
  final int order;
}
