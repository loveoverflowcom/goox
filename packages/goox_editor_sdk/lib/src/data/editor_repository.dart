import 'bridge_client.dart';

class GooxEditorRepository {
  GooxEditorRepository({GooxBridgeClient? bridgeClient})
    : _bridgeClient = bridgeClient ?? GooxBridgeClient();

  final GooxBridgeClient _bridgeClient;

  Future<void> seedDocument({required String text}) =>
      _bridgeClient.seedDocument(text: text);

  Future<BridgeBufferSnapshot> getSnapshot() => _bridgeClient.getSnapshot();

  Future<BridgeBufferPatchBatch> applyTransaction({
    required BridgeBufferTransaction transaction,
  }) => _bridgeClient.applyTransaction(transaction: transaction);

  Future<BridgeBufferPatchBatch> undo() => _bridgeClient.undo();

  Future<BridgeBufferPatchBatch> redo() => _bridgeClient.redo();

  Future<BridgeViewportSnapshot> getViewport({
    required BridgeViewportRequest request,
  }) => _bridgeClient.getViewport(request: request);

  Future<BridgeCursorPos> getCursorPosition({required BigInt charIndex}) =>
      _bridgeClient.getCursorPosition(charIndex: charIndex);

  Future<BridgeBufferPatchBatch> deleteLine({required BigInt charIndex}) =>
      _bridgeClient.deleteLine(charIndex: charIndex);

  Future<bool> syncLanguageServer({
    String? workspaceRoot,
    String? filePath,
    String? languageId,
    String? lspExecutable,
    required String text,
  }) => _bridgeClient.syncLanguageServer(
    workspaceRoot: workspaceRoot,
    filePath: filePath,
    languageId: languageId,
    lspExecutable: lspExecutable,
    text: text,
  );

  Future<BridgeLanguageServerSnapshot> pollLanguageServer() =>
      _bridgeClient.pollLanguageServer();

  Future<void> shutdownLanguageServer() =>
      _bridgeClient.shutdownLanguageServer();
}
