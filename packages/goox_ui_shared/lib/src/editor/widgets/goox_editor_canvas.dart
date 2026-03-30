import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';

class GooxEditorTextChange {
  const GooxEditorTextChange({
    required this.start,
    required this.end,
    required this.replacement,
  });

  final int start;
  final int end;
  final String replacement;
}

class GooxCodeController extends TextEditingController {
  GooxCodeController({super.text, String? languageId})
    : _languageId = _normalizeLanguageId(languageId);

  String? _languageId;

  String? get languageId => _languageId;

  void updateLanguageId(String? value) {
    final normalized = _normalizeLanguageId(value);
    if (normalized == _languageId) {
      return;
    }

    _languageId = normalized;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle =
        style ??
        DefaultTextStyle.of(context).style.copyWith(fontFamily: 'monospace');
    final spans = _GooxSyntaxHighlighter(
      languageId: _languageId,
      theme: Theme.of(context),
      baseStyle: baseStyle,
    ).highlight(text);

    final root = TextSpan(style: baseStyle, children: spans);
    if (!withComposing || !value.composing.isValid) {
      return root;
    }

    return _underlineComposingRegion(
      text: value.text,
      composing: value.composing,
      style: baseStyle,
      root: root,
    );
  }

  static String? _normalizeLanguageId(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static TextSpan _underlineComposingRegion({
    required String text,
    required TextRange composing,
    required TextStyle style,
    required TextSpan root,
  }) {
    final start = composing.start.clamp(0, text.length);
    final end = composing.end.clamp(start, text.length);
    if (start == end) {
      return root;
    }

    final children = <InlineSpan>[];
    var index = 0;

    for (final child in root.children ?? const <InlineSpan>[]) {
      if (child is! TextSpan || child.text == null || child.text!.isEmpty) {
        children.add(child);
        continue;
      }

      final spanText = child.text!;
      final spanStart = index;
      final spanEnd = index + spanText.length;

      if (spanEnd <= start || spanStart >= end) {
        children.add(child);
      } else {
        final localStart = (start - spanStart).clamp(0, spanText.length);
        final localEnd = (end - spanStart).clamp(localStart, spanText.length);

        if (localStart > 0) {
          children.add(
            TextSpan(
              text: spanText.substring(0, localStart),
              style: child.style,
            ),
          );
        }

        children.add(
          TextSpan(
            text: spanText.substring(localStart, localEnd),
            style: (child.style ?? style).copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        );

        if (localEnd < spanText.length) {
          children.add(
            TextSpan(text: spanText.substring(localEnd), style: child.style),
          );
        }
      }

      index = spanEnd;
    }

    return TextSpan(style: root.style, children: children);
  }
}

class GooxEditorCanvas extends StatefulWidget {
  const GooxEditorCanvas({
    super.key,
    required this.state,
    required this.focusNode,
    required this.onTap,
    this.onTapDown,
    this.onTextChanged,
    this.onCursorOffsetChanged,
    this.onSyntaxErrorChanged,
    this.autofocus = false,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.normal,
  });

  final EditorViewState state;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final void Function(TapDownDetails, BuildContext)? onTapDown;
  final Future<void> Function(GooxEditorTextChange change)? onTextChanged;
  final ValueChanged<int>? onCursorOffsetChanged;
  final Future<void> Function(String? syntaxError)? onSyntaxErrorChanged;
  final bool autofocus;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  State<GooxEditorCanvas> createState() => _GooxEditorCanvasState();
}

class _GooxEditorCanvasState extends State<GooxEditorCanvas> {
  late final GooxCodeController _textController;
  bool _isApplyingExternalValue = false;
  TextEditingValue _lastEditingValue = const TextEditingValue();
  String? _lastReportedSyntaxError;
  int _validationNonce = 0;

  final ScrollController _textScrollController = ScrollController();
  final ScrollController _lineScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController = GooxCodeController(
      text: widget.state.documentText,
      languageId: widget.state.activeExtension?.languageId,
    );
    _lastEditingValue = _editingValueFromState(widget.state);
    _textController.value = _lastEditingValue;
    widget.focusNode.addListener(_handleFocusChanged);
    _textController.addListener(_handleTextEditingChanged);
    _textScrollController.addListener(_handleScrollSync);
  }

  void _handleScrollSync() {
    if (_lineScrollController.hasClients && _textScrollController.hasClients) {
      if (_lineScrollController.offset != _textScrollController.offset) {
        _lineScrollController.jumpTo(_textScrollController.offset);
      }
    }
  }

  @override
  void didUpdateWidget(covariant GooxEditorCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }

    _textController.updateLanguageId(widget.state.activeExtension?.languageId);

    final textChanged = _textController.text != widget.state.documentText;
    final selectionOutOfBounds =
        _textController.selection.start > _textController.text.length ||
        _textController.selection.end > _textController.text.length;

    if (textChanged || selectionOutOfBounds || !widget.focusNode.hasFocus) {
      final nextValue = _editingValueFromState(widget.state);
      if (_textController.value != nextValue) {
        _applyExternalValue(nextValue);
        _validateCurrentText();
      }
    }

    if (oldWidget.state.activeExtension?.languageId !=
        widget.state.activeExtension?.languageId) {
      _validateCurrentText();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    _textController.removeListener(_handleTextEditingChanged);
    _textScrollController.removeListener(_handleScrollSync);
    _textController.dispose();
    _textScrollController.dispose();
    _lineScrollController.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _applyExternalValue(TextEditingValue value) {
    _isApplyingExternalValue = true;
    _textController.value = value;
    _lastEditingValue = value;
    _isApplyingExternalValue = false;
  }

  Future<void> _validateCurrentText() async {
    final languageId = widget.state.activeExtension?.languageId
        ?.trim()
        .toLowerCase();
    if (languageId == null || languageId.isEmpty) {
      await _emitSyntaxError(null);
      return;
    }

    final text = _textController.text;
    final currentNonce = ++_validationNonce;
    debugPrint(
      'GooxCodeController.validate language=$languageId chars=${text.length}',
    );

    final syntaxError = await GooxEditorSdkBootstrap.validateSourceText(
      languageId: languageId,
      text: text,
    );

    if (!mounted || currentNonce != _validationNonce) {
      return;
    }

    debugPrint(
      'GooxCodeController.result language=$languageId error=${syntaxError ?? 'ok'}',
    );
    await _emitSyntaxError(syntaxError);
  }

  Future<void> _emitSyntaxError(String? syntaxError) async {
    if (_lastReportedSyntaxError == syntaxError) {
      return;
    }

    _lastReportedSyntaxError = syntaxError;
    final callback = widget.onSyntaxErrorChanged;
    if (callback != null) {
      await callback(syntaxError);
    }
  }

  void _handleTextEditingChanged() {
    if (_isApplyingExternalValue) {
      return;
    }

    final nextValue = _textController.value;
    final previousValue = _lastEditingValue;
    _lastEditingValue = nextValue;

    if (previousValue.text != nextValue.text) {
      final callback = widget.onTextChanged;
      if (callback != null) {
        final change = _calculateTextChange(previousValue.text, nextValue.text);
        callback(change);
      }
      unawaited(_validateCurrentText());
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final selectionCallback = widget.onCursorOffsetChanged;
    if (selectionCallback != null &&
        previousValue.selection != nextValue.selection) {
      selectionCallback(
        nextValue.selection.extentOffset.clamp(0, nextValue.text.length),
      );
    }
  }

  TextEditingValue _editingValueFromState(EditorViewState state) {
    final offset = state.cursorOffset.clamp(0, state.documentText.length);
    return TextEditingValue(
      text: state.documentText,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  GooxEditorTextChange _calculateTextChange(
    String previousText,
    String nextText,
  ) {
    var start = 0;
    final sharedLength = previousText.length < nextText.length
        ? previousText.length
        : nextText.length;

    while (start < sharedLength &&
        previousText.codeUnitAt(start) == nextText.codeUnitAt(start)) {
      start++;
    }

    var previousEnd = previousText.length;
    var nextEnd = nextText.length;
    while (previousEnd > start &&
        nextEnd > start &&
        previousText.codeUnitAt(previousEnd - 1) ==
            nextText.codeUnitAt(nextEnd - 1)) {
      previousEnd--;
      nextEnd--;
    }

    return GooxEditorTextChange(
      start: start,
      end: previousEnd,
      replacement: nextText.substring(start, nextEnd),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFocused = widget.focusNode.hasFocus;
    final lineCount = '\n'.allMatches(_textController.text).length + 1;
    final lineHeight = widget.fontSize * 1.35;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: isFocused
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Listener(
        onPointerDown: (event) {
          final callback = widget.onTapDown;
          if (callback == null) return;
          callback(
            TapDownDetails(
              globalPosition: event.position,
              localPosition: event.localPosition,
              kind: event.kind,
            ),
            context,
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.2,
                    ),
                    width: 1,
                  ),
                ),
              ),
              child: ListView.builder(
                controller: _lineScrollController,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: lineCount,
                itemBuilder: (context, index) {
                  return Container(
                    height: lineHeight,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontFamily: 'monospace',
                        fontSize: widget.fontSize * 0.75, // Scaled with main font
                        height: 1.35 * (widget.fontSize / (widget.fontSize * 0.75)),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 16,
                  top: 16,
                  bottom: 16,
                ),
                child: TextField(
                  controller: _textController,
                  scrollController: _textScrollController,
                  focusNode: widget.focusNode,
                  autofocus: widget.autofocus,
                  onTap: widget.onTap,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  cursorColor: theme.colorScheme.primary,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'monospace',
                    fontSize: widget.fontSize,
                    fontWeight: widget.fontWeight,
                    height: 1.35,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GooxSyntaxHighlighter {
  _GooxSyntaxHighlighter({
    required this.languageId,
    required this.theme,
    required this.baseStyle,
  });

  final String? languageId;
  final ThemeData theme;
  final TextStyle baseStyle;

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

      final commentStart = _commentStart(text, index);
      if (commentStart != null) {
        spans.add(
          TextSpan(
            text: commentStart.text,
            style: baseStyle.copyWith(color: theme.colorScheme.outline),
          ),
        );
        index = commentStart.end;
        continue;
      }

      final stringStart = _stringStart(text, index);
      if (stringStart != null) {
        spans.add(
          TextSpan(
            text: stringStart.text,
            style: baseStyle.copyWith(color: theme.colorScheme.tertiary),
          ),
        );
        index = stringStart.end;
        continue;
      }

      if (_isDigit(current)) {
        final numberEnd = _consumeNumber(text, index);
        spans.add(
          TextSpan(
            text: text.substring(index, numberEnd),
            style: baseStyle.copyWith(color: theme.colorScheme.secondary),
          ),
        );
        index = numberEnd;
        continue;
      }

      if (_isIdentifierStart(current)) {
        final identifierEnd = _consumeIdentifier(text, index);
        final identifier = text.substring(index, identifierEnd);
        spans.add(
          TextSpan(
            text: identifier,
            style: _keywordStyleFor(identifier) ?? baseStyle,
          ),
        );
        index = identifierEnd;
        continue;
      }

      spans.add(TextSpan(text: current, style: baseStyle));
      index++;
    }

    return spans;
  }

  TextStyle? _keywordStyleFor(String identifier) {
    final keywords = _keywordsForLanguage(languageId);
    if (!keywords.contains(identifier)) {
      return null;
    }

    return baseStyle.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
  }

  _MatchSpan? _commentStart(String text, int index) {
    if (_isPython()) {
      if (text[index] == '#') {
        return _MatchSpan(
          text.substring(index, _lineEnd(text, index)),
          _lineEnd(text, index),
        );
      }
    }

    if (_isJavaScript()) {
      if (_startsWith(text, index, '//')) {
        final end = _lineEnd(text, index);
        return _MatchSpan(text.substring(index, end), end);
      }

      if (_startsWith(text, index, '/*')) {
        final end = _findBlockCommentEnd(text, index + 2);
        return _MatchSpan(text.substring(index, end), end);
      }
    }

    return null;
  }

  _MatchSpan? _stringStart(String text, int index) {
    if (_isPython() && _startsWith(text, index, "'''")) {
      final end = _findClosingTripleQuote(text, index + 3, "'''");
      return _MatchSpan(text.substring(index, end), end);
    }

    if (_isPython() && _startsWith(text, index, '"""')) {
      final end = _findClosingTripleQuote(text, index + 3, '"""');
      return _MatchSpan(text.substring(index, end), end);
    }

    final current = text[index];
    if (current != '\'' &&
        current != '"' &&
        !(current == '`' && _isJavaScript())) {
      return null;
    }

    final quote = current;
    final allowMultiline = _isJavaScript() && quote == '`';
    final end = _findStringEnd(
      text,
      index + 1,
      quote,
      allowMultiline: allowMultiline,
    );
    return _MatchSpan(text.substring(index, end), end);
  }

  int _consumeNumber(String text, int start) {
    var index = start;
    while (index < text.length && _isDigit(text[index])) {
      index++;
    }

    if (index < text.length && text[index] == '.') {
      index++;
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

  int _findBlockCommentEnd(String text, int index) {
    final end = text.indexOf('*/', index);
    return end == -1 ? text.length : end + 2;
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

  bool _isPython() => _normalizedLanguageId == 'python';

  bool _isJavaScript() {
    final id = _normalizedLanguageId;
    return id == 'javascript' || id == 'js' || id == 'typescript';
  }

  String? get _normalizedLanguageId {
    final id = languageId?.trim().toLowerCase();
    return (id == null || id.isEmpty) ? null : id;
  }

  Set<String> _keywordsForLanguage(String? id) {
    switch (id) {
      case 'python':
        return const {
          'and',
          'as',
          'assert',
          'async',
          'await',
          'break',
          'class',
          'continue',
          'def',
          'del',
          'elif',
          'else',
          'except',
          'False',
          'finally',
          'for',
          'from',
          'global',
          'if',
          'import',
          'in',
          'is',
          'lambda',
          'None',
          'nonlocal',
          'not',
          'or',
          'pass',
          'raise',
          'return',
          'True',
          'try',
          'while',
          'with',
          'yield',
        };
      case 'javascript':
      case 'js':
      case 'typescript':
        return const {
          'async',
          'await',
          'break',
          'case',
          'catch',
          'class',
          'const',
          'continue',
          'debugger',
          'default',
          'delete',
          'do',
          'else',
          'export',
          'extends',
          'false',
          'finally',
          'for',
          'function',
          'if',
          'import',
          'in',
          'instanceof',
          'let',
          'new',
          'null',
          'return',
          'super',
          'switch',
          'this',
          'throw',
          'true',
          'try',
          'typeof',
          'undefined',
          'var',
          'void',
          'while',
          'with',
          'yield',
        };
      default:
        return const {};
    }
  }

  bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
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
