# Implementation Plan: Editor Core Package Extraction

## Overview

This plan outlines the implementation steps for extracting editor core functionality into a standalone Dart package. The package will provide a clean interface for communicating with the Rust-based language server backend through flutter_rust_bridge, enabling better code organization and reusability.

## Tasks

- [x] 1. Set up package structure and configuration
  - Create packages/editor_core/ directory with standard Dart package structure
  - Create pubspec.yaml with dependencies (flutter_rust_bridge, equatable, meta)
  - Create analysis_options.yaml with linting rules
  - Create README.md with basic package description
  - Create lib/ directory and lib/src/ subdirectories (client/, models/, exceptions/)
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 6.1, 6.2, 6.3, 6.4, 10.1_

- [ ] 2. Implement model classes
  - [x] 2.1 Implement CursorPosition model
    - Create lib/src/models/cursor_position.dart
    - Implement immutable class with line, column, offset fields
    - Add copyWith method
    - Implement Equatable for value comparison
    - Add fromRust and toRust conversion methods
    - Add dartdoc comments
    - _Requirements: 4.3, 4.6, 4.7, 8.3_
  
  - [ ]* 2.2 Write unit tests for CursorPosition
    - Test copyWith method
    - Test Equatable comparison
    - Test fromRust and toRust conversions
    - _Requirements: 4.3, 4.6, 4.7_
  
  - [x] 2.3 Implement LanguageServerLocation model
    - Create lib/src/models/language_server_location.dart
    - Implement immutable class with filePath, line, column fields
    - Add copyWith method
    - Implement Equatable for value comparison
    - Add toRust conversion method
    - Add dartdoc comments
    - _Requirements: 4.4, 4.6, 4.7, 8.3_
  
  - [ ]* 2.4 Write unit tests for LanguageServerLocation
    - Test copyWith method
    - Test Equatable comparison
    - Test toRust conversion
    - _Requirements: 4.4, 4.6, 4.7_
  
  - [x] 2.5 Implement LanguageServerHover model
    - Create lib/src/models/language_server_hover.dart
    - Implement immutable class with contents and range fields
    - Add copyWith method
    - Implement Equatable for value comparison
    - Add fromRust conversion method
    - Add dartdoc comments
    - _Requirements: 4.5, 4.6, 4.7, 8.3_
  
  - [ ]* 2.6 Write unit tests for LanguageServerHover
    - Test copyWith method
    - Test Equatable comparison
    - Test fromRust conversion with nullable range
    - _Requirements: 4.5, 4.6, 4.7_
  
  - [x] 2.7 Implement EditorPatch model
    - Create lib/src/models/editor_patch.dart
    - Implement immutable class with filePath, startOffset, endOffset, newText, version fields
    - Add copyWith method
    - Implement Equatable for value comparison
    - Add toRust conversion method
    - Add dartdoc comments
    - _Requirements: 4.2, 4.6, 4.7, 8.3_
  
  - [ ]* 2.8 Write unit tests for EditorPatch
    - Test copyWith method
    - Test Equatable comparison
    - Test toRust conversion
    - _Requirements: 4.2, 4.6, 4.7_
  
  - [x] 2.9 Implement EditorViewState model
    - Create lib/src/models/editor_view_state.dart
    - Implement immutable class with filePath, content, cursorPosition, language, isDirty, version fields
    - Add copyWith method
    - Implement Equatable for value comparison
    - Add fromRust conversion method
    - Add dartdoc comments
    - _Requirements: 4.1, 4.6, 4.7, 8.3_
  
  - [ ]* 2.10 Write unit tests for EditorViewState
    - Test copyWith method
    - Test Equatable comparison
    - Test fromRust conversion with nested CursorPosition
    - _Requirements: 4.1, 4.6, 4.7_

