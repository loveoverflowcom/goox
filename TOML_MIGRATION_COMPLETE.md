# TOML Migration & Dual-Mode Support - Complete Implementation

## Executive Summary

Successfully completed the migration from JSON to TOML configuration format for Goox extensions, along with full dual-mode support implementation. The system now supports three extension types (Language, Renderer, DualMode) with automatic classification and a complete UI for switching between editor and preview modes.

## Implementation Status: ✅ COMPLETE

### Core Features Implemented

1. **TOML Configuration Format** ✅
   - Single `extension.toml` file replaces `config.json` + `extension.json`
   - Cleaner syntax with comments support
   - Better LSP configuration with separate command and args
   - Backward compatible with JSON format

2. **Extension Type Classification** ✅
   - Automatic detection based on directory structure
   - Three types: Language, Renderer, DualMode
   - Exposed through Rust bridge to Dart/Flutter

3. **Dual-Mode UI** ✅
   - Editor/Preview toggle toolbar
   - Seamless mode switching with IndexedStack
   - Visual feedback for current mode
   - Only appears for dual-mode extensions

4. **Test Coverage** ✅
   - 23 Rust tests passing
   - 2 Dart tests passing
   - Flutter analyze: No issues found

## File Structure

### TOML Configuration Example

```toml
# extension.toml - Single unified configuration file

[extension]
id = "markdown-support"
name = "Markdown Support"
version = "1.0.0"
description = "Edit and preview Markdown files"
author = "Goox Team"
repository = "https://github.com/goox/extensions"
type = "dual-mode"  # Optional: language, renderer, or dual-mode

[extension.files]
types = ["md", "markdown"]

[language]  # Optional: for language support
id = "markdown"
lsp_command = "markdown-language-server"
lsp_args = ["--stdio"]

[webview]  # Optional: for rendering
entry = "webview/index.html"

[ui]
mode = "webview"
rendering = true

[protocol]
version = "erp/1"
capabilities = ["render.markdown"]
```

## Extension Types

### 1. Language Extension
**Characteristics**:
- Has `languages/` directory
- No `webview/` directory
- Provides syntax highlighting and LSP support

**Example**: Dart extension
```
dart/
├── extension.toml
└── languages/
    └── dart/
        ├── config.toml
        └── queries/
            └── highlights.scm
```

### 2. Renderer Extension
**Characteristics**:
- Has `webview/` directory
- No `languages/` directory
- Provides only rendering capability

**Example**: PDF Viewer
```
pdf-viewer/
├── extension.toml
└── webview/
    └── index.html
```

### 3. Dual-Mode Extension
**Characteristics**:
- Has both `languages/` and `webview/` directories
- Provides both editing and preview capabilities
- Shows Editor/Preview toggle in UI

**Example**: Markdown extension
```
markdown/
├── extension.toml
├── languages/
│   └── markdown/
│       ├── config.toml
│       └── queries/
│           └── highlights.scm
└── webview/
    └── index.html
```

## Dual-Mode UI Implementation

### Location
`apps/goox_desktop/lib/src/features/editor/views/editor_page.dart`

### Components

1. **_DualModeToolbar Widget**
   - Two buttons: Editor (code icon) and Preview (visibility icon)
   - Visual feedback for selected mode
   - Only visible for dual-mode extensions

2. **Mode State Management**
   - `_showPreview` boolean state
   - `_togglePreviewMode()` method for switching
   - Preserved across file switches

3. **Content Switching**
   - Uses `IndexedStack` for efficient switching
   - No content reload when switching modes
   - Preserves scroll position and state

### Code Example

```dart
// Toolbar appears for dual-mode extensions
if (activeExtension?.isDualMode == true)
  _DualModeToolbar(
    showPreview: _showPreview,
    onToggle: _togglePreviewMode,
  ),

// Content switches between modes
if (isDualMode) {
  return IndexedStack(
    index: _showPreview ? 1 : 0,
    children: [
      editorCanvas,   // Editor mode
      webviewPanel,   // Preview mode
    ],
  );
}
```

## Migration Path

### For Extension Developers

1. **Create extension.toml**
   ```bash
   touch extension.toml
   ```

2. **Copy configuration from JSON files**
   - Merge `config.json` and `extension.json` content
   - Restructure into TOML sections

3. **Update LSP configuration**
   ```toml
   # Old (JSON)
   "lsp_executable": "dart language-server --protocol=lsp"
   
   # New (TOML)
   [language]
   lsp_command = "dart"
   lsp_args = ["language-server", "--protocol=lsp"]
   ```

4. **Test extension loading**
   ```bash
   # Extension should load with TOML
   # JSON files can be kept for backward compatibility
   ```

### For Users

No action required! The system automatically:
- Tries TOML first
- Falls back to JSON if TOML not found
- Works with both formats seamlessly

## Technical Details

### Rust Implementation

**File**: `core/engine/src/extensions.rs`

