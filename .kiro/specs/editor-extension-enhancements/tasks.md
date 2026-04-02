# Implementation Plan: Editor Extension Enhancements

## Overview

This implementation plan restructures the Goox Desktop editor extension system to use Tree-sitter for syntax highlighting and support a flexible extension architecture. The implementation is split across three main packages: `goox_editor_sdk` (Dart), `goox_flutter_bridge` (Rust), and `goox_desktop` (Flutter UI).

The plan follows a phased approach: Tree-sitter foundation → Language configuration & highlighting → WASM runtime → Webview integration → Markdown & fonts → Theme support & hot reload → Testing & polish.

## Tasks

- [x] 1. Set up Tree-sitter integration foundation
  - [x] 1.1 Add Tree-sitter Dart FFI bindings to goox_editor_sdk
    - Create FFI wrapper for Tree-sitter C library
    - Add tree-sitter dependency to pubspec.yaml
    - Set up native library loading for different platforms
    - _Requirements: 2.1, 5.1_
  
  - [x] 1.2 Implement TreeSitterParser class
    - Create `packages/goox_editor_sdk/lib/src/syntax/tree_sitter_parser.dart`
    - Implement loadGrammar, parse, updateTree, and query methods
    - Add SyntaxTree, Node, and Edit data classes
    - _Requirements: 2.1, 5.1, 5.4_
  
  - [ ]* 1.3 Write property test for Tree-sitter parsing
    - **Property 2: Valid Query Parsing**
    - **Validates: Requirements 2.1, 2.2**
  
  - [x] 1.4 Implement QueryParser for .scm files
    - Create `packages/goox_editor_sdk/lib/src/syntax/query_parser.dart`
    - Implement parse, validate, and execute methods
    - Add Query, QueryMatch, and Predicate data classes
    - Support all query file types: highlights.scm, brackets.scm, indents.scm, outline.scm, injections.scm
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [ ]* 1.5 Write property test for query round-trip preservation
    - **Property 1: Tree-sitter Query Round-Trip Preservation**
    - **Validates: Requirements 2.8, 3.1, 3.2, 3.4**
  
  - [ ]* 1.6 Write property test for capture name recognition
    - **Property 3: Capture Name Recognition**
    - **Validates: Requirements 2.3**
  
  - [ ]* 1.7 Write property test for predicate evaluation
    - **Property 4: Predicate Evaluation**
    - **Validates: Requirements 2.4**
  
  - [x] 1.8 Add extension manifest validation to Rust ExtensionManager
    - Update `platform/flutter_bridge/src/extension_manager.rs`
    - Implement validate_manifest and validate_queries methods
    - Add ExtensionManifest struct with id, name, version, description, author, repository, file_types, webview_entry fields
    - _Requirements: 1.1, 1.2, 1.3, 1.7, 7.1, 7.2_
  
  - [ ]* 1.9 Write property test for extension manifest validation
    - **Property 6: Extension Manifest Validation**
    - **Validates: Requirements 1.1, 7.2, 7.3**
  
  - [ ]* 1.10 Write property test for invalid query error handling
    - **Property 5: Invalid Query Error Handling**
    - **Validates: Requirements 2.6, 7.6**

