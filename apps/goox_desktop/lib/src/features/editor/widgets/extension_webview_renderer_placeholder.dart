import 'package:flutter/material.dart';

import 'extension_webview_renderer.dart';

class GooxDesktopPendingWebViewRenderer extends GooxExtensionWebViewRenderer {
  const GooxDesktopPendingWebViewRenderer({
    super.key,
    required super.extensionName,
    required super.filePath,
    required super.fileType,
    required super.webEntryPath,
    super.onBridgeMessage,
  });

  @override
  State<GooxDesktopPendingWebViewRenderer> createState() =>
      _GooxDesktopPendingWebViewRendererState();
}

class GooxFallbackWebViewRenderer extends GooxExtensionWebViewRenderer {
  const GooxFallbackWebViewRenderer({
    super.key,
    required super.extensionName,
    required super.filePath,
    required super.fileType,
    required super.webEntryPath,
    super.onBridgeMessage,
  });

  @override
  State<GooxFallbackWebViewRenderer> createState() =>
      _GooxFallbackWebViewRendererState();
}

class _GooxDesktopPendingWebViewRendererState
    extends State<GooxDesktopPendingWebViewRenderer> {
  @override
  Widget build(BuildContext context) {
    return _PendingRendererCard(
      extensionName: widget.extensionName,
      filePath: widget.filePath,
      fileType: widget.fileType,
      message:
          'Windows and Linux will plug into a dedicated embed engine here later.',
    );
  }
}

class _GooxFallbackWebViewRendererState
    extends State<GooxFallbackWebViewRenderer> {
  @override
  Widget build(BuildContext context) {
    return _PendingRendererCard(
      extensionName: widget.extensionName,
      filePath: widget.filePath,
      fileType: widget.fileType,
      message: 'This platform does not have an embedded WebView engine yet.',
    );
  }
}

class _PendingRendererCard extends StatelessWidget {
  const _PendingRendererCard({
    required this.extensionName,
    required this.filePath,
    required this.fileType,
    required this.message,
  });

  final String extensionName;
  final String filePath;
  final String fileType;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              extensionName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _MetaRow(label: 'File', value: filePath),
            _MetaRow(label: 'Type', value: fileType),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
