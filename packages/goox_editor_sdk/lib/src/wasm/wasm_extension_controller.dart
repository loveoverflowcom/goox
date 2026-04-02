import 'dart:io';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';

/// Controller for managing WASM extension lifecycle and events
class WasmExtensionController {
  final WasmClient _wasmClient = WasmClient();
  final Map<String, String> _loadedExtensions = {};

  /// Load a WASM extension from file
  Future<void> loadExtension({
    required String extensionId,
    required String wasmFilePath,
  }) async {
    final file = File(wasmFilePath);
    if (!await file.exists()) {
      throw Exception('WASM file not found: $wasmFilePath');
    }

    final wasmBytes = await file.readAsBytes();
    await _wasmClient.loadModule(
      extensionId: extensionId,
      wasmBytes: wasmBytes,
    );

    _loadedExtensions[extensionId] = wasmFilePath;
  }

  /// Notify extension when a file is opened
  Future<void> notifyFileOpened({
    required String extensionId,
    required String filePath,
    required String content,
  }) async {
    if (!await _wasmClient.isLoaded(extensionId: extensionId)) {
      throw Exception('Extension not loaded: $extensionId');
    }

    await _wasmClient.sendFileOpenedEvent(
      extensionId: extensionId,
      path: filePath,
      content: content,
    );
  }

  /// Notify extension when a file is saved
  Future<void> notifyFileSaved({
    required String extensionId,
    required String filePath,
  }) async {
    if (!await _wasmClient.isLoaded(extensionId: extensionId)) {
      return; // Silently ignore if extension not loaded
    }

    await _wasmClient.sendFileSavedEvent(
      extensionId: extensionId,
      path: filePath,
    );
  }

  /// Notify extension when a file is edited
  Future<void> notifyFileEdited({
    required String extensionId,
    required String filePath,
    required WasmEdit edit,
  }) async {
    if (!await _wasmClient.isLoaded(extensionId: extensionId)) {
      return; // Silently ignore if extension not loaded
    }

    await _wasmClient.sendFileEditedEvent(
      extensionId: extensionId,
      path: filePath,
      startByte: edit.startByte,
      oldEndByte: edit.oldEndByte,
      newEndByte: edit.newEndByte,
    );
  }

  /// Notify extension when a file is closed
  Future<void> notifyFileClosed({
    required String extensionId,
    required String filePath,
  }) async {
    if (!await _wasmClient.isLoaded(extensionId: extensionId)) {
      return; // Silently ignore if extension not loaded
    }

    await _wasmClient.sendFileClosedEvent(
      extensionId: extensionId,
      path: filePath,
    );
  }

  /// Unload an extension
  Future<bool> unloadExtension({required String extensionId}) async {
    final result = await _wasmClient.unloadModule(extensionId: extensionId);
    if (result) {
      _loadedExtensions.remove(extensionId);
    }
    return result;
  }

  /// Check if an extension is loaded
  Future<bool> isExtensionLoaded({required String extensionId}) async {
    return await _wasmClient.isLoaded(extensionId: extensionId);
  }

  /// Get list of all loaded extensions
  Future<List<String>> getLoadedExtensions() async {
    return await _wasmClient.loadedExtensions();
  }

  /// Get the file path of a loaded extension
  String? getExtensionPath(String extensionId) {
    return _loadedExtensions[extensionId];
  }

  /// Dispose all loaded extensions
  Future<void> dispose() async {
    final extensions = await getLoadedExtensions();
    for (final extensionId in extensions) {
      await unloadExtension(extensionId: extensionId);
    }
    _loadedExtensions.clear();
  }
}
