# Task 6.3: Dual-Mode Support & TOML Migration - Implementation Summary

## Overview
Successfully completed the TOML migration for extension configuration and verified dual-mode extension support. The system now uses TOML as the primary configuration format with JSON fallback for backward compatibility.

## What Was Accomplished

### 1. TOML Configuration Format
- ✅ Added `toml = "0.8"` dependency to `core/engine/Cargo.toml`
- ✅ Created TOML parsing structs: `ExtensionToml`, `ExtensionMetadata`, `LanguageConfig`, `WebviewConfig`, `UiConfig`, `ProtocolConfig`, `FilesConfig`
- ✅ Implemented `read_extension_toml()` function to parse TOML format
- ✅ Modified `read_extension_config()` to try TOML first, then fall back to JSON
- ✅ All code compiles successfully

### 2. Extension Type Classification
- ✅ `ExtensionType` enum already implemented with three variants:
  - `Language`: Extensions with only language support (syntax highlighting, LSP)
  - `Renderer`: Extensions with only webview rendering
  - `DualMode`: Extensions with both language support and webview rendering
- ✅ `classify_extension_type()` function determines type based on directory structure:
  - Checks for `languages/` directory → indicates language support
  - Checks for `webview/` directory or `webview_entry` → indicates rendering capability
- ✅ `extension_type` field added to `ExtensionMeta` and `ExtensionInfo` structs
- ✅ Extension type is automatically classified during extension loading

### 3. TOML Format Features
**Single unified file** (`extension.toml`) replaces both `config.json` and `extension.json`:

```toml
[extension]
id = "extension-id"
name = "Extension Name"
version = "1.0.0"
description = "Description"
author = "Author Name"
repository = "https://github.com/..."
type = "renderer"  # Optional: language, renderer, or dual-mode

[extension.files]
types = ["ext1", "ext2"]

[language]  # Optional section for language support
id = "language-id"
lsp_command = "language-server"
lsp_args = ["--arg1", "--arg2"]

[webview]  # Optional section for webview rendering
entry = "webview/index.html"

[ui]
mode = "webview"  # none, canvas, webview, native
rendering = true

[protocol]
version = "erp/1"
capabilities = ["capability1", "capability2"]
```

**Key improvements over JSON:**
- Comments supported for documentation
- Cleaner LSP configuration with separate `lsp_command` and `lsp_args` array
- Clear section structure with `[extension]`, `[language]`, `[webview]`, etc.
- Type-safe parsing with better error messages

### 4. Dummy Extensions Updated
Created TOML configuration for all dummy extensions:

1. **dart** (`dummy_extensions/dart/extension.toml`)
   - Type: Language
   - LSP: `dart language-server --protocol=lsp`
   - File types: `.dart`

2. **pdf-viewer-new** (`dummy_extensions/pdf-viewer-new/extension.toml`)
   - Type: Renderer
   - Webview: `webview/index.html`
   - File types: `.pdf`

3. **image-viewer** (`dummy_extensions/image-viewer/extension.toml`)
   - Type: Renderer
   - Webview: `webview/index.html`
   - File types: `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.webp`, `.bmp`, `.ico`

4. **markdown** (`dummy_extensions/markdown/extension.toml`)
   - Type: DualMode
   - Language: markdown
   - Webview: `webview/index.html`
   - File types: `.md`, `.markdown`

### 5. Testing
Added comprehensive tests to verify TOML functionality:

- ✅ `loads_toml_extension_with_language_support` - Tests language-only extension
- ✅ `loads_toml_extension_with_webview` - Tests dual-mode extension with webview
- ✅ `prefers_toml_over_json` - Verifies TOML takes priority when both exist
- ✅ All 23 extension tests pass

### 6. Backward Compatibility
- ✅ JSON format (`config.json` + `extension.json`) still supported
- ✅ System tries TOML first, falls back to JSON if TOML not found
- ✅ Existing extensions continue to work without modification

## File Changes

### Modified Files
1. `core/engine/Cargo.toml` - Added toml dependency
2. `core/engine/src/extensions.rs` - Added TOML parsing logic and tests

### Created Files
1. `dummy_extensions/dart/extension.toml`
2. `dummy_extensions/pdf-viewer-new/extension.toml`
3. `dummy_extensions/image-viewer/extension.toml`
4. `dummy_extensions/markdown/extension.toml`
5. `TOML_MIGRATION_GUIDE.md` - Complete migration documentation
6. `TASK_6.3_DUAL_MODE_SUMMARY.md` - This summary

### Updated Files
1. `dummy_extensions/README.md` - Updated with TOML examples

## Extension Type Classification Logic

The system automatically classifies extensions based on their directory structure:

```rust
pub fn classify_extension_type(extension_path: &Path, webview_entry: Option<&str>) -> ExtensionType {
    let has_languages = extension_path.join("languages").is_dir();
    let has_webview = extension_path.join("webview").is_dir() || webview_entry.is_some();
    
    match (has_languages, has_webview) {
        (true, true) => ExtensionType::DualMode,
        (true, false) => ExtensionType::Language,
        (false, true) => ExtensionType::Renderer,
        (false, false) => ExtensionType::Language, // Default
    }
}
```

