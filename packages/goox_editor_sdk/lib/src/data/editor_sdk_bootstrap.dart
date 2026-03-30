import 'dart:typed_data';

import 'package:goox_flutter_bridge/goox_flutter_bridge.dart';

import '../features/editor/models/editor_models.dart';

final class GooxEditorSdkBootstrap {
  static Future<void> ensureInitialized({String? workspaceRoot}) =>
      GooxRustBootstrap.ensureInitialized(workspaceRoot: workspaceRoot);

  static Future<void> refreshWorkspaceExtensions({
    required String workspaceRoot,
  }) => GooxRustBootstrap.refreshWorkspaceExtensions(
    workspaceRoot: workspaceRoot,
  );

  static Future<bool> activateExtensionForFile({
    required String workspaceRoot,
    required String filePath,
  }) => GooxRustBootstrap.activateExtensionForFile(
    workspaceRoot: workspaceRoot,
    filePath: filePath,
  );

  static Future<ActiveExtensionInfo?> resolveExtensionForFile({
    required String workspaceRoot,
    required String filePath,
  }) async {
    final extension = await GooxRustBootstrap.resolveExtensionForFile(
      workspaceRoot: workspaceRoot,
      filePath: filePath,
    );
    if (extension == null) {
      return null;
    }

    return ActiveExtensionInfo(
      name: extension.name,
      path: extension.path,
      entry: extension.entry,
      filetypes: extension.filetypes,
      languageId: extension.languageId,
      lspExecutable: extension.lspExecutable,
      rendering: extension.rendering,
    );
  }

  static Future<int> erpOpenSession({
    required String workspaceRoot,
    required String filePath,
  }) => GooxRustBootstrap.erpOpenSession(
    workspaceRoot: workspaceRoot,
    filePath: filePath,
  );

  static Future<int> erpGetPageCount({required int sessionId}) =>
      GooxRustBootstrap.erpGetPageCount(sessionId: sessionId);

  static Future<Uint8List> erpRenderPage({
    required int sessionId,
    required int pageIndex,
    required int width,
    required int height,
  }) => GooxRustBootstrap.erpRenderPage(
    sessionId: sessionId,
    pageIndex: pageIndex,
    width: width,
    height: height,
  );

  static Future<void> erpCloseSession({required int sessionId}) =>
      GooxRustBootstrap.erpCloseSession(sessionId: sessionId);

  static Future<String?> validateSourceText({
    required String languageId,
    required String text,
  }) =>
      GooxRustBootstrap.validateSourceText(languageId: languageId, text: text);

  static Future<bool> syncLanguageServer({
    String? workspaceRoot,
    String? filePath,
    String? languageId,
    String? lspExecutable,
    required String text,
  }) => GooxRustBootstrap.syncLanguageServer(
    workspaceRoot: workspaceRoot,
    filePath: filePath,
    languageId: languageId,
    lspExecutable: lspExecutable,
    text: text,
  );

  static Future<LanguageServerSnapshot> pollLanguageServer() =>
      GooxRustBootstrap.pollLanguageServer();

  static Future<void> shutdownLanguageServer() =>
      GooxRustBootstrap.shutdownLanguageServer();

  static void initMock({required RustLibApi api}) =>
      GooxRustBootstrap.initMock(api: api);
}
