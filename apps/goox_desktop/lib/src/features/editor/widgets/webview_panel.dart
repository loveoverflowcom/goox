import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';

/// A widget that displays extension webviews with sandboxed communication.
///
/// This widget provides a simplified interface for displaying extension webviews
/// with message passing capabilities between Flutter and the webview JavaScript.
class WebviewPanel extends StatefulWidget {
  /// The unique identifier of the extension
  final String extensionId;

  /// The path to the HTML file to load
  final String htmlPath;

  /// The file content to pass to the webview
  final String fileContent;

  /// Optional callback for handling messages from the webview
  final ValueChanged<Map<String, dynamic>>? onMessage;

  const WebviewPanel({
    required this.extensionId,
    required this.htmlPath,
    required this.fileContent,
    this.onMessage,
    super.key,
  });

  @override
  State<WebviewPanel> createState() => _WebviewPanelState();
}

class _WebviewPanelState extends State<WebviewPanel> {
  late final WebViewController _controller;
  bool _isReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebview();
  }

  @override
  void didUpdateWidget(covariant WebviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reload if the HTML path or extension ID changes
    if (oldWidget.htmlPath != widget.htmlPath ||
        oldWidget.extensionId != widget.extensionId) {
      _initializeWebview();
    }
    
    // Update content if it changes
    if (oldWidget.fileContent != widget.fileContent) {
      updateContent(widget.fileContent);
    }
  }

  /// Initialize the webview with extension assets
  void _initializeWebview() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // Inject initial file content when page loads
            _sendMessage({
              'type': 'fileContent',
              'content': widget.fileContent,
              'extensionId': widget.extensionId,
            });
            
            if (mounted) {
              setState(() {
                _isReady = true;
                _error = null;
              });
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isReady = false;
                _error = 'WebView error: ${error.description}';
              });
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'gooxAPI',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMessage(message.message);
        },
      );

    // Load the HTML file
    _loadHtmlFile();
  }

  /// Load the HTML file from the extension directory
  Future<void> _loadHtmlFile() async {
    try {
      await _controller.loadFile(widget.htmlPath);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load webview: $error';
          _isReady = false;
        });
      }
    }
  }

  /// Send a message to the webview
  void _sendMessage(Map<String, dynamic> message) {
    if (!_isReady) return;

    final jsonMessage = jsonEncode(message);
    final script = '''
      window.dispatchEvent(new CustomEvent('goox-message', {
        detail: $jsonMessage
      }));
    ''';

    _controller.runJavaScript(script).catchError((error) {
      debugPrint('Failed to send message to webview: $error');
    });
  }

  /// Handle messages received from the webview
  void _handleMessage(String rawMessage) {
    try {
      final message = jsonDecode(rawMessage) as Map<String, dynamic>;
      
      // Handle internal message types
      final type = message['type'] as String?;
      if (type == 'ready') {
        // Webview is ready, send initial content
        _sendMessage({
          'type': 'fileContent',
          'content': widget.fileContent,
          'extensionId': widget.extensionId,
        });
      } else if (type == 'requestContent') {
        // Webview is requesting file content
        _sendMessage({
          'type': 'fileContent',
          'content': widget.fileContent,
          'extensionId': widget.extensionId,
        });
      }
      
      // Forward message to parent widget
      widget.onMessage?.call(message);
    } catch (error) {
      debugPrint('Failed to parse message from webview: $error');
    }
  }

  /// Update the file content in the webview
  void updateContent(String newContent) {
    _sendMessage({
      'type': 'fileUpdate',
      'content': newContent,
      'extensionId': widget.extensionId,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Webview Error',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (!_isReady)
          Container(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading ${widget.extensionId}...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Message types for webview communication
class WebviewMessage {
  final String type;
  final Map<String, dynamic> data;

  WebviewMessage({
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        ...data,
      };

  factory WebviewMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final data = Map<String, dynamic>.from(json)..remove('type');
    return WebviewMessage(type: type, data: data);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebviewMessage &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          _mapsEqual(data, other.data);

  @override
  int get hashCode {
    // Create a consistent hash by combining type hash with sorted data keys
    int hash = type.hashCode;
    final sortedKeys = data.keys.toList()..sort();
    for (final key in sortedKeys) {
      hash = hash ^ key.hashCode ^ data[key].hashCode;
    }
    return hash;
  }

  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
