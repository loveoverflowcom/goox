import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class GooxPluginCanvas extends StatelessWidget {
  const GooxPluginCanvas({
    super.key,
    required this.sessionId,
    required this.pageCount,
    required this.onRenderPage,
  });

  final int sessionId;
  final int pageCount;
  final Future<Uint8List> Function(int pageIndex, int width, int height)
  onRenderPage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final renderWidth = width.clamp(1.0, 4096.0).round();
        final renderHeight = (renderWidth * 1.41421356237).round().clamp(1, 8192);

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: pageCount,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _PluginCanvasPage(
            key: ValueKey('erp-page-$sessionId-$index-$renderWidth-$renderHeight'),
            pageIndex: index,
            width: renderWidth,
            height: renderHeight,
            onRenderPage: onRenderPage,
          ),
        );
      },
    );
  }
}

class _PluginCanvasPage extends StatefulWidget {
  const _PluginCanvasPage({
    super.key,
    required this.pageIndex,
    required this.width,
    required this.height,
    required this.onRenderPage,
  });

  final int pageIndex;
  final int width;
  final int height;
  final Future<Uint8List> Function(int pageIndex, int width, int height)
  onRenderPage;

  @override
  State<_PluginCanvasPage> createState() => _PluginCanvasPageState();
}

class _PluginCanvasPageState extends State<_PluginCanvasPage> {
  Future<ui.Image>? _imageFuture;
  ui.Image? _image;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureRendering();
  }

  @override
  void didUpdateWidget(covariant _PluginCanvasPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.pageIndex != widget.pageIndex) {
      _imageFuture = null;
      _image = null;
      _error = null;
      _ensureRendering();
    }
  }

  Future<void> _ensureRendering() async {
    if (_imageFuture != null || !mounted) {
      return;
    }

    final future = _loadImage();
    setState(() {
      _imageFuture = future;
    });
    try {
      final image = await future;
      if (!mounted) return;
      setState(() {
        _image = image;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    }
  }

  Future<ui.Image> _loadImage() async {
    final rgba = await widget.onRenderPage(
      widget.pageIndex,
      widget.width,
      widget.height,
    );
    return _decodeRgba(rgba, widget.width, widget.height);
  }

  Future<ui.Image> _decodeRgba(
    Uint8List rgba,
    int width,
    int height,
  ) {
    final completer = Completer<ui.Image>();

    try {
      ui.decodeImageFromPixels(
        rgba,
        width,
        height,
        ui.PixelFormat.rgba8888,
        (image) => completer.complete(image),
        rowBytes: width * 4,
      );
    } catch (e, st) {
      completer.completeError(e, st);
    }

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = Size(widget.width.toDouble(), widget.height.toDouble());

    Widget child;
    if (_error != null) {
      child = Container(
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to render page ${widget.pageIndex + 1}\n$_error',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    } else if (_image == null) {
      child = Container(
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      child = Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: RawImage(
                image: _image,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'Page ${widget.pageIndex + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Center(child: child);
  }
}