- [x] 2. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Implement language configuration and syntax highlighting
  - [x] 3.1 Implement LanguageConfigParser
    - Create `packages/goox_editor_sdk/lib/src/syntax/language_config_parser.dart`
    - Parse config.toml files with name, grammar, path_suffixes, line_comments, block_comment, brackets, autoclose_before fields
    - Add LanguageConfig and BracketPair data classes
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_
  
  - [x] 3.2 Implement TreeSitterHighlighter
    - Create `packages/goox_editor_sdk/lib/src/syntax/tree_sitter_highlighter.dart`
    - Implement highlight and updateHighlighting methods
    - Add HighlightSpan and ThemeColorMap data classes
    - Map Tree-sitter captures to theme colors
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_
  
  - [ ]* 3.3 Write property test for syntax highlighting application
    - **Property 8: Syntax Highlighting Application**
    - **Validates: Requirements 5.1, 5.4**
  
  - [ ]* 3.4 Write property test for theme-aware color mapping
    - **Property 10: Theme-Aware Color Mapping**
    - **Validates: Requirements 11.1, 11.6**
  
  - [x] 3.5 Integrate TreeSitterHighlighter with GooxEditorCanvas
    - Update `apps/goox_desktop/lib/src/features/editor/widgets/goox_editor_canvas.dart`
    - Replace hardcoded highlighting with Tree-sitter based highlighting
    - Apply HighlightSpans to text rendering
    - _Requirements: 5.1, 5.4_
  
  - [x] 3.6 Implement incremental parsing and highlighting
    - Update TreeSitterParser to support incremental updates
    - Implement caching for parse trees and highlighting results
    - Only re-highlight affected regions on edits
    - _Requirements: 5.5, 5.6, 8.1, 8.3, 8.4_
  
  - [ ]* 3.7 Write property test for incremental highlighting
    - **Property 28: Incremental Highlighting**
    - **Validates: Requirements 8.1**
  
  - [ ]* 3.8 Write property test for highlighting cache utilization
    - **Property 29: Highlighting Cache Utilization**
    - **Validates: Requirements 8.3**

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Implement WASM runtime and extension logic
  - [x] 5.1 Add WASM runtime dependency to Rust bridge
    - Add wasmer or wasmtime crate to `platform/flutter_bridge/Cargo.toml`
    - Set up WASM module loading infrastructure
    - _Requirements: 14.1_
  
  - [x] 5.2 Implement WasmRuntime in Rust
    - Create `platform/flutter_bridge/src/wasm_runtime.rs`
    - Implement load_module, call_function, send_event, and set_limits methods
    - Add WasmInstance struct with instance, memory, and exports fields
    - Define ExtensionEvent enum for file operations
    - _Requirements: 14.1, 14.2, 14.3, 14.6_
  
  - [x] 5.3 Define host functions for WASM modules
    - Implement send_notification, read_file, and update_ui host functions
    - Set up secure communication channel between Dart and WASM
    - _Requirements: 14.2, 14.3, 14.7_
  
  - [x] 5.4 Implement message passing between Dart and WASM
    - Create Dart-side API for sending events to WASM
    - Handle WASM responses and UI updates
    - _Requirements: 14.3, 14.5_
  
  - [x] 5.5 Add resource limits and security controls
    - Enforce memory and CPU time limits for WASM execution
    - Implement sandboxed API access
    - _Requirements: 14.6_
  
  - [ ]* 5.6 Write unit tests for WASM execution
    - Test WASM module loading and initialization
    - Test event handling and message passing
    - Test resource limit enforcement
    - _Requirements: 14.1, 14.4, 14.6_

- [-] 6. Implement webview integration
  - [x] 6.1 Implement WebviewPanel widget
    - Create `apps/goox_desktop/lib/src/features/editor/widgets/webview_panel.dart`
    - Set up WebViewController for extension webviews
    - Implement _initializeWebview, _sendMessage, _handleMessage, and updateContent methods
    - _Requirements: 15.1, 15.2, 15.3, 15.6_
  
  - [x] 6.2 Set up webview-to-editor message passing API
    - Define WebviewMessage data class
    - Implement JavaScript API for webview extensions (gooxAPI)
    - Handle file content requests and UI updates
    - _Requirements: 15.3, 15.4_
  
  - [x] 6.3 Implement dual-mode support (editor + preview)
    - Add extension type classification in ExtensionManager
    - Implement mode switching UI with "Preview" button
    - Preserve scroll position and cursor location when switching modes
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6_
  
  - [~] 6.4 Add webview sandboxing and security controls
    - Restrict file system access to extension directory only
    - Implement secure message passing with origin validation
    - _Requirements: 15.5_
  
  - [~] 6.5 Implement file content synchronization
    - Pass file content to webview on file open
    - Send file change events to webview
    - Handle save requests from webview
    - _Requirements: 15.6_
  
  - [ ]* 6.6 Write integration tests for webview extensions
    - Test webview loading and rendering
    - Test message passing between editor and webview
    - Test dual-mode switching
    - _Requirements: 13.3, 13.4, 13.5, 15.1, 15.3_

