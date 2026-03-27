import 'package:goox_flutter_bridge/goox_flutter_bridge.dart' as bridge;

typedef BridgeBufferError = bridge.BufferError;
typedef BridgeBufferOperation = bridge.BufferOperation;
typedef BridgeBufferPatchBatch = bridge.BufferPatchBatch;
typedef BridgeBufferSnapshot = bridge.BufferSnapshot;
typedef BridgeBufferTransaction = bridge.BufferTransaction;
typedef BridgeCursorPos = bridge.CursorPos;
typedef BridgeViewportLine = bridge.ViewportLine;
typedef BridgeViewportRequest = bridge.ViewportRequest;
typedef BridgeViewportSnapshot = bridge.ViewportSnapshot;

class GooxBridgeClient {
  Future<void> seedDocument({required String text}) =>
      bridge.seedDocument(text: text);

  Future<BridgeBufferSnapshot> getSnapshot() => bridge.getSnapshot();

  Future<BridgeBufferPatchBatch> applyTransaction({
    required BridgeBufferTransaction transaction,
  }) => bridge.applyTransaction(transaction: transaction);

  Future<BridgeBufferPatchBatch> undo() => bridge.undo();

  Future<BridgeBufferPatchBatch> redo() => bridge.redo();

  Future<BridgeViewportSnapshot> getViewport({
    required BridgeViewportRequest request,
  }) => bridge.getViewport(request: request);

  Future<BridgeCursorPos> getCursorPosition({required BigInt charIndex}) =>
      bridge.getCursorPosition(charIndex: charIndex);

  Future<BridgeBufferPatchBatch> deleteLine({required BigInt charIndex}) =>
      bridge.deleteLine(charIndex: charIndex);
}
