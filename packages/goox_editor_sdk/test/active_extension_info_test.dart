import 'package:flutter_test/flutter_test.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';
import 'package:goox_flutter_bridge/goox_flutter_bridge.dart' as bridge;

void main() {
  test('ActiveExtensionInfo exposes dual-mode preview capability', () {
    final extension = ActiveExtensionInfo(
      name: 'markdown-preview',
      path: '/tmp/extensions/markdown-preview',
      filetypes: const ['md'],
      rendering: false,
      uiMode: 'none',
      protocol: 'erp/1',
      capabilities: const [],
      extensionType: bridge.ExtensionType.dualMode,
      webEntry: 'webview/index.html',
    );

    expect(extension.extensionType, bridge.ExtensionType.dualMode);
    expect(extension.isDualMode, isTrue);
    expect(extension.hasWebViewCapability, isTrue);
  });

  test('ActiveExtensionInfo.empty defaults to language mode', () {
    final extension = ActiveExtensionInfo.empty();

    expect(extension.extensionType, bridge.ExtensionType.language);
    expect(extension.isDualMode, isFalse);
    expect(extension.hasWebViewCapability, isFalse);
  });
}