- [~] 7. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Implement markdown rendering and font management
  - [~] 8.1 Implement MarkdownRenderer
    - Create `packages/goox_editor_sdk/lib/src/markdown/markdown_renderer.dart`
    - Implement render, renderCodeBlock, and renderInlineCode methods
    - Support bold, italic, code blocks, inline code, and links
    - Add MarkdownNode data class with type, text, children, and attributes fields
    - _Requirements: 6.1, 6.2, 6.3_
  
  - [ ]* 8.2 Write property test for markdown feature support
    - **Property 14: Markdown Feature Support**
    - **Validates: Requirements 6.2, 6.3**
  
  - [~] 8.3 Integrate markdown renderer with hover tooltips
    - Update LSP hover response handling in EditorController
    - Render markdown content in documentation tooltips
    - Handle plain text fallback for non-markdown content
    - _Requirements: 6.1, 6.7_
  
  - [ ]* 8.4 Write property test for markdown rendering
    - **Property 17: Markdown Rendering**
    - **Validates: Requirements 6.1**
  
  - [~] 8.5 Add Tree-sitter syntax highlighting for code blocks
    - Integrate TreeSitterHighlighter with MarkdownRenderer
    - Apply syntax highlighting to fenced code blocks with language tags
    - Use monospace font for all code blocks
    - _Requirements: 6.4, 6.5_
  
  - [ ]* 8.6 Write property test for code block highlighting
    - **Property 16: Language-Tagged Code Block Highlighting**
    - **Validates: Requirements 6.5**
  
  - [~] 8.7 Implement tooltip size adjustment
    - Auto-adjust tooltip width and height based on content
    - Ensure readable contrast in both light and dark themes
    - _Requirements: 6.6, 6.8_
  
  - [~] 8.8 Implement FontManager
    - Create `packages/goox_editor_sdk/lib/src/fonts/font_manager.dart`
    - Implement fetchAvailableFonts, downloadFont, isFontCached, loadCachedFont, and getCachedFonts methods
    - Add FontInfo data class with family, availableWeights, category, and isMonospace fields
    - _Requirements: 8.1, 8.3, 8.4, 8.5, 8.6_
  
  - [ ]* 8.9 Write property test for Google Fonts API integration
    - **Property 22: Google Fonts API Integration**
    - **Validates: Requirements 8.1**
  
  - [ ]* 8.10 Write property test for font download and caching
    - **Property 24: Font Download and Caching**
    - **Validates: Requirements 8.3, 8.4**
  
  - [~] 8.11 Extend AppSettings with fontFamily field
    - Update `apps/goox_desktop/lib/src/state/app_settings.dart`
    - Add fontFamily field with default value 'monospace'
    - Update copyWith, toJson, and fromJson methods
    - _Requirements: 7.1, 7.2_
  
  - [ ]* 8.12 Write property test for font family persistence
    - **Property 19: Font Family Persistence**
    - **Validates: Requirements 7.2**
  
  - [~] 8.13 Implement font selection UI in SettingsView
    - Update `apps/goox_desktop/lib/src/features/widgets/settings_view.dart`
    - Add font family dropdown with search functionality
    - Display font preview with sample text
    - Show available Google Fonts with download option
    - _Requirements: 7.5, 8.2_
  
  - [ ]* 8.14 Write property test for font family application
    - **Property 20: Font Family Application**
    - **Validates: Requirements 7.3**