- [ ] 3. Implement exception classes
  - [x] 3.1 Implement EditorCoreException
    - Create lib/src/exceptions/editor_core_exception.dart
    - Implement exception class with message, originalError, stackTrace fields
    - Override toString method for descriptive error messages
    - Add dartdoc comments
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  
  - [ ]* 3.2 Write unit tests for EditorCoreException
    - Test toString method with various field combinations
    - Test exception creation and field access
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Define EditorCoreClient interface
  - [x] 5.1 Create EditorCoreClient interface
    - Create lib/src/client/editor_core_client.dart
    - Define abstract interface class with all editor operations
    - Add methods: openFile, applyPatch, getViewState, closeFile, getHover, getDiagnostics, dispose
    - Add comprehensive dartdoc comments for all methods
    - Document exceptions thrown by each method
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 8.2_

- [ ] 6. Implement RustEditorCoreClient
  - [x] 6.1 Create RustEditorCoreClient implementation
    - Create lib/src/client/rust_editor_core_client.dart
    - Implement EditorCoreClient interface
    - Add constructor accepting RustBridge instance
    - Implement openFile method with error handling
    - Implement applyPatch method with error handling
    - Implement getViewState method with error handling
    - Implement closeFile method with error handling
    - Implement getHover method with error handling and null return
    - Implement getDiagnostics method with error handling
    - Implement dispose method
    - Wrap all flutter_rust_bridge calls in try-catch blocks
    - Convert Rust errors to EditorCoreException with descriptive messages
    - Add dartdoc comments
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 7.1_
  
  - [ ]* 6.2 Write unit tests for RustEditorCoreClient with mocked bridge
    - Create mock RustBridge using mocktail
    - Test openFile success case - verify bridge call and result conversion
    - Test openFile error case - verify EditorCoreException is thrown
    - Test applyPatch success case - verify bridge call with converted patch
    - Test applyPatch error case - verify EditorCoreException with file path in message
    - Test getViewState success and error cases
    - Test closeFile success and error cases
    - Test getHover success case with hover data
    - Test getHover success case returning null
    - Test getHover error case
    - Test getDiagnostics success and error cases
    - Test dispose method
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 7.1_

- [ ] 7. Create package public API exports
  - [x] 7.1 Create main library file
    - Create lib/editor_core.dart
    - Export EditorCoreClient interface
    - Export RustEditorCoreClient implementation
    - Export all model classes (EditorViewState, EditorPatch, CursorPosition, LanguageServerLocation, LanguageServerHover)
    - Export EditorCoreException
    - Do NOT export internal implementation details from lib/src/
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 4.8_

- [x] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Write package documentation
  - [x] 9.1 Complete README.md
    - Add package overview and purpose
    - Add installation instructions with path dependency example
    - Add basic usage example showing RustEditorCoreClient creation
    - Add example showing how to use EditorCoreClient interface
    - Add example showing model class usage
    - Add section on error handling
    - _Requirements: 8.1, 8.4, 8.5_

- [ ] 10. Integrate package with main application
  - [x] 10.1 Add editor_core dependency to main application
    - Update main application's pubspec.yaml
    - Add editor_core as path dependency pointing to packages/editor_core
    - Run flutter pub get
    - _Requirements: 6.5, 9.1_
  
  - [x] 10.2 Update main application imports
    - Replace old imports with editor_core package imports
    - Update code to use EditorCoreClient interface
    - Update code to use model classes from editor_core package
    - Verify no import errors
    - _Requirements: 9.1, 9.2, 9.3, 9.4_
  
  - [ ]* 10.3 Write integration tests
    - Test creating RustEditorCoreClient in main application context
    - Test using EditorCoreClient through dependency injection
    - Test end-to-end file operations if Rust backend is available
    - _Requirements: 9.2, 9.3, 9.4_

- [x] 11. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- The package uses mock-based unit tests since this is infrastructure code
- Integration tests require Rust backend to be available
- All model classes follow immutable pattern with copyWith methods
- Error handling wraps all flutter_rust_bridge calls with descriptive EditorCoreException
