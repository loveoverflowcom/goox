import 'dart:typed_data';
import 'package:dunebox_protocol/dunebox_protocol.dart';

/// Callback type for receiving command buffers from guest
typedef CommandBufferCallback = void Function(Uint8List buffer);

/// Callback type for receiving log messages from guest
typedef LogCallback = void Function(String message);

/// Bridge between Flutter host and Dart Wasm guest module
/// 
/// This class manages the Wasm runtime, provides host imports,
/// and handles memory access across the Wasm boundary.
/// 
/// NOTE: This is a stub implementation demonstrating the architecture.
/// A production implementation would integrate with an actual Wasm runtime
/// such as package:wasm or dart:wasm when available.
class WasmBridge {
  // Wasm runtime state (stub - would be actual WasmModule/WasmInstance)
  // ignore: unused_field
  dynamic _module;
  // ignore: unused_field
  dynamic _instance;
  // ignore: unused_field
  dynamic _memory;
  // ignore: unused_field
  dynamic _updateFunction;
  
  // Host import callbacks
  CommandBufferCallback? _onCommandBuffer;
  LogCallback? _onLog;
  
  bool _isLoaded = false;
  
  /// Load a Wasm module from file
  /// 
  /// Sets up host imports and instantiates the module.
  /// 
  /// Throws [WasmLoadException] if loading fails.
  Future<void> load(
    String wasmPath, {
    CommandBufferCallback? onCommandBuffer,
    LogCallback? onLog,
  }) async {
    _onCommandBuffer = onCommandBuffer;
    _onLog = onLog;
    
    try {
      // TODO: Integrate with actual Wasm runtime
      // Example with hypothetical package:wasm:
      // 
      // _module = await WasmModule.fromFile(wasmPath);
      // _instance = await _module.instantiate(imports: {
      //   'dunebox': {
      //     'send_commands': _hostSendCommands,
      //     'log': _hostLog,
      //   },
      // });
      // _memory = _instance.memory;
      // _updateFunction = _instance.getFunction('update');
      
      // For now, throw to indicate this needs actual Wasm runtime
      throw WasmLoadException(
        wasmPath,
        'Wasm runtime not yet integrated. '
        'This stub demonstrates the architecture. '
        'Integrate with package:wasm or dart:wasm when available.',
      );
    } catch (e) {
      if (e is WasmLoadException) rethrow;
      throw WasmLoadException(wasmPath, e.toString());
    }
  }
  
  /// Call the guest update() function
  /// 
  /// This triggers one frame of guest execution.
  /// The guest will generate commands and call send_commands host import.
  /// 
  /// Throws [StateError] if module is not loaded.
  void callUpdate() {
    if (!_isLoaded) {
      throw StateError('Wasm module not loaded. Call load() first.');
    }
    
    try {
      // TODO: Call actual Wasm function
      // _updateFunction.call([]);
      
      // Stub: would invoke guest update() which calls send_commands
    } catch (e) {
      // Wrap guest exceptions for better error messages
      throw GuestPanicException(
        'Guest update() failed: $e',
        stackTrace: StackTrace.current.toString(),
      );
    }
  }
  
  /// Read memory from Wasm linear memory
  /// 
  /// Performs bounds checking to prevent invalid memory access.
  /// 
  /// Throws [WasmMemoryException] if access is out of bounds.
  Uint8List readMemory(int ptr, int len) {
    if (!_isLoaded) {
      throw StateError('Wasm module not loaded. Call load() first.');
    }
    
    if (ptr < 0 || len < 0) {
      throw WasmMemoryException(
        'Invalid memory access: negative pointer or length',
        ptr: ptr,
        len: len,
      );
    }
    
    // TODO: Implement actual memory access with bounds checking
    // Example:
    // final memorySize = _memory.lengthInBytes;
    // if (ptr + len > memorySize) {
    //   throw WasmMemoryException(
    //     'Memory access out of bounds: ptr=$ptr, len=$len, memory_size=$memorySize',
    //     ptr: ptr,
    //     len: len,
    //   );
    // }
    // return _memory.buffer.asUint8List(ptr, len);
    
    throw WasmMemoryException(
      'Wasm memory access not yet implemented',
      ptr: ptr,
      len: len,
    );
  }
  
  /// Host import: send_commands(ptr: int, len: int)
  /// 
  /// Called by guest to transfer command buffer to host.
  /// Reads the buffer from Wasm memory and invokes the callback.
  // ignore: unused_element
  void _hostSendCommands(int ptr, int len) {
    try {
      final buffer = readMemory(ptr, len);
      _onCommandBuffer?.call(buffer);
    } catch (e) {
      // Log error but don't crash - allow host to handle gracefully
      _onLog?.call('ERROR: send_commands failed: $e');
    }
  }
  
  /// Host import: log(ptr: int, len: int)
  /// 
  /// Called by guest to log messages.
  /// Reads UTF-8 string from Wasm memory and invokes the callback.
  // ignore: unused_element
  void _hostLog(int ptr, int len) {
    try {
      final buffer = readMemory(ptr, len);
      final message = String.fromCharCodes(buffer);
      _onLog?.call(message);
    } catch (e) {
      // Silently fail - logging should never crash the system
      print('WARNING: Failed to read log message: $e');
    }
  }
  
  /// Check if module is loaded
  bool get isLoaded => _isLoaded;
  
  /// Unload the module and clean up resources
  void dispose() {
    _module = null;
    _instance = null;
    _memory = null;
    _updateFunction = null;
    _onCommandBuffer = null;
    _onLog = null;
    _isLoaded = false;
  }
}

