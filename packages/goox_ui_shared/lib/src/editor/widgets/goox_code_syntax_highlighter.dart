import 'package:flutter/material.dart';

import 'language_definition.dart';

class GooxCodeSyntaxHighlighter {
  GooxCodeSyntaxHighlighter({
    required this.languageId,
    required this.theme,
    required this.baseStyle,
  }) : _definition =
           LanguageDefinitionRegistry.getDefinition(languageId) ??
           LanguageDefinitionRegistry.fallback;

  final String? languageId;
  final ThemeData theme;
  final TextStyle baseStyle;
  final LanguageDefinition _definition;

  TextStyle get _keywordStyle => baseStyle.copyWith(
    color: _isDark ? const Color(0xFFC586C0) : const Color(0xFF0000FF),
    fontWeight: FontWeight.w700,
  );

  TextStyle get _typeStyle => baseStyle.copyWith(
    color: _isDark ? const Color(0xFF4EC9B0) : const Color(0xFF267F99),
  );

  TextStyle get _constantStyle => baseStyle.copyWith(
    color: _isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF),
    fontWeight: FontWeight.w700,
  );

  TextStyle get _builtinFuncStyle => baseStyle.copyWith(
    color: _isDark ? const Color(0xFFDCDCAA) : const Color(0xFF795E26),
  );

  TextStyle get _commentStyle => baseStyle.copyWith(
    color: _isDark ? const Color(0xFF6A9955) : const Color(0xFF008000),
    fontStyle: FontStyle.italic,
  );

  TextStyle get _stringStyle => baseStyle.copyWith(
    color: _isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515),
  );

  TextStyle get _numberStyle => baseStyle.copyWith(
    color: _isDark ? const Color(0xFFB5CEA8) : const Color(0xFF098658),
  );

  TextStyle get _annotationStyle => baseStyle.copyWith(
    color: _isDark ? const Color(0xFFDCDCAA) : const Color(0xFF795E26),
  );

  TextStyle get _punctuationStyle => baseStyle.copyWith(
    color: _isDark ? const Color(0xFFD4D4D4) : const Color(0xFF000000),
  );

  bool get _isDark => theme.brightness == Brightness.dark;

  List<TextSpan> highlight(String text) {
    if (text.isEmpty) {
      return const <TextSpan>[];
    }

    final spans = <TextSpan>[];
    var index = 0;

    while (index < text.length) {
      final current = text[index];

      if (current == '\n') {
        spans.add(TextSpan(text: current, style: baseStyle));
        index++;
        continue;
      }

      final commentMatch = _commentStart(text, index);
      if (commentMatch != null) {
        spans.add(TextSpan(text: commentMatch.text, style: _commentStyle));
        index = commentMatch.end;
        continue;
      }

      final stringMatch = _stringStart(text, index);
      if (stringMatch != null) {
        spans.add(TextSpan(text: stringMatch.text, style: _stringStyle));
        index = stringMatch.end;
        continue;
      }

      final annotationPrefix = _definition.annotationPrefix;
      if (annotationPrefix != null && current == annotationPrefix) {
        if (index + 1 < text.length && _isIdentifierStart(text[index + 1])) {
          final identEnd = _consumeIdentifier(text, index + 1);
          final annotation = text.substring(index, identEnd);
          spans.add(TextSpan(text: annotation, style: _annotationStyle));
          index = identEnd;
          continue;
        }
      }

      if (_isDigit(current)) {
        final numberEnd = _consumeNumber(text, index);
        spans.add(
          TextSpan(text: text.substring(index, numberEnd), style: _numberStyle),
        );
        index = numberEnd;
        continue;
      }

      if (_isIdentifierStart(current)) {
        final identifierEnd = _consumeIdentifier(text, index);
        final identifier = text.substring(index, identifierEnd);
        spans.add(
          TextSpan(text: identifier, style: _styleForIdentifier(identifier)),
        );
        index = identifierEnd;
        continue;
      }

      if (_isOperator(current)) {
        spans.add(TextSpan(text: current, style: _punctuationStyle));
      } else {
        spans.add(TextSpan(text: current, style: baseStyle));
      }
      index++;
    }

    return spans;
  }

  TextStyle _styleForIdentifier(String identifier) {
    if (_definition.keywords.contains(identifier)) {
      return _keywordStyle;
    }
    if (_definition.builtinConstants.contains(identifier)) {
      return _constantStyle;
    }
    if (_definition.builtinTypes.contains(identifier)) {
      return _typeStyle;
    }
    if (_definition.builtinFunctions.contains(identifier)) {
      return _builtinFuncStyle;
    }
    if (identifier.length > 1 &&
        identifier[0].toUpperCase() == identifier[0] &&
        identifier[0].toLowerCase() != identifier[0] &&
        !identifier.contains('_')) {
      return _typeStyle;
    }
    return baseStyle;
  }

  bool _isOperator(String char) {
    return '=<>!&|+-*/%^~?:;,.(){}[]'.contains(char);
  }

  _MatchSpan? _commentStart(String text, int index) {
    if (_definition.hashComment && text[index] == '#') {
      final end = _lineEnd(text, index);
      return _MatchSpan(text.substring(index, end), end);
    }

    final linePrefix = _definition.lineCommentPrefix;
    if (linePrefix != null && _startsWith(text, index, linePrefix)) {
      final end = _lineEnd(text, index);
      return _MatchSpan(text.substring(index, end), end);
    }

    if (_definition.hasBlockComment) {
      final blockStart = _definition.blockCommentStart!;
      if (_startsWith(text, index, blockStart)) {
        final end = _findBlockCommentEnd(
          text,
          index + blockStart.length,
          _definition.blockCommentEnd!,
        );
        return _MatchSpan(text.substring(index, end), end);
      }
    }

    return null;
  }

  _MatchSpan? _stringStart(String text, int index) {
    for (final tripleQuote in _definition.tripleQuoteDelimiters) {
      if (_startsWith(text, index, tripleQuote)) {
        final end = _findClosingTripleQuote(
          text,
          index + tripleQuote.length,
          tripleQuote,
        );
        return _MatchSpan(text.substring(index, end), end);
      }
    }

    final templateDelim = _definition.templateStringDelimiter;
    if (templateDelim != null && text[index] == templateDelim) {
      final end = _findStringEnd(
        text,
        index + 1,
        templateDelim,
        allowMultiline: true,
      );
      return _MatchSpan(text.substring(index, end), end);
    }

    final current = text[index];
    if (!_definition.stringDelimiters.contains(current)) {
      return null;
    }

    final end = _findStringEnd(text, index + 1, current, allowMultiline: false);
    return _MatchSpan(text.substring(index, end), end);
  }

  int _consumeNumber(String text, int start) {
    var index = start;
    if (index + 1 < text.length &&
        text[index] == '0' &&
        (text[index + 1] == 'x' || text[index + 1] == 'X')) {
      index += 2;
      while (index < text.length && _isHexDigit(text[index])) {
        index++;
      }
      return index;
    }
    while (index < text.length && _isDigit(text[index])) {
      index++;
    }
    if (index < text.length && text[index] == '.') {
      index++;
      while (index < text.length && _isDigit(text[index])) {
        index++;
      }
    }
    if (index < text.length && (text[index] == 'e' || text[index] == 'E')) {
      index++;
      if (index < text.length && (text[index] == '+' || text[index] == '-')) {
        index++;
      }
      while (index < text.length && _isDigit(text[index])) {
        index++;
      }
    }
    return index;
  }

  int _consumeIdentifier(String text, int start) {
    var index = start + 1;
    while (index < text.length && _isIdentifierPart(text[index])) {
      index++;
    }
    return index;
  }

  int _lineEnd(String text, int index) {
    final newline = text.indexOf('\n', index);
    return newline == -1 ? text.length : newline;
  }

  int _findBlockCommentEnd(String text, int index, String endToken) {
    final end = text.indexOf(endToken, index);
    return end == -1 ? text.length : end + endToken.length;
  }

  int _findClosingTripleQuote(String text, int index, String quote) {
    final end = text.indexOf(quote, index);
    return end == -1 ? text.length : end + quote.length;
  }

  int _findStringEnd(
    String text,
    int index,
    String quote, {
    required bool allowMultiline,
  }) {
    var escaped = false;
    var cursor = index;
    while (cursor < text.length) {
      final current = text[cursor];
      if (!allowMultiline && current == '\n') {
        return cursor;
      }

      if (escaped) {
        escaped = false;
        cursor++;
        continue;
      }

      if (current == '\\') {
        escaped = true;
        cursor++;
        continue;
      }

      if (current == quote) {
        return cursor + 1;
      }

      cursor++;
    }

    return text.length;
  }

  bool _startsWith(String text, int index, String pattern) {
    return index + pattern.length <= text.length &&
        text.substring(index, index + pattern.length) == pattern;
  }

  bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  bool _isHexDigit(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 48 && code <= 57) ||
        (code >= 65 && code <= 70) ||
        (code >= 97 && code <= 102);
  }

  bool _isIdentifierStart(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        char == '_';
  }

  bool _isIdentifierPart(String char) {
    return _isIdentifierStart(char) || _isDigit(char);
  }
}

class _MatchSpan {
  const _MatchSpan(this.text, this.end);

  final String text;
  final int end;
}
