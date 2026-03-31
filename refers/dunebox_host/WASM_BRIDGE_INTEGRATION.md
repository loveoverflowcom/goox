# Wasm Bridge Integration Guide

## Overview

The `WasmBridge` class provides the interface between the Flutter host application and Dart Wasm guest modules. It manages the Wasm runtime, provides host imports, and handles memory access across the Wasm boundary.

## Current Status

**This is a stub implementation** that demonstrates the architecture and API design. It does not yet integrate with an actual Wasm runtime.

## Architecture

```
┌─────────────────────────────────────┐
│      Flutter Host Application       │
│  ┌───────────────────────────────┐  │
│  │        WasmBridge             │  │
│  │  - load()                     │  │
│  │  - callUpdate()               │  │
│  │  - readMemory()               │  │
│  │  - _hostSendCommands()        │  │
│  │  - _hostLog()                 │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
              ▲
              │ Host Imports
              │ - dunebox.send_commands
              │ - dunebox.log
              │
    ══════════════════════════════════
          Wasm Boundary
    ══════════════════════════════════
              │
              ▼
┌─────────────────────────────────────┐
│       Dart Guest Module (Wasm)      │
│  - update() export                  │
│  - Generates command buffer         │
│  - Calls send_commands()            │
└─────────────────────────────────────┘
```

## API Reference

### Loading a Module

```dart
final bridge = WasmBridge();

await bridge.load(
  'path/to/guest.wasm',
  onCommandBuffer: (buffer) {
    // Process command buffer with BinaryDecoder
    decoder.decode(buffer, canvas);
  },
  onLog: (message) {
    // Handle guest log messages
    print('[Guest] $message');
  },
);
```

### Calling Guest Update

```dart
// Call once per frame
bridge.callUpdate();
```

### Reading Wasm Memory

```dart
// Read memory with bounds checking
final buffer = bridge.readMemory(ptr, len);
```

### Cleanup

```dart
bridge.dispose();
```

## Host Imports

The WasmBridge provides two host imports in the `dunebox` namespace:

### send_commands(ptr: int, len: int)

Called by the guest to transfer the command buffer to the host.

**Parameters:**
- `ptr`: Pointer to command buffer in Wasm linear memory
- `len`: Length of command buffer in bytes

**Behavior:**
1. Reads buffer from Wasm memory at `ptr` with length `len`
2. Performs bounds checking
3. Invokes `onCommandBuffer` callback with the buffer
4. Handles errors gracefully without crashing

### log(ptr: int, len: int)

Called by the guest to log messages.

**Parameters:**
- `ptr`: Pointer to UTF-8 string in Wasm linear memory
- `len`: Length of string in bytes

**Behavior:**
1. Reads UTF-8 string from Wasm memory
2. Decodes to Dart String
3. Invokes `onLog` callback with the message
4. Fails silently on errors (logging should never crash)

## Error Handling

### WasmLoadException

Thrown when module loading fails.

```dart
try {
  await bridge.load('guest.wasm');
} on WasmLoadException catch (e) {
  print('Failed to load: ${e.path}');
  print('Reason: ${e.message}');
}
```

### WasmMemoryException

Thrown when memory access is invalid.

```dart
try {
  final buffer = bridge.readMemory(ptr, len);
} on WasmMemoryException catch (e) {
  print('Memory error at ptr=${e.ptr}, len=${e.len}');
}
```

### GuestPanicException

Thrown when guest code panics or throws unhandled exception.

```dart
try {
  bridge.callUpdate();
} on GuestPanicException catch (e) {
  print('Guest panicked: ${e.message}');
  if (e.stackTrace != null) {
    print('Stack trace: ${e.stackTrace}');
  }
}
```

## Integration with Actual Wasm Runtime

To integrate with an actual Wasm runtime (e.g., `package:wasm` or `dart:wasm`), modify the `load()` method:

```dart
Future<void> load(String wasmPath, ...) async {
  try {
    // Load Wasm module
    _module = await WasmModule.fromFile(wasmPath);
    
    // Instantiate with host imports
    _instance = await _module.instantiate(imports: {
      'dunebox': {
        'send_commands': _hostSendCommands,
        'log': _hostLog,
      },
    });
    
    // Get memory and functions
    _memory = _instance.memory;
    _updateFunction = _instance.getFunction('update');
    
    _isLoaded = true;
  } catch (e) {
    throw WasmLoadException(wasmPath, e.toString());
  }
}
```

And update `callUpdate()`:

```dart
void callUpdate() {
  if (!_isLoaded) {
    throw StateError('Wasm module not loaded');
  }
  
  try {
    _updateFunction.call([]);
  } catch (e) {
    throw GuestPanicException(
      'Guest update() failed: $e',
      stackTrace: StackTrace.current.toString(),
    );
  }
}
```

And update `readMemory()`:

```dart
Uint8List readMemory(int ptr, int len) {
  if (!_isLoaded) {
    throw StateError('Wasm module not loaded');
  }
  
  if (ptr < 0 || len < 0) {
    throw WasmMemoryException(
      'Invalid memory access: negative pointer or length',
      ptr: ptr,
      len: len,
    );
  }
  
  final memorySize = _memory.lengthInBytes;
  if (ptr + len > memorySize) {
    throw WasmMemoryException(
      'Memory access out of bounds',
      ptr: ptr,
      len: len,
    );
  }
  
  return _memory.buffer.asUint8List(ptr, len);
}
```

## Available Wasm Runtimes for Dart

### Option 1: package:wasm (Experimental)

```yaml
dependencies:
  wasm: ^0.1.0  # Check pub.dev for latest version
```

**Status:** Experimental, may not be stable

### Option 2: dart:wasm (Future)

Dart SDK may include built-in Wasm support in future versions.

**Status:** Not yet available

### Option 3: FFI to wasmer/wasmtime

Use `dart:ffi` to call native Wasm runtimes.

**Status:** Requires native bindings, more complex

## Testing

The WasmBridge includes comprehensive tests covering:

- Module loading (8.1)
- Memory access methods (8.2)
- Host import handlers (8.3)
- callUpdate method (8.4)
- Exception handling
- Lifecycle management

Run tests:

```bash
cd packages/dunebox_host
flutter test test/wasm_bridge_test.dart
```

## Example Usage

```dart
import 'package:dunebox_host/dunebox_host.dart';

void main() async {
  final bridge = WasmBridge();
  final registry = ObjectRegistry();
  final decoder = BinaryDecoder(registry);
  
  // Load guest module
  await bridge.load(
    'guest.wasm',
    onCommandBuffer: (buffer) {
      // Decode and execute commands
      final canvas = getCurrentCanvas();
      decoder.decode(buffer, canvas);
    },
    onLog: (message) {
      print('[Guest] $message');
    },
  );
  
  // Animation loop
  while (true) {
    bridge.callUpdate();
    await Future.delayed(Duration(milliseconds: 16)); // 60 FPS
  }
}
```

## Next Steps

1. **Choose Wasm Runtime**: Evaluate available Dart Wasm runtimes
2. **Integrate Runtime**: Implement actual Wasm loading and execution
3. **Test with Real Guest**: Compile Dart guest to Wasm and test
4. **Performance Tuning**: Optimize memory access and boundary crossing
5. **Error Handling**: Enhance error messages and recovery mechanisms

## References

- [Design Document](../../.kiro/specs/flutter-dart-integration/design.md)
- [Requirements Document](../../.kiro/specs/flutter-dart-integration/requirements.md)
- [Binary Decoder](./lib/src/binary_decoder.dart)
- [Object Registry](./lib/src/object_registry.dart)

