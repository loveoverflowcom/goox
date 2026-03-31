import 'package:flutter/material.dart';

void main() {
  runApp(const ImageViewerExtensionApp());
}

class ImageViewerExtensionApp extends StatelessWidget {
  const ImageViewerExtensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF1D5DB5);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const _ImageViewerHome(),
    );
  }
}

class _ImageViewerHome extends StatelessWidget {
  const _ImageViewerHome();

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
            colors: [Color(0xFF0B1730), Color(0xFF12386B), Color(0xFF101418)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goox Image Viewer',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Flutter source extension. Host-side decoding and rendering feed this UI through the webview bridge.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _ActionChip(label: 'Fit'),
                    _ActionChip(label: '1:1'),
                    _ActionChip(label: 'Rotate'),
                    _ActionChip(label: 'Download'),
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
                        'Image canvas arrives from the Goox host.\nThis Flutter package owns the extension UI.',
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
