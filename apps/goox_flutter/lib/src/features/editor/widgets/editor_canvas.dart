import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/editor_models.dart';

class EditorCanvas extends StatefulWidget {
  const EditorCanvas({
    super.key,
    required this.state,
    required this.focusNode,
    required this.onTap,
  });

  final EditorViewState state;
  final FocusNode focusNode;
  final VoidCallback onTap;

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  final _ParagraphCache _cache = _ParagraphCache();

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant EditorCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) {
      return;
    }

    oldWidget.focusNode.removeListener(_handleFocusChanged);
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;

    return GestureDetector(
      onTap: widget.onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBF7EE), Color(0xFFF1EBDF)],
          ),
          border: Border.all(
            color: isFocused
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isFocused ? 2 : 1,
          ),
        ),
        child: CustomPaint(
          painter: _EditorCanvasPainter(
            state: widget.state,
            colorScheme: Theme.of(context).colorScheme,
            textTheme: Theme.of(context).textTheme,
            paragraphCache: _cache,
            isFocused: isFocused,
          ),
          child: const SizedBox.expand(),
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
  });

  final EditorViewState state;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final _ParagraphCache paragraphCache;
  final bool isFocused;

  @override
  void paint(Canvas canvas, Size size) {
    final gutterWidth = 70.0;
    final lineHeight = 28.0;
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
      final bodyStyle = textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontFamily: 'monospace',
        height: 1.25,
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
    }

    final footerRect = Rect.fromLTWH(0, size.height - 52, size.width, 52);
    final footerPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.75);
    canvas.drawRect(footerRect, footerPaint);

    final footerParagraph = paragraphCache.resolve(
      cacheKey: 'footer:${state.revision}:${size.width}:${state.lastCommand}',
      text:
          'viewport ${state.firstVisibleLine + 1}-${state.firstVisibleLine + state.visibleLines.length}  |  '
          'cursor ${state.cursor.line}:${state.cursor.column}  |  revision ${state.revision}',
      width: size.width - 24,
      style:
          textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ) ??
          const TextStyle(),
    );
    canvas.drawParagraph(footerParagraph, Offset(12, size.height - 38));
  }

  @override
  bool shouldRepaint(covariant _EditorCanvasPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.isFocused != isFocused;
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