**Key Functions**:
- `read_extension_toml()` - Parses TOML configuration
- `read_extension_json()` - Parses JSON configuration (fallback)
- `read_extension_config()` - Tries TOML first, then JSON
- `classify_extension_type()` - Determines extension type

**Structs**:
- `ExtensionToml` - TOML configuration structure
- `ExtensionMetadata` - Extension metadata
- `LanguageConfig` - Language support configuration
- `WebviewConfig` - Webview rendering configuration
- `UiConfig` - UI mode configuration
- `ProtocolConfig` - Protocol and capabilities

### Dart/Flutter Implementation

**Bridge**: `platform/flutter_bridge/lib/src/raw_bridge/extensions.dart`
- `ExtensionType` enum exposed to Dart
- `ExtensionInfo` includes `extensionType` field

**SDK**: `packages/goox_editor_sdk/lib/src/features/editor/models/editor_models.dart`
- `ActiveExtensionInfo` with `extensionType` field
- Helper methods: `isDualMode`, `isRendererOnly`, `hasWebViewCapability`

**UI**: `apps/goox_desktop/lib/src/features/editor/views/editor_page.dart`
- `_DualModeToolbar` widget
- `_showPreview` state management
- `_togglePreviewMode()` method

## Test Results

### Rust Tests (23 passing)
```
✅ loads_toml_extension_with_language_support
✅ loads_toml_extension_with_webview
✅ prefers_toml_over_json
✅ validates_extension_manifest_with_required_fields
✅ validates_queries_with_proper_structure
✅ rejects_manifest_with_empty_id
✅ rejects_manifest_with_empty_name
✅ rejects_manifest_with_invalid_version
✅ rejects_manifest_with_empty_file_types
✅ rejects_manifest_with_absolute_webview_path
✅ rejects_manifest_with_path_traversal
✅ rejects_queries_without_config_toml
✅ rejects_queries_without_queries_directory
✅ rejects_queries_without_scm_files
✅ accepts_extension_without_languages_directory
✅ workspace_overrides_global_by_name
✅ scans_metadata_only_language_extension
✅ loads_valid_textmate_grammar_reference
✅ rejects_absolute_textmate_grammar_path
✅ renderer_type_defaults_to_webview_mode
✅ activates_sample_flutter_webview_extension
✅ host_functions_are_callable
✅ tracks_loaded_extensions
```

### Dart Tests (2 passing)
```
✅ ActiveExtensionInfo exposes dual-mode preview capability
✅ ActiveExtensionInfo.empty defaults to language mode
```

### Flutter Analysis
```
✅ No issues found!
```

## Dummy Extensions Updated

All dummy extensions now have TOML configuration:

1. **dart** - Language extension with LSP support
2. **pdf-viewer-new** - Renderer extension for PDF files
3. **image-viewer** - Renderer extension for images
4. **markdown** - Dual-mode extension with editor and preview

## Documentation Created

1. `TOML_MIGRATION_GUIDE.md` - Complete migration guide
2. `TASK_6.3_DUAL_MODE_SUMMARY.md` - Task implementation summary
3. `TOML_MIGRATION_COMPLETE.md` - This document

## Benefits of TOML Format

### 1. Readability
- Comments for documentation
- Clear section structure
- Human-friendly syntax

### 2. Maintainability
- Single file instead of two
- Easier to understand and modify
- Better organization

### 3. Type Safety
- Better parsing with toml crate
- Clear error messages
- Validation at parse time

### 4. Flexibility
- Easy to add new sections
- Optional fields clearly marked
- Extensible structure

## Future Enhancements

### Potential Improvements
1. Add TOML schema validation
2. Create extension generator tool
3. Add hot-reload for TOML changes
4. Implement extension marketplace with TOML support
5. Add more extension types (e.g., hybrid, custom)

### Deprecation Path
1. Phase 1 (Current): Support both TOML and JSON
2. Phase 2 (Future): Mark JSON as deprecated
3. Phase 3 (Later): Remove JSON support (breaking change)

## Conclusion

The TOML migration and dual-mode support implementation is complete and fully functional. The system provides:

- ✅ Modern TOML configuration format
- ✅ Backward compatibility with JSON
- ✅ Automatic extension type classification
- ✅ Complete dual-mode UI implementation
- ✅ Comprehensive test coverage
- ✅ Clear migration path for developers
- ✅ No breaking changes for users

All dummy extensions have been updated, all tests pass, and the Flutter app analyzes without issues. The implementation is production-ready.

## Related Documents

- `TOML_MIGRATION_GUIDE.md` - Detailed migration instructions
- `TASK_6.3_DUAL_MODE_SUMMARY.md` - Task-specific summary
- `dummy_extensions/README.md` - Extension examples
- `.kiro/specs/editor-extension-enhancements/tasks.md` - Implementation tasks

## Contact

For questions or issues related to TOML migration or dual-mode support, please refer to the documentation or create an issue in the repository.
