import 'package:flutter/material.dart';

void main() {
  runApp(const PdfViewerExtensionApp());
}

class PdfViewerExtensionApp extends StatelessWidget {
  const PdfViewerExtensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFB55D1D);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const _PdfViewerHome(),
    );
  }
}

class _PdfViewerHome extends StatelessWidget {
  const _PdfViewerHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B120A), Color(0xFF3C2312), Color(0xFF101418)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goox PDF Viewer',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Flutter source extension. The host renders pages and the webview shell provides the UI layer.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _ActionChip(label: 'Prev Page'),
                    _ActionChip(label: 'Next Page'),
                    _ActionChip(label: 'Zoom Out'),
                    _ActionChip(label: 'Zoom In'),
                    _ActionChip(label: 'Reset'),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: const Center(
                      child: Text(
                        'PDF canvas arrives from the Goox host.\nThis Flutter package owns the extension UI.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}
