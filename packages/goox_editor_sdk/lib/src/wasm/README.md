# WASM Extension API

This module provides Dart-side APIs for communicating with WASM extension modules.

## Overview

The WASM extension system allows extensions to include compiled WebAssembly modules that can respond to editor events like file opens, edits, saves, and closes. This enables extensions to implement custom logic in Rust (or other languages that compile to WASM) while maintaining a secure, sandboxed execution environment.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter/Dart Layer                       │
│                                                               │
│  ┌──────────────────┐         ┌─────────────────────────┐  │
│  │ WasmExtension    │────────▶│  WasmClient             │  │
│  │ Controller       │         │  (FFI Bridge)           │  │
│  └──────────────────┘         └─────────────────────────┘  │
│         │                               │                    │
└─────────┼───────────────────────────────┼────────────────────┘
          │                               │
          │                               ▼
          │                     ┌─────────────────────────┐
          │                     │   Rust Bridge Layer     │
          │                     │   (api.rs)              │
          │                     └─────────────────────────┘
          │                               │
          │                               ▼
          │                     ┌─────────────────────────┐
          │                     │   WasmRuntime           │
          │                     │   (wasm_runtime.rs)     │
          │                     └─────────────────────────┘
          │                               │
          │                               ▼
          │                     ┌─────────────────────────┐
          └────────────────────▶│   WASM Module           │
                                │   (extension.wasm)      │
                                └─────────────────────────┘
```

## Components

### WasmClient

Low-level client for direct FFI calls to the Rust bridge. Provides methods for:
- Loading WASM modules
- Sending events to WASM modules
- Checking module status
- Unloading modules

### WasmExtensionController

High-level controller for managing WASM extension lifecycle. Provides:
- Extension loading from file paths
- Event notification with validation
- Extension lifecycle management
- Error handling

## Usage

### Basic Example

```dart
import 'package:goox_editor_sdk/goox_editor_sdk.dart';

// Create controller
final controller = WasmExtensionController();

// Load extension
await controller.loadExtension(
  extensionId: 'my-extension',
  wasmFilePath: '/path/to/extension.wasm',
);

// Notify extension when file is opened
await controller.notifyFileOpened(
  extensionId: 'my-extension',
  filePath: '/path/to/file.dart',
  content: 'void main() { }',
);

// Notify extension when file is edited
await controller.notifyFileEdited(
  extensionId: 'my-extension',
  filePath: '/path/to/file.dart',
  edit: WasmEdit(
    startByte: 0,
    oldEndByte: 5,
    newEndByte: 10,
  ),
);

// Notify extension when file is saved
await controller.notifyFileSaved(
  extensionId: 'my-extension',
  filePath: '/path/to/file.dart',
);

// Notify extension when file is closed
await controller.notifyFileClosed(
  extensionId: 'my-extension',
  filePath: '/path/to/file.dart',
);

// Unload extension
await controller.unloadExtension(extensionId: 'my-extension');
```

### Integration with Editor

```dart
class EditorWithWasmSupport extends StatefulWidget {
  @override
  State<EditorWithWasmSupport> createState() => _EditorWithWasmSupportState();
}

class _EditorWithWasmSupportState extends State<EditorWithWasmSupport> {
  final WasmExtensionController _wasmController = WasmExtensionController();
  String? _currentExtensionId;
  String? _currentFilePath;

  @override
  void initState() {
    super.initState();
    _loadExtensionForFile();
  }

  Future<void> _loadExtensionForFile() async {
    // Determine which extension to load based on file type
    final extensionId = 'dart-extension';
    final wasmPath = '/extensions/dart-extension/extension.wasm';
    
    try {
      await _wasmController.loadExtension(
        extensionId: extensionId,
        wasmFilePath: wasmPath,
      );
      _currentExtensionId = extensionId;
    } catch (e) {
      print('Failed to load WASM extension: $e');
    }
  }

  Future<void> _onFileOpened(String path, String content) async {
    if (_currentExtensionId != null) {
      await _wasmController.notifyFileOpened(
        extensionId: _currentExtensionId!,
        filePath: path,
        content: content,
      );
      _currentFilePath = path;
    }
  }

