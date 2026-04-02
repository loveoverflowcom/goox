import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
  late final WebViewController _controller;
  File? _pageFile;
  String _status = 'Preparing local HTML...';
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
            _injectHostPayload();
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
      _prepareAndLoadPage();
    }
  }

  Future<void> _prepareAndLoadPage() async {
    final directory = await Directory.systemTemp.createTemp(
      'webview_all_windows_smoke_',
    );
    final pageFile = File(
      '${directory.path}${Platform.pathSeparator}index.html',
    );
    await pageFile.writeAsString(_buildHtmlPage());

    if (!mounted) return;
    setState(() {
      _pageFile = pageFile;
      _status = 'Loading local file...';
      _ready = false;
    });

    final loadToken = ++_loadToken;
    try {
      await _controller.loadFile(pageFile.path);
      if (!mounted || loadToken != _loadToken) return;
      setState(() {
        _status = 'Local page loaded';
      });
    } catch (error) {
      if (!mounted || loadToken != _loadToken) return;
      setState(() {
        _status = 'Failed to load page: $error';
      });
    }
  }

  Future<void> _reloadPage() async {
    if (_pageFile == null) {
      await _prepareAndLoadPage();
      return;
    }

    final loadToken = ++_loadToken;
    try {
      await _controller.loadFile(_pageFile!.path);
      if (!mounted || loadToken != _loadToken) return;
      setState(() {
        _status = 'Reloaded local page';
      });
    } catch (error) {
      if (!mounted || loadToken != _loadToken) return;
      setState(() {
        _status = 'Reload failed: $error';
      });
    }
  }

  Future<void> _injectHostPayload() async {
    if (!mounted || _pageFile == null) return;

    final payload = <String, dynamic>{
      'type': 'host-sync',
      'title': 'webview_all smoke test',
      'timestamp': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.name,
      'ready': true,
      'filePath': _pageFile!.path,
    };

    final script =
        '''
window.dispatchEvent(new CustomEvent('goox-smoke-host', {
  detail: ${jsonEncode(payload)}
}));
''';

    try {
      await _controller.runJavaScript(script);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'Host injection failed: $error';
      });
    }
  }

  Future<void> _sendPing() async {
    final payload = <String, dynamic>{
      'type': 'ping',
      'nonce': math.Random().nextInt(1 << 31),
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await _controller.runJavaScript('''
window.dispatchEvent(new CustomEvent('goox-smoke-host', {
  detail: ${jsonEncode(payload)}
}));
''');
      if (!mounted) return;
      setState(() {
        _status = 'Sent host event to the page';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'Failed to send host event: $error';
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

  String _buildHtmlPage() {
    return '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>webview_all Desktop Smoke</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #07111e;
      --panel: rgba(15, 23, 42, 0.88);
      --panel-border: rgba(148, 163, 184, 0.18);
      --text: #e5eefc;
      --muted: #93a4bf;
      --accent: #12a89d;
      --accent-2: #f59e0b;
    }

    * { box-sizing: border-box; }
    html, body { margin: 0; min-height: 100%; }
    body {
      font-family: "Segoe UI", system-ui, sans-serif;
      background:
        radial-gradient(circle at top left, rgba(18, 168, 157, 0.22), transparent 24%),
        radial-gradient(circle at top right, rgba(245, 158, 11, 0.16), transparent 28%),
        linear-gradient(180deg, #07111e 0%, var(--bg) 100%);
      color: var(--text);
    }
    .page {
      max-width: 1180px;
      margin: 0 auto;
      padding: 24px;
    }
    .hero {
      display: flex;
      justify-content: space-between;
      gap: 20px;
      align-items: end;
      padding: 24px;
      border-radius: 24px;
      background: linear-gradient(180deg, rgba(15, 23, 42, 0.96), rgba(15, 23, 42, 0.76));
      border: 1px solid var(--panel-border);
      box-shadow: 0 24px 54px rgba(2, 6, 23, 0.42);
    }
    .eyebrow {
      margin: 0 0 10px;
      color: var(--accent-2);
      text-transform: uppercase;
      letter-spacing: 0.18em;
      font-size: 0.76rem;
      font-weight: 700;
    }
    h1 {
      margin: 0 0 10px;
      font-size: clamp(2rem, 4vw, 3.4rem);
      line-height: 1;
    }
    p {
      margin: 0;
      max-width: 72ch;
      color: var(--muted);
      line-height: 1.6;
    }
    .actions {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      justify-content: flex-end;
    }
    .button {
      appearance: none;
      border: 1px solid var(--panel-border);
      background: rgba(15, 23, 42, 0.96);
      color: var(--text);
      padding: 12px 16px;
      border-radius: 14px;
      font: inherit;
      font-weight: 700;
      cursor: pointer;
    }
    .button--primary {
      border-color: rgba(18, 168, 157, 0.35);
      background: linear-gradient(180deg, rgba(18, 168, 157, 0.28), rgba(15, 23, 42, 0.95));
    }
    .status {
      margin: 16px 0 18px;
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
      align-items: center;
      color: var(--muted);
    }
    .pill {
      display: inline-flex;
      align-items: center;
      padding: 8px 12px;
      border-radius: 999px;
      background: rgba(148, 163, 184, 0.14);
      color: #dbeafe;
      font-weight: 700;
      letter-spacing: 0.02em;
    }
    .layout {
      display: grid;
      gap: 18px;
      grid-template-columns: 1fr 1fr;
    }
    .panel {
      padding: 18px;
      border-radius: 22px;
      background: var(--panel);
      border: 1px solid var(--panel-border);
      backdrop-filter: blur(12px);
    }
    .panel--wide {
      grid-column: 1 / -1;
    }
    .title {
      margin: 0 0 12px;
      color: #cbd5e1;
      font-size: 0.84rem;
      text-transform: uppercase;
      letter-spacing: 0.12em;
      font-weight: 800;
    }
    .value, pre {
      margin: 0;
      white-space: pre-wrap;
      word-break: break-word;
      line-height: 1.6;
    }
    .card {
      display: grid;
      gap: 8px;
      padding: 12px;
      border-radius: 16px;
      background: rgba(148, 163, 184, 0.06);
    }
    .muted {
      color: var(--muted);
      font-size: 0.9rem;
    }
    @media (max-width: 860px) {
      .hero { flex-direction: column; align-items: stretch; }
      .actions { justify-content: flex-start; }
      .layout { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <div class="page">
    <section class="hero">
      <div>
        <div class="eyebrow">webview_all smoke test</div>
        <h1>Desktop WebView sample</h1>
        <p>
          This page is loaded from a local file so you can verify that
          <code>webview_all</code> starts correctly on Windows and that the JS
          bridge still works.
        </p>
      </div>
      <div class="actions">
        <button id="pingButton" class="button button--primary">Ping host</button>
        <button id="clearButton" class="button">Clear log</button>
      </div>
    </section>

    <section class="status">
      <span id="statusPill" class="pill">Waiting for host...</span>
      <span id="statusText">No data has been injected yet.</span>
    </section>

    <section class="layout">
      <article class="panel">
        <div class="title">Injected data</div>
        <div class="card">
          <div><strong>File path</strong></div>
          <div id="filePath" class="value muted">-</div>
        </div>
        <div style="height: 10px;"></div>
        <div class="card">
          <div><strong>Payload</strong></div>
          <div id="payload" class="value muted">-</div>
        </div>
      </article>

      <article class="panel">
        <div class="title">Bridge log</div>
        <pre id="log">No bridge messages yet.</pre>
      </article>

      <article class="panel panel--wide">
        <div class="title">Test notes</div>
        <pre>1. If this view renders, the Windows plugin is alive.
2. If you see "Bridge: ready", the page sent a message to Flutter.
3. If you click "Ping host" and the log updates, two-way messaging works.</pre>
      </article>
    </section>
  </div>

  <script>
    (function () {
      const logEl = document.getElementById('log');
      const statusPill = document.getElementById('statusPill');
      const statusText = document.getElementById('statusText');
      const filePathEl = document.getElementById('filePath');
      const payloadEl = document.getElementById('payload');
      const pingButton = document.getElementById('pingButton');
      const clearButton = document.getElementById('clearButton');
      const log = [];

      function append(entry) {
        log.unshift(entry);
        logEl.textContent = log.slice(0, 8).join('\\n\\n');
      }

      function setStatus(label, detail) {
        statusPill.textContent = label;
        statusText.textContent = detail;
      }

      function send(payload) {
        const message = typeof payload === 'string' ? payload : JSON.stringify(payload);
        append('-> ' + message);

        if (window.host && typeof window.host.postMessage === 'function') {
          window.host.postMessage(message);
          return;
        }
        if (window.chrome && window.chrome.webview && window.chrome.webview.postMessage) {
          window.chrome.webview.postMessage(message);
          return;
        }
        if (window.external && typeof window.external.invoke === 'function') {
          window.external.invoke(message);
        }
      }

      document.addEventListener('goox-smoke-host', function (event) {
        const detail = event.detail || {};
        filePathEl.textContent = detail.filePath || '-';
        payloadEl.textContent = JSON.stringify(detail, null, 2);
        setStatus('Ready', 'Received host data from Flutter.');
        append('<- ' + JSON.stringify(detail));
      });

      pingButton.addEventListener('click', function () {
        send({
          type: 'ping',
          timestamp: new Date().toISOString(),
          userAgent: navigator.userAgent,
        });
      });

      clearButton.addEventListener('click', function () {
        log.length = 0;
        logEl.textContent = 'Log cleared.';
      });

      window.addEventListener('DOMContentLoaded', function () {
        send({
          type: 'ready',
          platform: 'windows',
          title: 'webview_all smoke test',
        });
      });
    })();
  </script>
</body>
</html>
''';
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
                pageFile: _pageFile,
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
    required this.pageFile,
    required this.status,
    required this.bridgeLog,
    required this.colorScheme,
  });

  final File? pageFile;
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
              _DetailCard(
                label: 'Local file',
                value: pageFile?.path ?? 'Not ready yet',
              ),
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
