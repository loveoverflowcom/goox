# Goox Editor Engine

Core editor functionality and Rust backend communication for the Goox editor.

## Overview

The `goox_editor_engine` package provides a clean interface for interacting with the Rust-based language server backend through flutter_rust_bridge. It encapsulates all editor operations including file management, content editing, and language server features.

## Features

- **Abstract Interface**: `EditorCoreClient` interface for dependency injection and testing
- **Rust Backend Integration**: `RustEditorCoreClient` implementation using flutter_rust_bridge
- **Immutable Models**: Type-safe data classes for editor state and operations
- **Error Handling**: Custom exceptions with detailed error information

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  goox_editor_engine:
    path: packages/goox_editor_engine
```

## Usage

### Basic Example

```dart
import 'package:goox_editor_engine/goox_editor_engine.dart';

// Create a client instance
final client = RustEditorCoreClient(rustBridge);

// Open a file
try {
  final viewState = await client.openFile('/path/to/file.dart');
  print('Opened file: ${viewState.filePath}');
  print('Content length: ${viewState.content.length}');
} on EditorCoreException catch (e) {
  print('Failed to open file: ${e.message}');
}

// Apply a patch
final patch = EditorPatch(
  filePath: '/path/to/file.dart',
  startOffset: 0,
  endOffset: 5,
  newText: 'Hello',
  version: viewState.version,
);

try {
  final updatedState = await client.applyPatch(patch);
  print('Patch applied successfully');
} on EditorCoreException catch (e) {
  print('Failed to apply patch: ${e.message}');
}

// Get hover information
final location = LanguageServerLocation(
  filePath: '/path/to/file.dart',
  line: 10,
  column: 5,
);

final hover = await client.getHover('/path/to/file.dart', location);
if (hover != null) {
  print('Hover info: ${hover.contents}');
}

// Clean up
await client.dispose();
```

### Dependency Injection

Use the `EditorCoreClient` interface for dependency injection:

```dart
class EditorService {
  EditorService(this._client);
  
  final EditorCoreClient _client;
  
  Future<void> openAndEdit(String filePath) async {
    final state = await _client.openFile(filePath);
    // ... perform operations
  }
}

// In production
final service = EditorService(RustEditorCoreClient(rustBridge));

// In tests
final service = EditorService(MockEditorCoreClient());
```

## Architecture

The package follows a layered architecture:

- **Interface Layer**: `EditorCoreClient` abstract interface
- **Implementation Layer**: `RustEditorCoreClient` concrete implementation
- **Model Layer**: Immutable data classes (`EditorViewState`, `EditorPatch`, etc.)
- **Exception Layer**: Custom exceptions for error handling

## Models

### EditorViewState

Represents the complete state of an editor view:

```dart
final state = EditorViewState(
  filePath: '/path/to/file.dart',
  content: 'void main() {}',
  cursorPosition: CursorPosition(line: 0, column: 0, offset: 0),
  language: 'dart',
  isDirty: false,
  version: 1,
);
```

### EditorPatch

Represents a change to apply to editor content:

```dart
final patch = EditorPatch(
  filePath: '/path/to/file.dart',
  startOffset: 0,
  endOffset: 5,
  newText: 'Hello',
  version: 1,
);
```

### CursorPosition

Represents a cursor position in the editor:

```dart
final position = CursorPosition(
  line: 10,      // Zero-based line number
  column: 5,     // Zero-based column number
  offset: 105,   // Absolute character offset
);
```

## Error Handling

All operations may throw `EditorCoreException`:

```dart
try {
  await client.openFile('/path/to/file.dart');
} on EditorCoreException catch (e) {
  print('Error: ${e.message}');
  print('Original error: ${e.originalError}');
  print('Stack trace: ${e.stackTrace}');
}
```

## Development

### Running Tests

```bash
cd packages/goox_editor_engine
flutter test
```

### Code Analysis

```bash
cd packages/goox_editor_engine
flutter analyze
```

## License

This package is part of the Goox editor project and is not intended for public distribution.
