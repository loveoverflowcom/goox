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

class GooxEditorCanvas extends StatefulWidget {
  const GooxEditorCanvas({
    super.key,
    required this.state,
    required this.focusNode,
    required this.onTap,
    this.onTapDown,
    this.onTextChanged,
    this.onCursorOffsetChanged,
    this.autofocus = false,
  });

  final EditorViewState state;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final void Function(TapDownDetails, BuildContext)? onTapDown;
  final Future<void> Function(GooxEditorTextChange change)? onTextChanged;
  final ValueChanged<int>? onCursorOffsetChanged;
  final bool autofocus;

  @override
  State<GooxEditorCanvas> createState() => _GooxEditorCanvasState();
}

class _GooxEditorCanvasState extends State<GooxEditorCanvas> {
  late final TextEditingController _textController;
  bool _isApplyingExternalValue = false;
  TextEditingValue _lastEditingValue = const TextEditingValue();

  final ScrollController _textScrollController = ScrollController();
  final ScrollController _lineScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.state.documentText);
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

    final textChanged = _textController.text != widget.state.documentText;
    final selectionOutOfBounds =
        _textController.selection.start > _textController.text.length ||
        _textController.selection.end > _textController.text.length;

    if (textChanged || selectionOutOfBounds || !widget.focusNode.hasFocus) {
      final nextValue = _editingValueFromState(widget.state);
      if (_textController.value == nextValue) {
        return;
      }
      _applyExternalValue(nextValue);
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
      if (mounted) {
        setState(() {}); // Trigger rebuild to update line numbers if lines changed
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
    
    // Calculate lines dynamically based on actual text, 1 minimum
    final lineCount = '\n'.allMatches(_textController.text).length + 1;
    final lineHeight = 16 * 1.35; // fontSize * height

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
            // Line numbers gutter
            Container(
              width: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
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
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontFamily: 'monospace',
                        fontSize: 12, // Slightly smaller than editor text
                        height: 1.35 * (16 / 12), // Keep exactly same total line height: 12 * (1.35 * 16/12) = 21.6
                      ),
                    ),
                  );
                },
              ),
            ),
            // Editor text field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
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
                    fontSize: 16,
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
