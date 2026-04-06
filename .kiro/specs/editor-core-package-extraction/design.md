# Design Document: Editor Core Package Extraction

## Overview

This design document outlines the technical approach for extracting editor core functionality into a standalone Dart package. The new `editor_core` package will encapsulate all communication logic with the Rust-based language server backend through flutter_rust_bridge, providing a clean interface for the main application to interact with editor core features.

### Goals

- Create a reusable, well-structured package for editor core functionality
- Establish clear separation between Flutter UI layer and Rust backend communication
- Provide type-safe interfaces for editor operations
- Enable easier testing through interface abstraction
- Improve code organization and maintainability

### Non-Goals

- Implementing new editor features beyond what's required for the extraction
- Modifying the Rust backend implementation
- Creating a publicly publishable package (this is internal only)
- Implementing UI components (those remain in the main application)

## Architecture

### Package Structure

```
packages/editor_core/
├── lib/
│   ├── src/
│   │   ├── client/
│   │   │   ├── editor_core_client.dart          # Abstract interface
│   │   │   └── rust_editor_core_client.dart     # Rust implementation
│   │   ├── models/
│   │   │   ├── editor_view_state.dart
│   │   │   ├── editor_patch.dart
│   │   │   ├── cursor_position.dart
│   │   │   ├── language_server_location.dart
│   │   │   └── language_server_hover.dart
│   │   └── exceptions/
│   │       └── editor_core_exception.dart
│   └── editor_core.dart                          # Public API exports
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

### Architectural Layers

1. **Interface Layer** (`EditorCoreClient`): Abstract contract defining all editor operations
2. **Implementation Layer** (`RustEditorCoreClient`): Concrete implementation using flutter_rust_bridge
3. **Model Layer**: Immutable data classes representing editor state and operations
4. **Exception Layer**: Custom exceptions for error handling

### Design Principles

- **Dependency Inversion**: Main application depends on `EditorCoreClient` interface, not concrete implementation
- **Single Responsibility**: Each model class represents one concept
- **Immutability**: All model classes are immutable with `copyWith` methods
- **Fail-Fast**: Errors from Rust backend are immediately converted to typed exceptions

## Components and Interfaces

### EditorCoreClient Interface

```dart
/// Abstract interface for editor core operations.
///
/// This interface defines all operations for interacting with the editor
/// backend, including file operations, content editing, and language server
/// features.
abstract interface class EditorCoreClient {
  /// Opens a file in the editor and returns its initial view state.
  ///
  /// Throws [EditorCoreException] if the file cannot be opened.
  Future<EditorViewState> openFile(String filePath);
  
  /// Applies a patch to the editor content.
  ///
  /// Returns the updated [EditorViewState] after applying the patch.
  /// Throws [EditorCoreException] if the patch cannot be applied.
  Future<EditorViewState> applyPatch(EditorPatch patch);
  
  /// Gets the current view state for a file.
  ///
  /// Throws [EditorCoreException] if the file is not open.
  Future<EditorViewState> getViewState(String filePath);
  
  /// Closes a file in the editor.
  ///
  /// Throws [EditorCoreException] if the file cannot be closed.
  Future<void> closeFile(String filePath);
  
  /// Gets hover information at a specific location.
  ///
  /// Returns null if no hover information is available.
  /// Throws [EditorCoreException] if the request fails.
  Future<LanguageServerHover?> getHover(
    String filePath,
    LanguageServerLocation location,
  );
  
  /// Gets diagnostics (errors, warnings) for a file.
  ///
  /// Returns an empty list if no diagnostics are available.
  /// Throws [EditorCoreException] if the request fails.
  Future<List<Diagnostic>> getDiagnostics(String filePath);
  
  /// Disposes resources used by the client.
  Future<void> dispose();
}
```

### RustEditorCoreClient Implementation

```dart
/// Implementation of [EditorCoreClient] using Rust backend via flutter_rust_bridge.
final class RustEditorCoreClient implements EditorCoreClient {
  RustEditorCoreClient(this._bridge);
  
