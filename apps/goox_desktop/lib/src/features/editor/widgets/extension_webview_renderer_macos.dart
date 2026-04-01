import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:webview_all/webview_all.dart';

import 'extension_webview_renderer.dart';

class GooxMacosExtensionWebViewRenderer extends GooxExtensionWebViewRenderer {
  const GooxMacosExtensionWebViewRenderer({
    super.key,
    required super.extensionName,
    required super.filePath,
    required super.fileType,
    required super.webEntryPath,
    super.onBridgeMessage,
  });

  @override
  State<GooxMacosExtensionWebViewRenderer> createState() =>
      _GooxMacosExtensionWebViewRendererState();
}

class _GooxMacosExtensionWebViewRendererState
    extends State<GooxMacosExtensionWebViewRenderer> {
  late final WebViewController _controller;
  bool _ready = false;
  bool _injecting = false;
  String _status = 'Loading renderer...';
  String? _error;
  int _inputSequence = 0;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            unawaited(_injectInput());
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _ready = false;
              _injecting = false;
              _error =
                  'WebView resource error: ${error.description} (${error.errorType})';
              _status = 'Renderer failed';
            });
          },
        ),
      )
      ..addJavaScriptChannel('host', onMessageReceived: _handleHostMessage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadEntry());
    });
  }

  @override
  void didUpdateWidget(covariant GooxMacosExtensionWebViewRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extensionName != widget.extensionName ||
        oldWidget.filePath != widget.filePath ||
        oldWidget.fileType != widget.fileType ||
        oldWidget.webEntryPath != widget.webEntryPath) {
      unawaited(_loadEntry());
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    unawaited(_loadEntry());
  }

  Future<void> _loadEntry() async {
    if (!mounted) return;

    final entryPath = _resolveEntryPath();
    setState(() {
      _ready = false;
      _error = null;
      _status = 'Opening ${widget.extensionName}...';
    });

    if (entryPath == null) {
      await _controller.loadHtmlString(
        _buildErrorPage(
          'Missing web entry',
          'The renderer entry for ${widget.extensionName} could not be found.',
        ),
      );
      if (!mounted) return;
      setState(() {
        _status = 'Renderer missing';
      });
      return;
    }

    final loadToken = ++_loadToken;
    try {
      await _controller.loadFile(entryPath);
      if (!mounted || loadToken != _loadToken) {
        return;
      }
      setState(() {
        _ready = true;
        _status = 'Renderer loaded';
      });
    } catch (error) {
      if (!mounted || loadToken != _loadToken) {
        return;
      }
      await _controller.loadHtmlString(
        _buildErrorPage(
          'Renderer failed',
          'Failed to open ${widget.extensionName}: $error',
        ),
      );
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _status = 'Renderer failed';
      });
    }
  }

  String? _resolveEntryPath() {
    final entryPath = widget.webEntryPath;
    if (entryPath == null || entryPath.isEmpty) {
      return null;
    }

    final file = File(entryPath);
    if (!file.existsSync()) {
      return null;
    }

    return file.absolute.path;
  }

  Future<void> _injectInput() async {
    if (!mounted || _injecting) return;
    _injecting = true;

    try {
      final input = await _buildExtensionInput();
      final serialized = jsonEncode(input);
      final script =
          '''
window.__EXTENSION_INPUT__ = $serialized;
window.dispatchEvent(new CustomEvent('goox-extension-input', {
  detail: window.__EXTENSION_INPUT__
}));
''';

      for (var attempt = 0; attempt < 6; attempt += 1) {
        try {
          await _controller.runJavaScript(script);
          if (!mounted) return;
          setState(() {
            _inputSequence += 1;
            _status = 'Ready';
          });
          return;
        } catch (_) {
          if (attempt == 5) {
            rethrow;
          }
          await Future<void>.delayed(const Duration(milliseconds: 120));
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _status = 'Input injection failed';
      });
    } finally {
      _injecting = false;
    }
  }

  Future<Map<String, dynamic>> _buildExtensionInput() async {
    final file = File(widget.filePath);
    Uint8List? bytes;
    if (file.existsSync()) {
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        bytes = null;
      }
    }

    return <String, dynamic>{
      'filePath': widget.filePath,
      'fileUri': Uri.file(widget.filePath).toString(),
      'fileType': widget.fileType,
      'fileName': p.basename(widget.filePath),
      'extensionName': widget.extensionName,
      'fileContentBase64': bytes == null ? null : base64Encode(bytes),
      'inputSequence': _inputSequence + 1,
      'hasFileContent': bytes != null,
    };
  }

  String _buildErrorPage(String title, String message) {
    return '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      background: #08101a;
      color: #eef4ff;
      font-family: system-ui, sans-serif;
    }
    .card {
      max-width: 620px;
      padding: 28px;
      border-radius: 20px;
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid rgba(255, 255, 255, 0.12);
    }
    h1 { margin: 0 0 12px; font-size: 24px; }
    p { margin: 0; line-height: 1.55; color: #c6d6e6; }
  </style>
</head>
<body>
  <div class="card">
    <h1>${_escapeHtml(title)}</h1>
    <p>${_escapeHtml(message)}</p>
  </div>
</body>
</html>
''';
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  void _handleHostMessage(JavaScriptMessage message) {
    final trimmed = message.message.trim();
    if (trimmed.isEmpty) return;

    widget.onBridgeMessage?.call(trimmed);
    if (!mounted) return;

    setState(() {
      _status = _bridgeStatus(trimmed);
    });
  }

  String _bridgeStatus(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        final type = decoded['type']?.toString();
        if (type != null && type.isNotEmpty) {
          return 'Bridge: $type';
        }
      }
    } catch (_) {
      // Keep raw fallback.
    }
    return message.length > 42 ? '${message.substring(0, 42)}…' : message;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          Positioned(
            left: 8,
            top: 8,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: _ready ? 0.0 : 0.96,
                child: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final colorScheme = theme.colorScheme;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _error == null
                                    ? colorScheme.primary
                                    : colorScheme.error,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.extensionName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _status,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
