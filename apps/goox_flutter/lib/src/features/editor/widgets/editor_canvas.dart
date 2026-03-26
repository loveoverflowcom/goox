import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/editor_models.dart';

class EditorCanvas extends StatefulWidget {
  const EditorCanvas({
    super.key,
    required this.state,
    required this.focusNode,
    required this.onTap,
    this.onTapDown,
  });

  final EditorViewState state;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final void Function(TapDownDetails, BuildContext)? onTapDown;

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> with SingleTickerProviderStateMixin {
  final _ParagraphCache _cache = _ParagraphCache();
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _cursorController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _cursorController.forward();
        }
      });
    
    if (widget.focusNode.hasFocus) {
      _cursorController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant EditorCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) {
      if (widget.focusNode.hasFocus && !_cursorController.isAnimating) {
        _cursorController.forward();
      }
      return;
    }

    oldWidget.focusNode.removeListener(_handleFocusChanged);
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    _cursorController.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (widget.focusNode.hasFocus) {
      _cursorController.forward();
    } else {
      _cursorController.stop();
      _cursorController.value = 0;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (details) {
        if (widget.onTapDown != null) {
          widget.onTapDown!(details, context);
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isFocused
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: AnimatedBuilder(
          animation: _cursorController,
          builder: (context, child) {
            return CustomPaint(
              painter: _EditorCanvasPainter(
                state: widget.state,
                colorScheme: Theme.of(context).colorScheme,
                textTheme: Theme.of(context).textTheme,
                paragraphCache: _cache,
                isFocused: isFocused,
                cursorOpacity: _cursorController.value,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _EditorCanvasPainter extends CustomPainter {
  const _EditorCanvasPainter({
    required this.state,
    required this.colorScheme,
    required this.textTheme,
    required this.paragraphCache,
    required this.isFocused,
    required this.cursorOpacity,
  });

  final EditorViewState state;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final _ParagraphCache paragraphCache;
  final bool isFocused;
  final double cursorOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final gutterWidth = 70.0;
    final lineHeight = 32.0;
    final topPadding = 20.0;
    final textWidth = size.width - gutterWidth - 32;
    final currentLine = state.cursor.line;

    final dividerPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(gutterWidth, 0),
      Offset(gutterWidth, size.height),
      dividerPaint,
    );

    final focusPaint = Paint()
      ..color = colorScheme.primaryContainer.withValues(
        alpha: isFocused ? 0.35 : 0.18,
      );
    final currentLineTop =
        topPadding + ((currentLine - state.firstVisibleLine - 1) * lineHeight);
    if (currentLineTop >= 0 && currentLineTop <= size.height - lineHeight) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(8, currentLineTop - 2, size.width - 16, lineHeight + 4),
          const Radius.circular(12),
        ),
        focusPaint,
      );
    }

    final bodyStyle = textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurface,
      fontFamily: 'monospace',
      height: 1.25,
      fontSize: 16.0,
    );

    // Measure character width for monospace cursor positioning
    final charWidthParagraph = paragraphCache.resolve(
      cacheKey: 'charWidth:${size.width}',
      text: 'A',
      width: textWidth,
      style: bodyStyle ?? const TextStyle(),
    );
    final charWidth = charWidthParagraph.maxIntrinsicWidth;

    for (var index = 0; index < state.visibleLines.length; index++) {
      final line = state.visibleLines[index];
      final y = topPadding + (index * lineHeight);
      final numberStyle = textTheme.labelMedium?.copyWith(
        color: line.lineNumber == currentLine
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
        fontWeight: line.lineNumber == currentLine
            ? FontWeight.w700
            : FontWeight.w500,
      );

      final lineNumberParagraph = paragraphCache.resolve(
        cacheKey: 'num:${line.lineNumber}:${size.width}',
        text: '${line.lineNumber}'.padLeft(2, '0'),
        width: gutterWidth - 16,
        style: numberStyle ?? const TextStyle(),
        alignment: TextAlign.right,
      );
      canvas.drawParagraph(lineNumberParagraph, Offset(8, y));

      final textParagraph = paragraphCache.resolve(
        cacheKey:
            'text:${state.revision}:${line.lineNumber}:${size.width}:${line.text}',
        text: line.text.isEmpty ? ' ' : line.text,
        width: textWidth,
        style: bodyStyle ?? const TextStyle(),
      );
      canvas.drawParagraph(textParagraph, Offset(gutterWidth + 16, y));

      // Draw cursor if this is the current line and app is focused
      if (line.lineNumber == currentLine && isFocused) {
        final cursorX = gutterWidth + 16 + (state.cursor.column - 1) * charWidth;
        final cursorPaint = Paint()
          ..color = colorScheme.primary.withValues(alpha: cursorOpacity)
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset(cursorX, y + 4),
          Offset(cursorX, y + lineHeight - 4),
          cursorPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EditorCanvasPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isFocused != isFocused ||
        oldDelegate.cursorOpacity != cursorOpacity;
  }
}

class _ParagraphCache {
  final Map<String, ui.Paragraph> _paragraphs = {};

  ui.Paragraph resolve({
    required String cacheKey,
    required String text,
    required double width,
    required TextStyle style,
    TextAlign alignment = TextAlign.left,
  }) {
    final cached = _paragraphs[cacheKey];
    if (cached != null) {
      return cached;
    }

    final builder =
        ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: alignment,
            maxLines: 1,
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
            height: style.height,
          ),
        )..pushStyle(
          ui.TextStyle(
            color: style.color,
            fontFamily: style.fontFamily,
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
            height: style.height,
          ),
        );

    builder.addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: width));
    _paragraphs[cacheKey] = paragraph;
    return paragraph;
  }
}
