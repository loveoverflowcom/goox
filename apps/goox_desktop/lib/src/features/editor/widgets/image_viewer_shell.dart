// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:atomic_webview/atomic_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GooxRenderWebViewShell extends StatefulWidget {
  const GooxRenderWebViewShell({
    super.key,
    required this.sessionId,
    required this.pageCount,
    required this.metadataJson,
    required this.onRenderPage,
    required this.documentName,
    this.webEntryPath,
  });

  final int sessionId;
  final int pageCount;
  final String? metadataJson;
  final Future<Uint8List> Function(int pageIndex, int width, int height)
  onRenderPage;
  final String documentName;
  final String? webEntryPath;

  @override
  State<GooxRenderWebViewShell> createState() => _GooxRenderWebViewShellState();
}

class _GooxRenderWebViewShellState extends State<GooxRenderWebViewShell> {
  final WebViewController _controller = WebViewController();

  int _currentPage = 0;
  double _zoom = 1.0;
  String? _status = 'Preparing WebView viewer...';
  String? _error;
  bool _initializing = true;
  int _renderEpoch = 0;
  double _currentAspectRatio = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  @override
  void didUpdateWidget(covariant GooxRenderWebViewShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId ||
        oldWidget.pageCount != widget.pageCount ||
        oldWidget.metadataJson != widget.metadataJson ||
        oldWidget.documentName != widget.documentName ||
        oldWidget.webEntryPath != widget.webEntryPath) {
      _currentPage = 0;
      _zoom = 1.0;
      _error = null;
      _status = 'Preparing WebView viewer...';
      _renderEpoch++;
      unawaited(_renderCurrentPage());
    }
  }

  @override
  void dispose() {
    if (_controller.is_init && _controller.is_desktop) {
      _controller.webview_desktop_controller.close();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted || _controller.is_init) {
      return;
    }

    try {
      Uri uri;
      final webEntryPath = widget.webEntryPath;
      if (webEntryPath != null && File(webEntryPath).existsSync()) {
        uri = Uri.file(webEntryPath);
      } else {
        final html = await rootBundle.loadString(
          'assets/webview/renderer.html',
        );
        uri = Uri.dataFromString(html, mimeType: 'text/html', encoding: utf8);
      }

      await _controller.init(context: context, setState: setState, uri: uri);

      if (!mounted) {
        return;
      }

      setState(() {
        _initializing = false;
        _status = 'WebView viewer ready';
      });

      await Future<void>.delayed(const Duration(milliseconds: 150));
      await _renderCurrentPage();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _error = 'Failed to open WebView viewer: $error';
        _status = 'WebView viewer failed';
      });
    }
  }

  Map<String, dynamic> _metadata() {
    final metadataJson = widget.metadataJson;
    if (metadataJson == null || metadataJson.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(metadataJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore malformed metadata and fall back to defaults.
    }
    return const {};
  }

  Map<String, dynamic> _metadataPayload() {
    final metadata = _metadata();
    final payload = metadata['payload'];
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    return const {};
  }

  double get _aspectRatio {
    final payload = _metadataPayload();
    final width = _asDouble(payload['width']);
    final height = _asDouble(payload['height']);
    if (width != null && height != null && height > 0) {
      return width / height;
    }

    if (payload.containsKey('page_count')) {
      // PDF fallback: keep a print-like aspect ratio.
      return 1 / 1.41421356237;
    }

    return 1.0;
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  Future<void> _renderCurrentPage() async {
    if (!mounted || !_controller.is_init) {
      return;
    }

    final renderEpoch = ++_renderEpoch;
    final width = (1200 * _zoom).clamp(320, 4096).round();
    final height = (width / _aspectRatio).clamp(240, 4096).round();

    setState(() {
      _status = 'Rendering page ${_currentPage + 1}...';
      _error = null;
    });

    try {
      final pixels = await widget.onRenderPage(_currentPage, width, height);
      if (!mounted || renderEpoch != _renderEpoch) {
        return;
      }

      final payload = jsonEncode({
        'page': _currentPage,
        'width': width,
        'height': height,
        'pixelsBase64': base64Encode(pixels),
        'documentName': widget.documentName,
      });

      await _evaluateJs(
        'window.gooxViewer && window.gooxViewer.renderFrame($payload);',
      );

      if (!mounted || renderEpoch != _renderEpoch) {
        return;
      }

      setState(() {
        _currentAspectRatio = _aspectRatio;
        _status = 'Rendered page ${_currentPage + 1}';
      });
    } catch (error) {
      if (!mounted || renderEpoch != _renderEpoch) {
        return;
      }

      setState(() {
        _error = error.toString();
        _status = 'Render failed';
      });
    }
  }

  Future<void> _evaluateJs(String script) async {
    try {
      await _controller.evaluateJavaScript(script);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'WebView script error: $error';
        _status = 'WebView script failed';
      });
    }
  }

  void _nextPage() {
    if (widget.pageCount <= 1) {
      return;
    }
    setState(() {
      _currentPage = (_currentPage + 1).clamp(0, widget.pageCount - 1);
    });
    unawaited(_renderCurrentPage());
  }

  void _previousPage() {
    if (widget.pageCount <= 1) {
      return;
    }
    setState(() {
      _currentPage = (_currentPage - 1).clamp(0, widget.pageCount - 1);
    });
    unawaited(_renderCurrentPage());
  }

  void _setZoom(double zoom) {
    setState(() {
      _zoom = zoom.clamp(0.25, 4.0);
    });
    unawaited(_renderCurrentPage());
  }

  void _resetViewer() {
    setState(() {
      _currentPage = 0;
      _zoom = 1.0;
    });
    unawaited(_renderCurrentPage());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metadata = _metadataPayload();
    final pageCount = widget.pageCount < 1 ? 1 : widget.pageCount;

    final rows = <Widget>[
      _ViewerHeader(
        documentName: widget.documentName,
        status: _status ?? 'Idle',
        isBusy: _initializing,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _currentPage > 0 ? _previousPage : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Prev'),
          ),
          FilledButton.icon(
            onPressed: _currentPage < pageCount - 1 ? _nextPage : null,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Next'),
          ),
          OutlinedButton.icon(
            onPressed: () => _setZoom((_zoom - 0.25).clamp(0.25, 4.0)),
            icon: const Icon(Icons.zoom_out_rounded),
            label: const Text('Zoom Out'),
          ),
          OutlinedButton.icon(
            onPressed: () => _setZoom((_zoom + 0.25).clamp(0.25, 4.0)),
            icon: const Icon(Icons.zoom_in_rounded),
            label: const Text('Zoom In'),
          ),
          TextButton.icon(
            onPressed: _resetViewer,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WebView rendering path',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The document is rendered by the native engine, then painted inside the existing WebView surface. '
                'WASM only supplies logic and render intent.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Page',
                value: '${_currentPage + 1} / $pageCount',
              ),
              _InfoRow(label: 'Zoom', value: '${(_zoom * 100).round()}%'),
              _InfoRow(
                label: 'Aspect',
                value: _currentAspectRatio.toStringAsFixed(3),
              ),
              if (metadata.isNotEmpty) ...[
                const SizedBox(height: 12),
                _MetadataBlock(metadata: metadata),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}

class _ViewerHeader extends StatelessWidget {
  const _ViewerHeader({
    required this.documentName,
    required this.status,
    required this.isBusy,
  });

  final String documentName;
  final String status;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.web_asset_rounded, color: colorScheme.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                documentName.isEmpty ? 'WebView Viewer' : documentName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (isBusy)
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _MetadataBlock extends StatelessWidget {
  const _MetadataBlock({required this.metadata});

  final Map<String, dynamic> metadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = metadata.entries.toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metadata',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
