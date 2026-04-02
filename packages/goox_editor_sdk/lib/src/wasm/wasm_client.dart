import 'package:goox_flutter_bridge/goox_flutter_bridge.dart' as bridge;

/// Client for interacting with WASM extension runtime
class WasmClient {
  /// Load a WASM module for an extension
  Future<void> loadModule({
    required String extensionId,
    required List<int> wasmBytes,
  }) async {
    await bridge.wasmLoadModule(
      extensionId: extensionId,
      wasmBytes: wasmBytes,
    );
  }

  /// Send file opened event to WASM module
  Future<void> sendFileOpenedEvent({
    required String extensionId,
    required String path,
    required String content,
  }) async {
    await bridge.wasmSendFileOpenedEvent(
      extensionId: extensionId,
      path: path,
      content: content,
    );
  }

  /// Send file saved event to WASM module
  Future<void> sendFileSavedEvent({
    required String extensionId,
    required String path,
  }) async {
    await bridge.wasmSendFileSavedEvent(
      extensionId: extensionId,
      path: path,
    );
  }

  /// Send file edited event to WASM module
  Future<void> sendFileEditedEvent({
    required String extensionId,
    required String path,
    required int startByte,
    required int oldEndByte,
    required int newEndByte,
  }) async {
    await bridge.wasmSendFileEditedEvent(
      extensionId: extensionId,
      path: path,
      startByte: BigInt.from(startByte),
      oldEndByte: BigInt.from(oldEndByte),
      newEndByte: BigInt.from(newEndByte),
    );
  }

  /// Send file closed event to WASM module
  Future<void> sendFileClosedEvent({
    required String extensionId,
    required String path,
  }) async {
    await bridge.wasmSendFileClosedEvent(
      extensionId: extensionId,
      path: path,
    );
  }

  /// Check if an extension's WASM module is loaded
  Future<bool> isLoaded({required String extensionId}) async {
    return await bridge.wasmIsLoaded(extensionId: extensionId);
  }

  /// Unload a WASM module
  Future<bool> unloadModule({required String extensionId}) async {
    return await bridge.wasmUnloadModule(extensionId: extensionId);
  }

  /// Get list of loaded extension IDs
  Future<List<String>> loadedExtensions() async {
    return await bridge.wasmLoadedExtensions();
  }
}

/// Extension event types that can be sent to WASM modules
enum WasmEventType {
  fileOpened,
  fileSaved,
  fileEdited,
  fileClosed,
}

/// Edit information for file change events
class WasmEdit {
  final int startByte;
  final int oldEndByte;
  final int newEndByte;

  const WasmEdit({
    required this.startByte,
    required this.oldEndByte,
    required this.newEndByte,
  });
}
