import 'package:goox_flutter_bridge/goox_flutter_bridge.dart';

final class GooxEditorSdkBootstrap {
  static Future<void> ensureInitialized({String? workspaceRoot}) =>
      GooxRustBootstrap.ensureInitialized(workspaceRoot: workspaceRoot);

  static void initMock({required RustLibApi api}) =>
      GooxRustBootstrap.initMock(api: api);
}
