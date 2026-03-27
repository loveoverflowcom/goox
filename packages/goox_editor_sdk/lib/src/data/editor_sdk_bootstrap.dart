import 'package:goox_flutter_bridge/goox_flutter_bridge.dart';

final class GooxEditorSdkBootstrap {
  static Future<void> ensureInitialized({String? workspaceRoot}) =>
      GooxRustBootstrap.ensureInitialized(workspaceRoot: workspaceRoot);

  static Future<void> refreshWorkspaceExtensions({required String workspaceRoot}) =>
      GooxRustBootstrap.refreshWorkspaceExtensions(workspaceRoot: workspaceRoot);

  static Future<bool> activateExtensionForFile({
    required String workspaceRoot,
    required String filePath,
  }) =>
      GooxRustBootstrap.activateExtensionForFile(
        workspaceRoot: workspaceRoot,
        filePath: filePath,
      );

  static void initMock({required RustLibApi api}) =>
      GooxRustBootstrap.initMock(api: api);
}
