import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'page_cache.dart';

/// Scale factor bounds (Requirements 5.1, 5.7)
const double _kMinScale = 0.25;
const double _kMaxScale = 8.0;

/// Re-render threshold: trigger re-render when scale changes > 20% (Requirement 5.3)
const double _kRerenderThreshold = 0.20;

/// Scroll-wheel zoom step per tick (Requirement 5.2)
const double _kScrollZoomStep = 0.10;

/// Default A4 aspect ratio (width / height)
const double _kDefaultAspectRatio = 1.0 / 1.41421356237;

/// Multi-page PDF viewer with zoom, lazy loading, and LRU page cache.
///
/// Architecture: ListView handles vertical scroll (Requirement 5.5).
/// Zoom is applied via [Transform.scale] on each page — this avoids the
/// "unbounded height" error that occurs when InteractiveViewer(constrained:false)
/// wraps a ListView.
///
/// Requirements: 5.1–5.7, 6.1–6.7, 8.1–8.4
class GooxPluginCanvas extends StatefulWidget {
  const GooxPluginCanvas({
    super.key,
    required this.sessionId,
    required this.pageCount,
    required this.onRenderPage,
    this.aspectRatio = _kDefaultAspectRatio,
    this.cacheSize = 5,
  });

  final int sessionId;
  final int pageCount;
  final double aspectRatio;
  final int cacheSize;
  final Future<Uint8List> Function(int pageIndex, int width, int height)
      onRenderPage;

  @override
  State<GooxPluginCanvas> createState() => _GooxPluginCanvasState();
}

class _GooxPluginCanvasState extends State<GooxPluginCanvas> {
  late final ScrollController _scrollController;
  late final PageCache _cache;

