import 'package:flutter/material.dart';

import 'extension_webview_renderer.dart';

class GooxExtensionWebViewShell extends StatelessWidget {
  const GooxExtensionWebViewShell({
    super.key,
    required this.extensionName,
    required this.filePath,
    required this.fileType,
    required this.webEntryPath,
    this.onBridgeMessage,
  });

  final String extensionName;
  final String filePath;
  final String fileType;
  final String? webEntryPath;
  final ValueChanged<String>? onBridgeMessage;

  @override
  Widget build(BuildContext context) {
    return GooxExtensionWebViewRenderer.forPlatform(
      extensionName: extensionName,
      filePath: filePath,
      fileType: fileType,
      webEntryPath: webEntryPath,
      onBridgeMessage: onBridgeMessage,
    );
  }
}