  final RustBridge _bridge; // flutter_rust_bridge generated class
  
  @override
  Future<EditorViewState> openFile(String filePath) async {
    try {
      final result = await _bridge.openFile(filePath: filePath);
      return EditorViewState.fromRust(result);
    } catch (e, stackTrace) {
      throw EditorCoreException(
        message: 'Failed to open file: $filePath',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  // ... other method implementations
}
```

### Key Design Decisions

1. **Interface-based design**: Using `abstract interface class` ensures the contract cannot be extended, only implemented
2. **Future-based API**: All operations are asynchronous to accommodate Rust FFI calls
3. **Null safety**: Hover information returns nullable type as it may not always be available
4. **Resource management**: Explicit `dispose()` method for cleanup

## Data Models

### EditorViewState

Represents the complete state of an editor view for a file.

```dart
/// Represents the current state of an editor view.
final class EditorViewState extends Equatable {
  const EditorViewState({
    required this.filePath,
    required this.content,
    required this.cursorPosition,
    required this.language,
    required this.isDirty,
    required this.version,
  });
  
  /// The absolute path to the file.
  final String filePath;
  
  /// The current content of the file.
  final String content;
  
  /// The current cursor position.
  final CursorPosition cursorPosition;
  
  /// The programming language of the file.
  final String language;
  
  /// Whether the file has unsaved changes.
  final bool isDirty;
  
  /// Version number for optimistic concurrency control.
  final int version;
  
  EditorViewState copyWith({
    String? filePath,
    String? content,
    CursorPosition? cursorPosition,
    String? language,
    bool? isDirty,
    int? version,
  }) {
    return EditorViewState(
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      language: language ?? this.language,
      isDirty: isDirty ?? this.isDirty,
      version: version ?? this.version,
    );
  }
  
  /// Creates an [EditorViewState] from Rust bridge data.
  factory EditorViewState.fromRust(RustEditorViewState rust) {
    return EditorViewState(
      filePath: rust.filePath,
      content: rust.content,
      cursorPosition: CursorPosition.fromRust(rust.cursorPosition),
      language: rust.language,
      isDirty: rust.isDirty,
      version: rust.version,
    );
  }
  
  @override
  List<Object?> get props => [
    filePath,
    content,
    cursorPosition,
    language,
    isDirty,
    version,
  ];
}
```

### EditorPatch

Represents a change to be applied to editor content.

```dart
/// Represents a patch to apply to editor content.
final class EditorPatch extends Equatable {
  const EditorPatch({
    required this.filePath,
    required this.startOffset,
    required this.endOffset,
    required this.newText,
    required this.version,
  });
  
  /// The file to patch.
  final String filePath;
  
  /// Starting offset of the range to replace.
  final int startOffset;
  
  /// Ending offset of the range to replace.
  final int endOffset;
  
  /// The new text to insert.
  final String newText;
  
  /// Expected version for optimistic concurrency control.
  final int version;
  
  EditorPatch copyWith({
    String? filePath,
    int? startOffset,
    int? endOffset,
    String? newText,
    int? version,
  }) {
    return EditorPatch(
      filePath: filePath ?? this.filePath,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      newText: newText ?? this.newText,
      version: version ?? this.version,
    );
  }
  
  /// Converts to Rust bridge format.
  RustEditorPatch toRust() {
    return RustEditorPatch(
      filePath: filePath,
      startOffset: startOffset,
      endOffset: endOffset,
      newText: newText,
      version: version,
    );
  }
  
  @override
  List<Object?> get props => [
    filePath,
    startOffset,
    endOffset,
    newText,
    version,
  ];
}
```

### CursorPosition

Represents a cursor position in the editor.

```dart
/// Represents a cursor position in the editor.
final class CursorPosition extends Equatable {
  const CursorPosition({
    required this.line,
    required this.column,
    required this.offset,
  });
  
  /// Zero-based line number.
  final int line;
  
  /// Zero-based column number.
  final int column;
  
  /// Absolute character offset from start of file.
  final int offset;
  
  CursorPosition copyWith({
    int? line,
    int? column,
    int? offset,
  }) {
    return CursorPosition(
      line: line ?? this.line,
      column: column ?? this.column,
      offset: offset ?? this.offset,
    );
  }
  
  factory CursorPosition.fromRust(RustCursorPosition rust) {
    return CursorPosition(
      line: rust.line,
      column: rust.column,
      offset: rust.offset,
    );
  }
  
  RustCursorPosition toRust() {
    return RustCursorPosition(
      line: line,
      column: column,
      offset: offset,
    );
  }
  
  @override
  List<Object?> get props => [line, column, offset];
}
```

### LanguageServerLocation

Represents a location in a source file for language server operations.

```dart
/// Represents a location in a source file.
final class LanguageServerLocation extends Equatable {
  const LanguageServerLocation({
    required this.filePath,
    required this.line,
    required this.column,
  });
  
  /// The file path.
  final String filePath;
  
  /// Zero-based line number.
  final int line;
  
  /// Zero-based column number.
  final int column;
  
  LanguageServerLocation copyWith({
    String? filePath,
    int? line,
    int? column,
  }) {
    return LanguageServerLocation(
      filePath: filePath ?? this.filePath,
      line: line ?? this.line,
      column: column ?? this.column,
    );
  }
  
  RustLanguageServerLocation toRust() {
    return RustLanguageServerLocation(
      filePath: filePath,
      line: line,
      column: column,
    );
  }
  
  @override
  List<Object?> get props => [filePath, line, column];
}
```

### LanguageServerHover

Represents hover information from the language server.

```dart
/// Represents hover information from the language server.
final class LanguageServerHover extends Equatable {
  const LanguageServerHover({
    required this.contents,
    required this.range,
  });
  
  /// The hover contents (markdown formatted).
  final String contents;
  
  /// The range this hover applies to (optional).
  final LanguageServerRange? range;
  
  LanguageServerHover copyWith({
    String? contents,
    LanguageServerRange? range,
  }) {
    return LanguageServerHover(
      contents: contents ?? this.contents,
      range: range ?? this.range,
    );
  }
  
  factory LanguageServerHover.fromRust(RustLanguageServerHover rust) {
    return LanguageServerHover(
      contents: rust.contents,
      range: rust.range != null 
        ? LanguageServerRange.fromRust(rust.range!)
        : null,
    );
  }
  
  @override
  List<Object?> get props => [contents, range];
}
```

### EditorCoreException

Custom exception for editor core errors.

```dart
/// Exception thrown when editor core operations fail.
final class EditorCoreException implements Exception {
  const EditorCoreException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });
  
  /// Human-readable error message.
  final String message;
  
  /// The original error that caused this exception.
  final Object? originalError;
  
  /// Stack trace when the error occurred.
  final StackTrace? stackTrace;
  
  @override
  String toString() {
    final buffer = StringBuffer('EditorCoreException: $message');
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    return buffer.toString();
  }
}
```

## Error Handling

### Error Categories

1. **File Operation Errors**: File not found, permission denied, invalid path
2. **Bridge Communication Errors**: FFI call failures, serialization errors
3. **Version Conflict Errors**: Optimistic concurrency control failures
4. **Language Server Errors**: LSP request failures, timeout errors

### Error Handling Strategy

1. **Catch at Bridge Boundary**: All flutter_rust_bridge calls are wrapped in try-catch
2. **Convert to Typed Exceptions**: Raw errors are converted to `EditorCoreException` with context
3. **Preserve Original Error**: Original error and stack trace are included for debugging
4. **Descriptive Messages**: Error messages include operation context (e.g., file path)

### Example Error Flow

```dart
// In RustEditorCoreClient
@override
Future<EditorViewState> applyPatch(EditorPatch patch) async {
  try {
    final rustPatch = patch.toRust();
    final result = await _bridge.applyPatch(patch: rustPatch);
    return EditorViewState.fromRust(result);
  } on FfiException catch (e, stackTrace) {
    throw EditorCoreException(
      message: 'Failed to apply patch to ${patch.filePath}',
      originalError: e,
      stackTrace: stackTrace,
    );
  } on VersionConflictException catch (e, stackTrace) {
    throw EditorCoreException(
      message: 'Version conflict when applying patch to ${patch.filePath}. '
               'Expected version ${patch.version}',
      originalError: e,
      stackTrace: stackTrace,
    );
  } catch (e, stackTrace) {
    throw EditorCoreException(
      message: 'Unexpected error applying patch to ${patch.filePath}',
      originalError: e,
      stackTrace: stackTrace,
    );
  }
}
```

## Testing Strategy

### Unit Testing Approach

Since this feature is primarily about package structure, interface definition, and integration with flutter_rust_bridge, the testing strategy focuses on:

1. **Mock-based Unit Tests**: Test `RustEditorCoreClient` with mocked flutter_rust_bridge
   - Verify correct method calls to bridge
   - Verify data conversion (Dart ↔ Rust)
   - Verify error handling and exception throwing

2. **Model Tests**: Test data model classes
   - Verify `copyWith` methods work correctly
   - Verify `Equatable` comparison works correctly
   - Verify `fromRust` and `toRust` conversion methods

3. **Integration Tests**: Test with real Rust backend (if available)
   - Verify end-to-end file operations
   - Verify language server features work correctly

### Test Structure

```dart
// Example unit test for RustEditorCoreClient
class MockRustBridge extends Mock implements RustBridge {}

void main() {
  group('RustEditorCoreClient', () {
    late MockRustBridge mockBridge;
    late RustEditorCoreClient client;
    
    setUp(() {
      mockBridge = MockRustBridge();
      client = RustEditorCoreClient(mockBridge);
    });
    
    group('openFile', () {
      test('should call bridge.openFile and convert result', () async {
        // Arrange
        final rustResult = RustEditorViewState(/* ... */);
        when(() => mockBridge.openFile(filePath: any(named: 'filePath')))
          .thenAnswer((_) async => rustResult);
        
        // Act
        final result = await client.openFile('/path/to/file.dart');
        
        // Assert
        verify(() => mockBridge.openFile(filePath: '/path/to/file.dart'))
          .called(1);
        expect(result.filePath, '/path/to/file.dart');
      });
      
      test('should throw EditorCoreException on bridge error', () async {
        // Arrange
        when(() => mockBridge.openFile(filePath: any(named: 'filePath')))
          .thenThrow(FfiException('File not found'));
        
        // Act & Assert
        expect(
          () => client.openFile('/path/to/file.dart'),
          throwsA(isA<EditorCoreException>()
            .having((e) => e.message, 'message', contains('Failed to open file'))
            .having((e) => e.originalError, 'originalError', isA<FfiException>())),
        );
      });
    });
    
    // More tests...
  });
}
```

### Why Property-Based Testing Is Not Applicable

Property-based testing (PBT) is not appropriate for this feature because:

1. **Infrastructure Code**: This feature is about creating package structure and wiring components together, not implementing algorithms with universal properties
2. **External Dependencies**: The core functionality depends on flutter_rust_bridge and Rust backend behavior, which are external to our code
3. **No Universal Properties**: There are no meaningful "for all inputs X, property P(X) holds" statements we can make about package structure or FFI calls
4. **Configuration Validation**: The requirements are about correct setup and integration, better tested with example-based tests and integration tests

Instead, we use:
- **Mock-based unit tests** to verify correct interaction with flutter_rust_bridge
- **Example-based tests** to verify specific scenarios (file operations, error cases)
- **Integration tests** to verify end-to-end functionality with real Rust backend

### Test Coverage Goals

- 100% coverage of `EditorCoreClient` interface methods
- 100% coverage of error handling paths in `RustEditorCoreClient`
- 100% coverage of model class methods (`copyWith`, `fromRust`, `toRust`)
- Integration tests for all major user workflows

## Dependencies

### Package Dependencies

```yaml
# packages/editor_core/pubspec.yaml
name: editor_core
description: Core editor functionality and Rust backend communication
version: 1.0.0
publish_to: none

environment:
  sdk: ^3.11.3

dependencies:
  flutter:
    sdk: flutter
  equatable: ^2.0.5
  flutter_rust_bridge: ^2.0.0  # Version to be determined based on Rust setup
  meta: ^1.9.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.1
  very_good_analysis: ^10.2.0
```

### Main Application Integration

```yaml
# Main application pubspec.yaml
dependencies:
  editor_core:
    path: packages/editor_core
```

### Dependency Rationale

- **flutter_rust_bridge**: Required for FFI communication with Rust backend
- **equatable**: Provides value equality for model classes
- **meta**: Provides annotations like `@immutable`
- **mocktail**: For creating mocks in unit tests
- **very_good_analysis**: Enforces code quality standards

## Implementation Plan

### Phase 1: Package Structure Setup
1. Create `packages/editor_core/` directory structure
2. Create `pubspec.yaml` with dependencies
3. Create `analysis_options.yaml` with linting rules
4. Create `README.md` with basic documentation

### Phase 2: Model Classes
1. Implement `CursorPosition` model
2. Implement `LanguageServerLocation` model
3. Implement `LanguageServerHover` model
4. Implement `EditorViewState` model
5. Implement `EditorPatch` model
6. Implement `EditorCoreException`

### Phase 3: Interface and Implementation
1. Define `EditorCoreClient` interface
2. Implement `RustEditorCoreClient` (initially with stub/mock bridge)
3. Add conversion methods (`fromRust`, `toRust`) to models

### Phase 4: Testing
1. Write unit tests for model classes
2. Write unit tests for `RustEditorCoreClient` with mocked bridge
3. Write integration tests (when Rust backend is available)

### Phase 5: Main Application Integration
1. Add `editor_core` dependency to main application
2. Update imports in main application to use new package
3. Remove old code from main application
4. Verify all functionality works

### Phase 6: Documentation
1. Add dartdoc comments to all public APIs
2. Complete README.md with usage examples
3. Add migration guide for developers

## Migration Strategy

### Current State
- Editor functionality is scattered across `lib/features/editor_content/`
- No clear separation between UI and backend communication
- Models are tightly coupled with UI code

### Target State
- Clean `editor_core` package with well-defined interfaces
- Main application depends only on `EditorCoreClient` interface
- Models are reusable across different features

### Migration Steps

1. **Create Package in Parallel**: Build `editor_core` package without modifying existing code
2. **Gradual Integration**: Update one feature at a time to use new package
3. **Deprecation Period**: Mark old code as deprecated but keep it functional
4. **Final Cleanup**: Remove old code after all features are migrated

### Backward Compatibility

During migration:
- Old code continues to work
- New code uses `editor_core` package
- Both can coexist temporarily
- No breaking changes to public APIs

## Security Considerations

1. **Input Validation**: File paths should be validated before passing to Rust backend
2. **Error Information**: Error messages should not expose sensitive system information
3. **Resource Limits**: Consider adding limits on file size, content length
4. **Path Traversal**: Validate file paths to prevent directory traversal attacks

## Performance Considerations

1. **Async Operations**: All operations are async to avoid blocking UI thread
2. **Data Copying**: Minimize data copying between Dart and Rust
3. **Caching**: Consider caching frequently accessed data (future enhancement)
4. **Batch Operations**: Consider adding batch APIs for multiple operations (future enhancement)

## Future Enhancements

1. **Streaming APIs**: For large file operations
2. **Cancellation Support**: Allow cancelling long-running operations
3. **Progress Reporting**: For operations that take significant time
4. **Offline Mode**: Cache data for offline editing
5. **Multi-file Operations**: Batch operations across multiple files