  double _scale = 1.0;
  double _lastRenderScale = 1.0;
  int _firstVisiblePage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _cache = PageCache(maxSize: widget.cacheSize);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _cache.clear(); // Requirement 6.4
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    // Estimate page height from viewport width and aspect ratio
    final viewportWidth = _scrollController.position.viewportDimension;
    final pageHeight = (viewportWidth * _scale) / widget.aspectRatio;
    if (pageHeight <= 0) return;
    final itemHeight = pageHeight + 16; // page + separator
    final firstVisible = (offset / itemHeight).floor().clamp(0, widget.pageCount - 1);
    if (firstVisible != _firstVisiblePage) {
      setState(() => _firstVisiblePage = firstVisible);
    }
  }

  double _clampScale(double s) => s.clamp(_kMinScale, _kMaxScale);

  void _zoom(double delta) {
    final factor = delta > 0 ? (1.0 + _kScrollZoomStep) : (1.0 - _kScrollZoomStep);
    setState(() => _scale = _clampScale(_scale * factor));
  }

  void _toggleZoom() {
    setState(() => _scale = (_scale - 1.0).abs() < 0.05 ? 2.0 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        // Render at base resolution; scale visually via Transform
        final baseWidth = viewportWidth.clamp(1.0, 4096.0).round();
        final baseHeight = (baseWidth / widget.aspectRatio).round().clamp(1, 8192);

        // Determine if a re-render at higher resolution is needed
        final scaleDelta = _lastRenderScale > 0
            ? (_scale - _lastRenderScale).abs() / _lastRenderScale
            : 1.0;
        final needsRerender = scaleDelta > _kRerenderThreshold;

        return Listener(
          // Ctrl/Cmd + scroll wheel zoom (Requirement 5.2)
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final isZoom = HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed;
              if (isZoom) {
                _zoom(-event.scrollDelta.dy);
              }
            }
          },
          child: GestureDetector(
            onDoubleTap: _toggleZoom, // Requirement 5.6
            // Pinch-to-zoom via ScaleGestureDetector (Requirement 5.1)
            onScaleUpdate: (details) {
              if (details.pointerCount >= 2) {
                setState(() => _scale = _clampScale(details.scale));
              }
            },
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: widget.pageCount,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final inViewport = index >= _firstVisiblePage - 1 &&
                    index <= _firstVisiblePage + 2;

                // Wrap each page in RepaintBoundary (Requirement 6.7)
                return RepaintBoundary(
                  child: inViewport
                      ? _PluginCanvasPage(
                          key: ValueKey(
                            'erp-${ widget.sessionId}-$index-$baseWidth-$baseHeight',
                          ),
                          pageIndex: index,
                          baseWidth: baseWidth,
                          baseHeight: baseHeight,
                          scale: _scale,
                          needsRerender: needsRerender,
                          cache: _cache,
                          onRenderPage: widget.onRenderPage,
                          onRendered: () {
                            _lastRenderScale = _scale;
                          },
                        )
                      : _PagePlaceholder(
                          baseWidth: baseWidth.toDouble(),
                          baseHeight: baseHeight.toDouble(),
                          scale: _scale,
                          pageIndex: index,
                        ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ── Page widget ───────────────────────────────────────────────────────────────

/// A single page with lazy loading, cache, buffer validation, and zoom via Transform.
///
/// Requirements: 5.3, 5.4, 6.1, 6.6, 8.1–8.4
class _PluginCanvasPage extends StatefulWidget {
  const _PluginCanvasPage({
    super.key,
    required this.pageIndex,
    required this.baseWidth,
    required this.baseHeight,
    required this.scale,
    required this.needsRerender,
    required this.cache,
    required this.onRenderPage,
    required this.onRendered,
  });

  final int pageIndex;
  final int baseWidth;
  final int baseHeight;
  final double scale;
  final bool needsRerender;
  final PageCache cache;
  final Future<Uint8List> Function(int pageIndex, int width, int height) onRenderPage;
  final VoidCallback onRendered;

  @override
  State<_PluginCanvasPage> createState() => _PluginCanvasPageState();
}

class _PluginCanvasPageState extends State<_PluginCanvasPage> {
  ui.Image? _image;
  ui.Image? _staleImage;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tryLoadFromCache();
  }

  @override
  void didUpdateWidget(covariant _PluginCanvasPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sizeChanged = oldWidget.baseWidth != widget.baseWidth ||
        oldWidget.baseHeight != widget.baseHeight;
    final rerenderNeeded = widget.needsRerender && !oldWidget.needsRerender;

    if (sizeChanged || rerenderNeeded) {
      _staleImage = _image;
      _image = null;
      _error = null;
      _tryLoadFromCache();
    }
  }

  void _tryLoadFromCache() {
    final cached = widget.cache.get(widget.pageIndex);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _image = cached;
          _staleImage = null;
        });
      }
      return;
    }
    _startRender();
  }

  Future<void> _startRender() async {
    if (_loading || !mounted) return;
    _loading = true;

    try {
      final rgba = await widget.onRenderPage(
        widget.pageIndex,
        widget.baseWidth,
        widget.baseHeight,
      );
      if (!mounted) return;

      // Validate buffer size (Requirements 8.2, 8.3)
      final expected = widget.baseWidth * widget.baseHeight * 4;
      if (rgba.length != expected) {
        debugPrint(
          '[GooxPluginCanvas] Buffer mismatch page ${widget.pageIndex}: '
          'expected $expected, got ${rgba.length}',
        );
        setState(() {
          _error = 'Buffer size mismatch (expected $expected, got ${rgba.length})';
          _loading = false;
        });
        return;
      }

      final image = await _decodeRgba(rgba, widget.baseWidth, widget.baseHeight);
      if (!mounted) return;

      widget.cache.put(widget.pageIndex, image);
      widget.cache.evictFarthestFrom(widget.pageIndex);

      setState(() {
        _image = image;
        _staleImage = null;
        _loading = false;
      });
      widget.onRendered();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<ui.Image> _decodeRgba(Uint8List rgba, int width, int height) {
    final completer = Completer<ui.Image>();
    try {
      // Requirement 8.4: use PixelFormat.rgba8888
      ui.decodeImageFromPixels(
        rgba,
        width,
        height,
        ui.PixelFormat.rgba8888,
        (img) => completer.complete(img),
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

    // Visual size after zoom (Requirement 5.1)
    final displayWidth = widget.baseWidth * widget.scale;
    final displayHeight = widget.baseHeight * widget.scale;

    Widget content;

    if (_error != null) {
      content = _errorWidget(theme, colorScheme);
    } else if (_image != null) {
      content = _imageWidget(colorScheme);
    } else if (_staleImage != null) {
      content = _staleWidget(colorScheme); // Requirement 5.4
    } else {
      content = _loadingWidget(colorScheme); // Requirement 6.6
    }

    return Center(
      child: SizedBox(
        width: displayWidth,
        height: displayHeight,
        child: content,
      ),
    );
  }

  Widget _imageWidget(ColorScheme colorScheme) {
    return _PageFrame(
      colorScheme: colorScheme,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  'Page ${widget.pageIndex + 1}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

  Widget _staleWidget(ColorScheme colorScheme) {
    return _PageFrame(
      colorScheme: colorScheme,
      child: Stack(
        children: [
          Positioned.fill(
            child: RawImage(
              image: _staleImage,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const Positioned(
            right: 12,
            bottom: 12,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingWidget(ColorScheme colorScheme) {
    return _PageFrame(
      colorScheme: colorScheme,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _errorWidget(ThemeData theme, ColorScheme colorScheme) {
    return _PageFrame(
      colorScheme: colorScheme,
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
  }
}

// ── Placeholder ───────────────────────────────────────────────────────────────

class _PagePlaceholder extends StatelessWidget {
  const _PagePlaceholder({
    required this.baseWidth,
    required this.baseHeight,
    required this.scale,
    required this.pageIndex,
  });

  final double baseWidth;
  final double baseHeight;
  final double scale;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: baseWidth * scale,
        height: baseHeight * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          'Page ${pageIndex + 1}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

// ── Frame decoration ──────────────────────────────────────────────────────────

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.colorScheme, required this.child});

  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}