  Future<void> _onFileEdited(int start, int oldEnd, int newEnd) async {
    if (_currentExtensionId != null && _currentFilePath != null) {
      await _wasmController.notifyFileEdited(
        extensionId: _currentExtensionId!,
        filePath: _currentFilePath!,
        edit: WasmEdit(
          startByte: start,
          oldEndByte: oldEnd,
          newEndByte: newEnd,
        ),
      );
    }
  }

  Future<void> _onFileSaved() async {
    if (_currentExtensionId != null && _currentFilePath != null) {
      await _wasmController.notifyFileSaved(
        extensionId: _currentExtensionId!,
        filePath: _currentFilePath!,
      );
    }
  }

  @override
  void dispose() {
    if (_currentExtensionId != null && _currentFilePath != null) {
      _wasmController.notifyFileClosed(
        extensionId: _currentExtensionId!,
        filePath: _currentFilePath!,
      );
    }
    _wasmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build editor UI
    return Container();
  }
}
```

## Event Types

### FileOpened
Sent when a file is opened in the editor.
- **Parameters**: `path` (String), `content` (String)
- **Use case**: Initialize extension state, parse file content

### FileSaved
Sent when a file is saved.
- **Parameters**: `path` (String)
- **Use case**: Trigger validation, update caches

### FileEdited
Sent when a file is edited.
- **Parameters**: `path` (String), `edit` (WasmEdit with startByte, oldEndByte, newEndByte)
- **Use case**: Incremental parsing, real-time validation

### FileClosed
Sent when a file is closed.
- **Parameters**: `path` (String)
- **Use case**: Clean up extension state, free resources

## WASM Module Interface

Extensions must implement event handlers in their WASM modules:

```rust
// Rust example for WASM extension

#[no_mangle]
pub extern "C" fn on_file_opened(
    path_ptr: *const u8,
    path_len: usize,
    content_ptr: *const u8,
    content_len: usize,
) {
    let path = unsafe {
        std::str::from_utf8_unchecked(
            std::slice::from_raw_parts(path_ptr, path_len)
        )
    };
    let content = unsafe {
        std::str::from_utf8_unchecked(
            std::slice::from_raw_parts(content_ptr, content_len)
        )
    };
    
    // Extension logic here
    println!("File opened: {}", path);
}

#[no_mangle]
pub extern "C" fn on_file_saved(path_ptr: *const u8, path_len: usize) {
    // Handle file save
}

#[no_mangle]
pub extern "C" fn on_file_edited(
    path_ptr: *const u8,
    path_len: usize,
    start: usize,
    old_end: usize,
    new_end: usize,
) {
    // Handle file edit
}

#[no_mangle]
pub extern "C" fn on_file_closed(path_ptr: *const u8, path_len: usize) {
    // Handle file close
}
```

## Security

WASM modules run in a sandboxed environment with:
- Limited memory access
- No direct file system access
- No network access
- CPU time limits

All communication between Dart and WASM happens through the controlled message passing API.

## Error Handling

The API uses Dart's `Future` with exceptions for error handling:

```dart
try {
  await controller.loadExtension(
    extensionId: 'my-extension',
    wasmFilePath: '/path/to/extension.wasm',
  );
} catch (e) {
  print('Failed to load extension: $e');
  // Handle error (show notification, use fallback, etc.)
}
```

Common errors:
- **File not found**: WASM file doesn't exist at specified path
- **Invalid WASM**: WASM file is corrupted or invalid
- **Extension not loaded**: Trying to send events to unloaded extension
- **Memory limit exceeded**: WASM module exceeded memory limits

## Performance Considerations

- WASM modules are loaded once and reused for multiple files
- Events are sent asynchronously to avoid blocking the UI
- Extensions should handle events efficiently to maintain editor responsiveness
- Consider debouncing file edit events for better performance

## Requirements Validated

This implementation validates:
- **Requirement 14.3**: Message passing between Dart and WASM
- **Requirement 14.5**: WASM event handlers for file operations
- **Requirement 14.2**: Sandboxed API for file reading and event handling
- **Requirement 14.7**: UI updates from WASM modules
