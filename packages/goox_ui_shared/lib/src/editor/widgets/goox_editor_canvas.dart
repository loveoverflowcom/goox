import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';

import 'language_definition.dart';

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
  List<LanguageServerDocumentHighlight> _lspHighlights = [];

  String? get languageId => _languageId;

  void updateLspHighlights(List<LanguageServerDocumentHighlight> value) {
    if (listEquals(_lspHighlights, value)) {
      return;
    }
    _lspHighlights = value;
    notifyListeners();
  }

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
    var spans = _GooxSyntaxHighlighter(
      languageId: _languageId,
      theme: Theme.of(context),
      baseStyle: baseStyle,
    ).highlight(text);

    if (_lspHighlights.isNotEmpty) {
      spans = _applyHighlights(
        spans,
        text,
        _lspHighlights,
        theme: Theme.of(context),
        baseTextStyle: baseStyle,
      );
    }

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

  List<TextSpan> _applyHighlights(
    List<TextSpan> spans,
    String text,
    List<LanguageServerDocumentHighlight> highlights, {
    required ThemeData theme,
    required TextStyle baseTextStyle,
  }) {
    if (highlights.isEmpty) return spans;

    final highlightRanges = highlights.map((h) {
      final start = _getOffset(
        text,
        h.range.start.line,
        h.range.start.character,
      );
      final end = _getOffset(text, h.range.end.line, h.range.end.character);
      return TextRange(start: start, end: end);
    }).toList();

    final result = <TextSpan>[];
    var currentOffset = 0;

    for (final span in spans) {
      final spanText = span.text ?? '';
      if (spanText.isEmpty) {
        result.add(span);
        continue;
      }

      final spanStart = currentOffset;
      final spanEnd = currentOffset + spanText.length;

      // Check if this span intersects with any highlight
      bool intersected = false;
      for (final range in highlightRanges) {
        if (range.start < spanEnd && range.end > spanStart) {
          // Intersection found. For simplicity, we'll just style the whole span if it intersects.
          // In a better implementation, we'd split the span.
          result.add(
            TextSpan(
              text: spanText,
              style: (span.style ?? baseTextStyle).copyWith(
                backgroundColor: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                decoration: TextDecoration.underline,
                decorationColor: theme.colorScheme.primary,
              ),
            ),
          );
          intersected = true;
          break;
        }
      }

      if (!intersected) {
        result.add(span);
      }
      currentOffset = spanEnd;
    }

    return result;
  }

  int _getOffset(String text, int line, int character) {
    final lines = text.split('\n');
    var offset = 0;
    for (var i = 0; i < line && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    return offset + character;
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
    this.onGoToDefinition,
    this.onGoToDeclaration,
    this.onGoToImplementation,
    this.onFindReferences,
    this.onHover,
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
  final VoidCallback? onGoToDefinition;
  final VoidCallback? onGoToDeclaration;
  final VoidCallback? onGoToImplementation;
  final VoidCallback? onFindReferences;
  final ValueChanged<int>? onHover;
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

  Timer? _hoverTimer;
  Offset? _lastMousePosition;
  int? _pendingHoverOffset;
  int? _lastDispatchedHoverOffset;

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
    _textController.updateLspHighlights(widget.state.lspHighlights);

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
      child: Stack(
        children: [
          Listener(
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
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontFamily: 'monospace',
                            fontSize:
                                widget.fontSize * 0.75, // Scaled with main font
                            height:
                                1.35 *
                                (widget.fontSize / (widget.fontSize * 0.75)),
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
                    child: MouseRegion(
                      opaque: false,
                      onHover: _handleMouseMove,
                      onExit: (_) {
                        _hoverTimer?.cancel();
                        _lastMousePosition = null;
                        _pendingHoverOffset = null;
                        _lastDispatchedHoverOffset = null;
                        widget.onHover?.call(-1); // Signal to clear hover
                      },
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
                        contextMenuBuilder: (context, editableTextState) {
                          return _buildContextMenu(context, editableTextState);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.state.lspHover != null && _lastMousePosition != null)
            Positioned(
              left: _lastMousePosition!.dx + 10,
              top: _lastMousePosition!.dy + 10,
              child: IgnorePointer(
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.state.lspHover!.contents,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleMouseMove(PointerHoverEvent event) {
    if (widget.onHover == null) return;

    _lastMousePosition = event.localPosition;
    final offset = _resolveHoverOffset(event.localPosition);
    if (offset == null) {
      _hoverTimer?.cancel();
      _pendingHoverOffset = null;
      return;
    }

    if (_pendingHoverOffset == offset) {
      return;
    }

    _pendingHoverOffset = offset;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || _pendingHoverOffset != offset) return;
      if (_lastDispatchedHoverOffset == offset) return;

      _lastDispatchedHoverOffset = offset;
      widget.onHover?.call(offset);
    });
  }

  int? _resolveHoverOffset(Offset localPosition) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      fontFamily: 'monospace',
      fontSize: widget.fontSize,
      height: 1.35,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: _textController.text, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    final correctedPos = Offset(
      localPosition.dx,
      localPosition.dy + _textScrollController.offset,
    );

    textPainter.layout(maxWidth: double.infinity);
    final textPosition = textPainter.getPositionForOffset(correctedPos);
    final offset = textPosition.offset;
    if (offset < 0 || offset >= _textController.text.length) {
      return null;
    }

    return offset;
  }

  Widget _buildContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final textSelectionToolbarItems = editableTextState.contextMenuButtonItems;

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: [
        ...textSelectionToolbarItems,
        if (widget.state.lspStatus != 'inactive') ...[
          ContextMenuButtonItem(
            onPressed: () {
              editableTextState.hideToolbar();
              widget.onGoToDefinition?.call();
            },
            label: 'Go to Definition',
          ),
          ContextMenuButtonItem(
            onPressed: () {
              editableTextState.hideToolbar();
              widget.onGoToDeclaration?.call();
            },
            label: 'Go to Declaration',
          ),
          ContextMenuButtonItem(
            onPressed: () {
              editableTextState.hideToolbar();
              widget.onGoToImplementation?.call();
            },
            label: 'Go to Implementation',
          ),
          ContextMenuButtonItem(
            onPressed: () {
              editableTextState.hideToolbar();
              widget.onFindReferences?.call();
            },
            label: 'Find References',
          ),
        ],
      ],
    );
  }
}

class _GooxSyntaxHighlighter {
  _GooxSyntaxHighlighter({
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

  // ── VS Code–inspired semantic colors ──────────────────────────────────

  /// Keywords: if, for, class, return — bold, blue/purple
  TextStyle get _keywordStyle => baseStyle.copyWith(
        color: _isDark
            ? const Color(0xFFC586C0) // VS Code dark: magenta-pink
            : const Color(0xFF0000FF), // VS Code light: blue
        fontWeight: FontWeight.w700,
      );

  /// Built-in types: int, String, bool, List — teal/cyan
  TextStyle get _typeStyle => baseStyle.copyWith(
        color: _isDark
            ? const Color(0xFF4EC9B0) // VS Code dark: teal
            : const Color(0xFF267F99), // VS Code light: dark teal
      );

  /// Constants: true, false, null — orange
  TextStyle get _constantStyle => baseStyle.copyWith(
        color: _isDark
            ? const Color(0xFF569CD6) // VS Code dark: blue
            : const Color(0xFF0000FF), // VS Code light: blue
        fontWeight: FontWeight.w700,
      );

  /// Built-in functions: print, len, println — yellow/gold
  TextStyle get _builtinFuncStyle => baseStyle.copyWith(
        color: _isDark
            ? const Color(0xFFDCDCAA) // VS Code dark: yellow
            : const Color(0xFF795E26), // VS Code light: dark gold
      );

  /// Comments — grey, italic
  TextStyle get _commentStyle => baseStyle.copyWith(
        color: _isDark
            ? const Color(0xFF6A9955) // VS Code dark: green
            : const Color(0xFF008000), // VS Code light: green
        fontStyle: FontStyle.italic,
      );

  /// Strings — orange-brown
  TextStyle get _stringStyle => baseStyle.copyWith(
        color: _isDark
            ? const Color(0xFFCE9178) // VS Code dark: light brown
            : const Color(0xFFA31515), // VS Code light: dark red
      );

  /// Numbers — light green
  TextStyle get _numberStyle => baseStyle.copyWith(
        color: _isDark
            ? const Color(0xFFB5CEA8) // VS Code dark: pale green
            : const Color(0xFF098658), // VS Code light: dark green
      );

  /// Annotations/decorators (@override, @deprecated)
  TextStyle get _annotationStyle => baseStyle.copyWith(
        color: _isDark
            ? const Color(0xFFDCDCAA) // VS Code dark: yellow
            : const Color(0xFF795E26), // VS Code light: dark gold
      );

  /// Operators and punctuation
  TextStyle get _punctuationStyle => baseStyle.copyWith(
        color: _isDark
            ? const Color(0xFFD4D4D4) // VS Code dark: light grey
            : const Color(0xFF000000), // VS Code light: black
      );

  bool get _isDark => theme.brightness == Brightness.dark;

  // ── Main highlight method ─────────────────────────────────────────────

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

      // ── Comments ──
      final commentMatch = _commentStart(text, index);
      if (commentMatch != null) {
        spans.add(TextSpan(text: commentMatch.text, style: _commentStyle));
        index = commentMatch.end;
        continue;
      }

      // ── Strings ──
      final stringMatch = _stringStart(text, index);
      if (stringMatch != null) {
        spans.add(TextSpan(text: stringMatch.text, style: _stringStyle));
        index = stringMatch.end;
        continue;
      }

      // ── Annotations (@override, @deprecated) ──
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

      // ── Numbers ──
      if (_isDigit(current)) {
        final numberEnd = _consumeNumber(text, index);
        spans.add(
          TextSpan(
            text: text.substring(index, numberEnd),
            style: _numberStyle,
          ),
        );
        index = numberEnd;
        continue;
      }

      // ── Identifiers & Keywords ──
      if (_isIdentifierStart(current)) {
        final identifierEnd = _consumeIdentifier(text, index);
        final identifier = text.substring(index, identifierEnd);
        spans.add(
          TextSpan(
            text: identifier,
            style: _styleForIdentifier(identifier),
          ),
        );
        index = identifierEnd;
        continue;
      }

      // ── Operators & punctuation ──
      if (_isOperator(current)) {
        spans.add(TextSpan(text: current, style: _punctuationStyle));
      } else {
        spans.add(TextSpan(text: current, style: baseStyle));
      }
      index++;
    }

    return spans;
  }

  // ── Token classification ──────────────────────────────────────────────

  TextStyle _styleForIdentifier(String identifier) {
    // Keywords: highest priority
    if (_definition.keywords.contains(identifier)) {
      return _keywordStyle;
    }

    // Built-in constants (true, false, null)
    if (_definition.builtinConstants.contains(identifier)) {
      return _constantStyle;
    }

    // Built-in types (int, String, bool)
    if (_definition.builtinTypes.contains(identifier)) {
      return _typeStyle;
    }

    // Built-in functions (print, len)
    if (_definition.builtinFunctions.contains(identifier)) {
      return _builtinFuncStyle;
    }

    // Heuristic: UpperCamelCase → likely a type/class name
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

  // ── Comment parsing ───────────────────────────────────────────────────

  _MatchSpan? _commentStart(String text, int index) {
    // Hash comments (#)
    if (_definition.hashComment && text[index] == '#') {
      final end = _lineEnd(text, index);
      return _MatchSpan(text.substring(index, end), end);
    }

    // Line comments (// etc.)
    final linePrefix = _definition.lineCommentPrefix;
    if (linePrefix != null && _startsWith(text, index, linePrefix)) {
      final end = _lineEnd(text, index);
      return _MatchSpan(text.substring(index, end), end);
    }

    // Block comments (/* */ or <!-- --> etc.)
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

  // ── String parsing ────────────────────────────────────────────────────

  _MatchSpan? _stringStart(String text, int index) {
    // Triple-quote delimiters (must check before single-char delimiters)
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

    // Template string delimiter (e.g. backtick for JS/TS/Go)
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

    // Standard string delimiters
    final current = text[index];
    if (!_definition.stringDelimiters.contains(current)) {
      return null;
    }

    final end = _findStringEnd(text, index + 1, current, allowMultiline: false);
    return _MatchSpan(text.substring(index, end), end);
  }

  // ── Utility methods ───────────────────────────────────────────────────

  int _consumeNumber(String text, int start) {
    var index = start;
    // Hex: 0x...
    if (index + 1 < text.length &&
        text[index] == '0' &&
        (text[index + 1] == 'x' || text[index + 1] == 'X')) {
      index += 2;
      while (index < text.length && _isHexDigit(text[index])) {
        index++;
      }
      return index;
    }
    // Decimal
    while (index < text.length && _isDigit(text[index])) {
      index++;
    }
    if (index < text.length && text[index] == '.') {
      index++;
      while (index < text.length && _isDigit(text[index])) {
        index++;
      }
    }
    // Exponent: e/E
    if (index < text.length &&
        (text[index] == 'e' || text[index] == 'E')) {
      index++;
      if (index < text.length &&
          (text[index] == '+' || text[index] == '-')) {
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
