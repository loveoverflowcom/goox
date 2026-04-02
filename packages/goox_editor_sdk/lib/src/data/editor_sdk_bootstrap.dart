import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:goox_flutter_bridge/goox_flutter_bridge.dart';
import 'package:path/path.dart' as p;

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
      webEntry: extension.webEntry,
      filetypes: extension.filetypes,
      languageId: extension.languageId,
      lspExecutable: extension.lspExecutable,
      rendering: extension.rendering,
      uiMode: extension.uiMode,
      protocol: extension.protocol,
      capabilities: extension.capabilities,
      extensionType: extension.extensionType,
      syntaxGrammarPath: await _resolveSyntaxGrammarPath(extension.path),
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

  static Future<ArtifactDescriptor> erpRenderPageFrame({
    required int sessionId,
    required int pageIndex,
    required int width,
    required int height,
  }) async {
    final json = await GooxRustBootstrap.erpRenderPageFrame(
      sessionId: sessionId,
      pageIndex: pageIndex,
      width: width,
      height: height,
    );
    return ArtifactDescriptor.fromJsonString(json);
  }

  static Future<Uint8List> erpRenderPage({
    required int sessionId,
    required int pageIndex,
    required int width,
    required int height,
  }) async {
    final frame = await erpRenderPageFrame(
      sessionId: sessionId,
      pageIndex: pageIndex,
      width: width,
      height: height,
    );
    return GooxRustBootstrap.erpReadArtifact(
      sessionId: sessionId,
      artifactId: frame.artifactId,
    );
  }

  static Future<void> erpCloseSession({required int sessionId}) =>
      GooxRustBootstrap.erpCloseSession(sessionId: sessionId);

  static Future<String?> erpGetMetadata({required int sessionId}) =>
      GooxRustBootstrap.erpGetMetadata(sessionId: sessionId);

  static Future<Uint8List> erpReadArtifact({
    required int sessionId,
    required int artifactId,
  }) => GooxRustBootstrap.erpReadArtifact(
    sessionId: sessionId,
    artifactId: artifactId,
  );

  static Future<List<ExtensionEvent>> erpDrainEvents({
    required int sessionId,
  }) async {
    final events = await GooxRustBootstrap.erpDrainEvents(sessionId: sessionId);
    return events.map(ExtensionEvent.fromJsonString).toList(growable: false);
  }

  static Future<String?> validateSourceText({
    required String languageId,
    required String text,
  }) =>
      GooxRustBootstrap.validateSourceText(languageId: languageId, text: text);

  static Future<String?> _resolveSyntaxGrammarPath(String extensionPath) async {
    final configFile = File(p.join(extensionPath, 'config.json'));
    if (!configFile.existsSync()) {
      return null;
    }

    try {
      final decoded = jsonDecode(await configFile.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final rawPath = decoded['syntax_grammar'];
      if (rawPath is! String) {
        return null;
      }

      final trimmed = rawPath.trim();
      if (trimmed.isEmpty || p.isAbsolute(trimmed)) {
        return null;
      }

      if (p.split(trimmed).contains('..')) {
        return null;
      }

      final resolved = p.normalize(p.join(extensionPath, trimmed));
      final extensionRoot = p.normalize(extensionPath);
      if (!p.isWithin(extensionRoot, resolved)) {
        return null;
      }

      return File(resolved).existsSync() ? resolved : null;
    } catch (_) {
      return null;
    }
  }

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