- [ ] 9. Implement theme support and hot reload
  - [~] 9.1 Implement ThemeManager
    - Create `packages/goox_editor_sdk/lib/src/theme/theme_manager.dart`
    - Implement registerTheme, getAvailableThemes, loadTheme, and validateTheme methods
    - Add ExtensionTheme, ThemeVariant, and ThemeInfo data classes
    - _Requirements: 16.1, 16.2, 16.3, 16.4_
  
  - [~] 9.2 Add theme.json parsing and validation
    - Parse theme.json files from extensions
    - Support light and dark variants
    - Map Tree-sitter captures to colors
    - _Requirements: 16.1, 16.2, 16.5_
  
  - [~] 9.3 Implement WCAG contrast validation
    - Validate theme colors meet WCAG AA requirements (4.5:1 contrast)
    - Reject themes that don't meet accessibility standards
    - _Requirements: 11.6, 16.7_
  
  - [~] 9.4 Implement file watching in Rust ExtensionManager
    - Add notify crate dependency
    - Implement watch_extension_files and handle_query_change methods
    - Detect changes to .scm query files
    - _Requirements: 12.1, 12.3_
  
  - [ ]* 9.5 Write property test for grammar file change detection
    - **Property 31: Grammar File Change Detection**
    - **Validates: Requirements 12.1, 12.3**
  
  - [~] 9.6 Add query reload logic with error handling
    - Reload queries when .scm files change
    - Keep previous valid queries on reload failure
    - Show error notification on failure
    - _Requirements: 12.1, 12.4_
  
  - [~] 9.7 Implement extension enable/disable refresh
    - Refresh syntax highlighting for all open files when extension state changes
    - Re-apply highlighting with new queries after successful reload
    - _Requirements: 12.2, 12.5_
  
  - [ ]* 9.8 Write property test for extension state change refresh
    - **Property 32: Extension State Change Refresh**
    - **Validates: Requirements 12.2**
  
  - [~] 9.9 Implement theme change re-highlighting
    - Update all syntax colors immediately when theme changes
    - Support both light and dark theme variants
    - _Requirements: 11.2, 11.3_
  
  - [ ]* 9.10 Write property test for theme change re-highlighting
    - **Property 11: Theme Change Re-Highlighting**
    - **Validates: Requirements 11.2**

- [~] 10. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Testing, optimization, and polish
  - [~] 11.1 Implement QueryParser pretty printer
    - Add print method to QueryParser for formatting .scm files
    - Preserve semantic information and use consistent formatting
    - _Requirements: 3.1, 3.2, 3.3_
  
  - [~] 11.2 Add comprehensive error handling
    - Implement all error types from design document
    - Add descriptive error messages with context
    - Implement fallback behaviors for all error conditions
    - _Requirements: 2.6, 7.5, 7.6_
  
  - [~] 11.3 Performance optimization and profiling
    - Profile syntax highlighting performance with large files
    - Optimize incremental parsing and caching
    - Ensure 60 FPS scrolling with highlighting enabled
    - _Requirements: 8.1, 8.2, 8.4, 8.5_
  
  - [ ]* 11.4 Write property test for incremental re-highlighting on edit
    - **Property 30: Incremental Re-Highlighting on Edit**
    - **Validates: Requirements 8.4**
  
  - [ ]* 11.5 Write unit tests for example-based scenarios
    - Test grammar fallback on invalid file
    - Test plain text tooltip display
    - Test font fallback on unavailable font
    - Test common programming font support
    - Test font download failure handling
    - Test grammar reload failure handling
    - _Requirements: 1.5, 6.7, 7.4, 7.6, 8.5, 12.4_
  
  - [~] 11.6 Security audit
    - Review path traversal prevention in extension validation
    - Audit WASM sandboxing and resource limits
    - Review webview security and message passing
    - Validate query patterns for DoS prevention
    - _Requirements: 7.3, 14.6, 15.5_
  
  - [~] 11.7 Add logging and debugging support
    - Add detailed logging for extension loading and validation
    - Log performance metrics for highlighting and parsing
    - Add debug mode for extension developers
    - _Requirements: 7.5_
  
  - [ ]* 11.8 Write integration tests for end-to-end scenarios
    - Test extension installation and file opening with highlighting
    - Test theme switching and color updates
    - Test grammar hot reload
    - Test Google Font selection and application
    - Test markdown rendering in hover tooltips
    - _Requirements: 5.1, 6.1, 7.3, 8.3, 11.2, 12.1_

- [~] 12. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- Implementation follows phased approach: foundation → highlighting → WASM → webview → markdown/fonts → themes → polish
- Dart is used for goox_editor_sdk and goox_desktop packages
- Rust is used for goox_flutter_bridge platform code
- Tree-sitter replaces TextMate grammars for syntax highlighting
- Extensions support language editing, webview rendering, and dual-mode operation