## Next Steps

### Recommended Actions
1. ✅ Test TOML parsing with actual extension loading in the Flutter app
2. ✅ Verify all dummy extensions load correctly with TOML format
3. Update documentation to reflect TOML as primary format
4. Consider deprecating JSON format in future versions
5. Add validation for TOML parsing errors with helpful error messages

### For Dual-Mode UI Implementation (Task 6.3 continuation)
The extension type classification is complete. The next step is to implement the UI for dual-mode switching:

1. Add mode switching UI with "Preview" button in editor toolbar
2. Implement mode state management (editor vs preview)
3. Preserve scroll position and cursor location when switching modes
4. Handle file content synchronization between modes

### 6. Dual-Mode UI Implementation
The dual-mode UI is already fully implemented in the Flutter app:

**Location**: `apps/goox_desktop/lib/src/features/editor/views/editor_page.dart`

**Features**:
- ✅ `_DualModeToolbar` widget with Editor/Preview toggle buttons
- ✅ `_showPreview` state management for mode switching
- ✅ `IndexedStack` for efficient mode switching without rebuilding
- ✅ Automatic toolbar display when `activeExtension?.isDualMode == true`
- ✅ Icon-based buttons (code icon for Editor, visibility icon for Preview)
- ✅ Visual feedback for selected mode

**Implementation Details**:
```dart
// Dual-mode toolbar appears when extension supports both modes
if (activeExtension?.isDualMode == true)
  _DualModeToolbar(
    showPreview: _showPreview,
    onToggle: _togglePreviewMode,
  ),

// Content switches between editor and preview using IndexedStack
if (activeExtension != null && isDualMode) {
  return IndexedStack(
    index: _showPreview ? 1 : 0,
    children: [
      editorContent,  // Editor mode
      webviewContent, // Preview mode
    ],
  );
}
```

**User Experience**:
- Seamless switching between editor and preview modes
- No content reload when switching (IndexedStack preserves state)
- Clear visual indication of current mode
- Only appears for dual-mode extensions (markdown, etc.)

## Testing Results

All tests pass successfully:

### Rust Tests (23 tests)
```
running 23 tests
test extensions::tests::accepts_extension_without_languages_directory ... ok
test extensions::tests::activates_sample_flutter_webview_extension ... ok
test extensions::tests::host_functions_are_callable ... ok
test extensions::tests::loads_toml_extension_with_language_support ... ok
test extensions::tests::loads_toml_extension_with_webview ... ok
test extensions::tests::loads_valid_textmate_grammar_reference ... ok
test extensions::tests::prefers_toml_over_json ... ok
test extensions::tests::rejects_absolute_textmate_grammar_path ... ok
test extensions::tests::rejects_manifest_with_absolute_webview_path ... ok
test extensions::tests::rejects_manifest_with_empty_file_types ... ok
test extensions::tests::rejects_manifest_with_empty_id ... ok
test extensions::tests::rejects_manifest_with_empty_name ... ok
test extensions::tests::rejects_manifest_with_invalid_version ... ok
test extensions::tests::rejects_manifest_with_path_traversal ... ok
test extensions::tests::rejects_queries_without_config_toml ... ok
test extensions::tests::rejects_queries_without_queries_directory ... ok
test extensions::tests::rejects_queries_without_scm_files ... ok
test extensions::tests::renderer_type_defaults_to_webview_mode ... ok
test extensions::tests::scans_metadata_only_language_extension ... ok
test extensions::tests::validates_extension_manifest_with_required_fields ... ok
test extensions::tests::validates_queries_with_proper_structure ... ok
test extensions::tests::workspace_overrides_global_by_name ... ok
test wasm_runtime::tests::tracks_loaded_extensions ... ok

test result: ok. 23 passed; 0 failed; 0 ignored; 0 measured; 18 filtered out
```

### Dart Tests (2 tests)
```
00:01 +2: All tests passed!
```

Tests verify:
- ✅ TOML parsing for language-only extensions
- ✅ TOML parsing for dual-mode extensions with webview
- ✅ TOML takes priority over JSON when both exist
- ✅ Extension type classification (Language, Renderer, DualMode)
- ✅ Dual-mode capability detection in Dart
- ✅ ActiveExtensionInfo exposes dual-mode preview capability

## Migration Path for Existing Extensions

For extension developers:

1. Create `extension.toml` in extension root directory
2. Copy configuration from `config.json` and `extension.json`
3. Restructure into TOML sections
4. Split LSP command into `lsp_command` and `lsp_args`
5. Test extension loading
6. Optionally remove JSON files (or keep for backward compatibility)

See `TOML_MIGRATION_GUIDE.md` for detailed migration instructions.

## Conclusion

The TOML migration is complete and fully functional. The system now:
- Supports modern TOML configuration format
- Maintains backward compatibility with JSON
- Automatically classifies extension types
- Has comprehensive test coverage
- Provides clear migration path for existing extensions

All dummy extensions have been updated to use TOML format, and the system correctly loads and classifies them based on their capabilities.
