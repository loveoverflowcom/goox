import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';

class WebViewAllWindowsSmokeApp extends StatelessWidget {
  const WebViewAllWindowsSmokeApp({super.key, this.startAutomatically = true});

  final bool startAutomatically;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'webview_all Desktop Smoke',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF12A89D),
          brightness: Brightness.dark,
          surface: const Color(0xFF111827),
        ),
        scaffoldBackgroundColor: const Color(0xFF07111E),
        useMaterial3: true,
      ),
      home: SmokeHomePage(startAutomatically: startAutomatically),
    );
  }
}

class SmokeHomePage extends StatefulWidget {
  const SmokeHomePage({super.key, this.startAutomatically = true});

  final bool startAutomatically;

  @override
  State<SmokeHomePage> createState() => _SmokeHomePageState();
}

class _SmokeHomePageState extends State<SmokeHomePage> {
  static const String _targetUrl = 'https://www.google.com/?client=safari';

  late final WebViewController _controller;
  String _status = 'Preparing remote URL...';
  final List<String> _bridgeLog = <String>[];
  int _loadToken = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('host', onMessageReceived: _handleBridgeMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _ready = true;
              _status = 'Loaded $_targetUrl';
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _ready = false;
              _status = 'WebView error: ${error.description}';
            });
          },
        ),
      );

    if (widget.startAutomatically) {
      _loadTargetUrl();
    }
  }

  Future<void> _loadTargetUrl() async {
    if (!mounted) return;
    setState(() {
      _status = 'Loading $_targetUrl...';
      _ready = false;
    });

    final loadToken = ++_loadToken;
    try {
      await _controller.loadRequest(Uri.parse(_targetUrl));
      if (!mounted || loadToken != _loadToken) return;
      setState(() {
        _status = 'Loaded $_targetUrl';
      });
    } catch (error) {
      if (!mounted || loadToken != _loadToken) return;
      setState(() {
        _status = 'Failed to load URL: $error';
      });
    }
  }

  Future<void> _reloadPage() async {
    final loadToken = ++_loadToken;
    try {
      await _controller.loadRequest(Uri.parse(_targetUrl));
      if (!mounted || loadToken != _loadToken) return;
      setState(() {
        _status = 'Reloaded $_targetUrl';
      });
    } catch (error) {
      if (!mounted || loadToken != _loadToken) return;
      setState(() {
        _status = 'Reload failed: $error';
      });
    }
  }

  Future<void> _sendPing() async {
    try {
      if (!mounted) return;
      setState(() {
        _status = 'Ping pressed for $_targetUrl';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'Ping failed: $error';
      });
    }
  }

  void _handleBridgeMessage(JavaScriptMessage message) {
    final raw = message.message.trim();
    if (raw.isEmpty) return;

    _bridgeLog.insert(0, raw);
    if (_bridgeLog.length > 6) {
      _bridgeLog.removeRange(6, _bridgeLog.length);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final type = decoded['type']?.toString() ?? 'message';
        setState(() {
          _ready = true;
          _status = 'Bridge: $type';
        });
        return;
      }
    } catch (_) {
      // Keep the raw fallback below.
    }

    setState(() {
      _ready = true;
      _status = raw.length > 64 ? '${raw.substring(0, 64)}…' : raw;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1120;
              final infoPanel = _InfoPanel(
                targetUrl: _targetUrl,
                status: _status,
                bridgeLog: _bridgeLog,
                colorScheme: colorScheme,
              );
              final webViewFrame = _WebViewFrame(
                controller: _controller,
                status: _status,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderBar(
                    status: _status,
                    ready: _ready,
                    onReload: _reloadPage,
                    onPing: _sendPing,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: wide
                        ? Row(
                            children: [
                              Expanded(child: infoPanel),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: webViewFrame),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(flex: 1, child: infoPanel),
                              const SizedBox(height: 16),
                              Expanded(flex: 2, child: webViewFrame),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.status,
    required this.ready,
    required this.onReload,
    required this.onPing,
  });

  final String status;
  final bool ready;
  final VoidCallback onReload;
  final VoidCallback onPing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            colorScheme.surface.withValues(alpha: 0.95),
            colorScheme.surface.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'webview_all Desktop smoke test',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onPing,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Ping host'),
                ),
                OutlinedButton.icon(
                  onPressed: onReload,
                  icon: Icon(ready ? Icons.refresh : Icons.hourglass_empty),
                  label: const Text('Reload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.targetUrl,
    required this.status,
    required this.bridgeLog,
    required this.colorScheme,
  });

  final String targetUrl;
  final String status;
  final List<String> bridgeLog;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colorScheme.surface.withValues(alpha: 0.88),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connection details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _DetailCard(label: 'Target URL', value: targetUrl),
              const SizedBox(height: 12),
              _DetailCard(label: 'Status', value: status),
              const SizedBox(height: 16),
              Text(
                'Latest bridge messages',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: ListView.builder(
                      itemCount: bridgeLog.isEmpty ? 1 : bridgeLog.length,
                      itemBuilder: (context, index) {
                        final text = bridgeLog.isEmpty
                            ? 'No messages yet.'
                            : bridgeLog[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            text,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.5,
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
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _WebViewFrame extends StatelessWidget {
  const _WebViewFrame({required this.controller, required this.status});

  final WebViewController controller;
  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colorScheme.surface.withValues(alpha: 0.9),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF0B1220)),
            WebViewWidget(controller: controller),
            if (status.contains('Loading') || status.contains('Preparing'))
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.76),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 14),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
