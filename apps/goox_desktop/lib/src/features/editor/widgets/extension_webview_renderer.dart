import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'extension_webview_renderer_macos.dart';
import 'extension_webview_renderer_placeholder.dart';

abstract class GooxExtensionWebViewRenderer extends StatefulWidget {
  const GooxExtensionWebViewRenderer({
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

  factory GooxExtensionWebViewRenderer.forPlatform({
    Key? key,
    required String extensionName,
    required String filePath,
    required String fileType,
    required String? webEntryPath,
    ValueChanged<String>? onBridgeMessage,
  }) {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      return GooxMacosExtensionWebViewRenderer(
        key: key,
        extensionName: extensionName,
        filePath: filePath,
        fileType: fileType,
        webEntryPath: webEntryPath,
        onBridgeMessage: onBridgeMessage,
      );
    }

    return GooxFallbackWebViewRenderer(
      key: key,
      extensionName: extensionName,
      filePath: filePath,
      fileType: fileType,
      webEntryPath: webEntryPath,
      onBridgeMessage: onBridgeMessage,
    );
  }
}
