import 'package:flutter/material.dart';

import 'goox_code_syntax_highlighter.dart';

class MarkdownRenderer extends StatelessWidget {
  const MarkdownRenderer({
    super.key,
    required this.markdown,
    required this.theme,
    required this.baseStyle,
  });

  final String markdown;
  final ThemeData theme;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(markdown);
    final bodyStyle = baseStyle.copyWith(
      color: theme.colorScheme.onSurface,
      height: 1.35,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks) ...[
          if (block case _ParagraphBlock(:final text))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  style: bodyStyle,
                  children: _parseInline(text, bodyStyle, theme),
                ),
              ),
            )
          else if (block case _CodeBlock(:final language, :final code))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.75,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: RichText(
                    text: TextSpan(
                      children: _highlightCode(
                        language: language,
                        code: code,
                        theme: theme,
                        baseStyle: bodyStyle.copyWith(
                          fontFamily: 'monospace',
                          fontFamilyFallback: const ['monospace'],
                          fontSize: bodyStyle.fontSize ?? 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  List<InlineSpan> _highlightCode({
    required String? language,
    required String code,
    required ThemeData theme,
    required TextStyle baseStyle,
  }) {
    final highlighter = GooxCodeSyntaxHighlighter(
      languageId: language,
      theme: theme,
      baseStyle: baseStyle,
    );
    return highlighter.highlight(code);
  }

  List<_MarkdownBlock> _parseBlocks(String source) {
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_MarkdownBlock>[];
    final buffer = StringBuffer();
    String? fenceLanguage;
    var inCodeBlock = false;

    void flushParagraph() {
      final text = buffer.toString().trim();
      if (text.isNotEmpty) {
        blocks.add(_ParagraphBlock(text));
      }
      buffer.clear();
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          blocks.add(
            _CodeBlock(language: fenceLanguage, code: buffer.toString()),
          );
          buffer.clear();
          fenceLanguage = null;
          inCodeBlock = false;
        } else {
          flushParagraph();
          inCodeBlock = true;
          final language = trimmed
              .substring(3)
              .trim()
              .split(RegExp(r'\s+'))
              .firstOrNull
              ?.trim();
          fenceLanguage = (language == null || language.isEmpty)
              ? null
              : language;
        }
        continue;
      }

      if (inCodeBlock) {
        buffer.writeln(line);
        continue;
      }

      if (trimmed.isEmpty) {
        flushParagraph();
        continue;
      }

      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.write(line);
    }

    if (inCodeBlock) {
      blocks.add(_CodeBlock(language: fenceLanguage, code: buffer.toString()));
    } else {
      flushParagraph();
    }

    return blocks;
  }

  List<InlineSpan> _parseInline(
    String text,
    TextStyle baseStyle,
    ThemeData theme,
  ) {
    final spans = <InlineSpan>[];
    var index = 0;

    while (index < text.length) {
      final remainder = text.substring(index);

      if (remainder.startsWith('**') || remainder.startsWith('__')) {
        final marker = remainder.substring(0, 2);
        final close = text.indexOf(marker, index + 2);
        if (close != -1) {
          spans.addAll(
            _parseInline(
              text.substring(index + 2, close),
              baseStyle.copyWith(fontWeight: FontWeight.w700),
              theme,
            ),
          );
          index = close + 2;
          continue;
        }
      }

      if (remainder.startsWith('*') || remainder.startsWith('_')) {
        final marker = remainder[0];
        final close = text.indexOf(marker, index + 1);
        if (close != -1) {
          spans.addAll(
            _parseInline(
              text.substring(index + 1, close),
              baseStyle.copyWith(fontStyle: FontStyle.italic),
              theme,
            ),
          );
          index = close + 1;
          continue;
        }
      }

      if (remainder.startsWith('`')) {
        final close = text.indexOf('`', index + 1);
        if (close != -1) {
          spans.add(
            TextSpan(
              text: text.substring(index + 1, close),
              style: baseStyle.copyWith(
                fontFamily: 'monospace',
                fontFamilyFallback: const ['monospace'],
                backgroundColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.55),
              ),
            ),
          );
          index = close + 1;
          continue;
        }
      }

      if (remainder.startsWith('[')) {
        final closeLabel = text.indexOf(']', index + 1);
        final openUrl = closeLabel == -1 ? -1 : text.indexOf('(', closeLabel);
        final closeUrl = openUrl == -1 ? -1 : text.indexOf(')', openUrl);
        if (closeLabel != -1 && openUrl == closeLabel + 1 && closeUrl != -1) {
          final label = text.substring(index + 1, closeLabel);
          spans.add(
            TextSpan(
              text: label,
              style: baseStyle.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          );
          index = closeUrl + 1;
          continue;
        }
      }

      final nextSpecial = _nextSpecialIndex(text, index + 1);
      spans.add(
        TextSpan(text: text.substring(index, nextSpecial), style: baseStyle),
      );
      index = nextSpecial;
    }

    return spans;
  }

  int _nextSpecialIndex(String text, int start) {
    final candidates = <int>[
      text.indexOf('**', start),
      text.indexOf('__', start),
      text.indexOf('*', start),
      text.indexOf('_', start),
      text.indexOf('`', start),
      text.indexOf('[', start),
    ].where((index) => index != -1).toList();

    if (candidates.isEmpty) {
      return text.length;
    }

    candidates.sort();
    return candidates.first;
  }
}

abstract class _MarkdownBlock {
  const _MarkdownBlock();
}

class _ParagraphBlock extends _MarkdownBlock {
  const _ParagraphBlock(this.text);

  final String text;
}

class _CodeBlock extends _MarkdownBlock {
  const _CodeBlock({required this.language, required this.code});

  final String? language;
  final String code;
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
