# Fixes and New Extensions Summary

## Issues Fixed

### 1. Hover Dialog Dismiss Behavior ✅

**Problem**: Hover documentation dialog follows the mouse and doesn't dismiss when mouse moves outside.

**Solution**: 
- Added outer `MouseRegion` with `Positioned.fill` to detect mouse movement outside tooltip area
- Calculate tooltip bounds and dismiss when mouse exits the area
- Added border to tooltip for better visibility
- Changed `suppressUntilMove` to `false` on exit to allow immediate re-hover

**File Modified**: `packages/goox_ui_shared/lib/src/editor/widgets/goox_editor_canvas.dart`

**Changes**:
- Wrapped hover tooltip in `Positioned.fill` + `MouseRegion`
- Added bounds checking logic
- Improved visual styling with border

### 2. LSP Actions Context Menu ✅

**Problem**: LSP actions (Go to Definition, Declaration, etc.) and hover documentation are hidden when extension doesn't have LSP server configured.

**Root Cause**: 
- Context menu items were only shown when `lspStatus != 'inactive'`
- New extensions without LSP configuration had status 'inactive'
- This completely hid the menu items, giving no indication they exist

**Solution**:
- Changed condition from `lspStatus != 'inactive'` to check if extension has `languageId`
- Menu items now always visible for language extensions
- Items are disabled (grayed out) when LSP not ready
- Items become active when LSP server starts
- Better UX: users can see available features even before LSP starts

**Files Modified**:
- `packages/goox_ui_shared/lib/src/editor/widgets/goox_editor_canvas.dart`
- `dummy_extensions/dart/config.json` - Added `lsp_executable`
- `dummy_extensions/dart/extension.json` - Added `lsp_server` configuration

**Changes**:
```dart
// Before: Items completely hidden
if (widget.state.lspStatus != 'inactive') ...

// After: Items visible but disabled when LSP not ready
final hasLanguageSupport = widget.state.activeExtension?.languageId != null;
final lspReady = widget.state.lspStatus != 'inactive';

if (hasLanguageSupport) ...[
  ContextMenuButtonItem(
    onPressed: lspReady ? () { ... } : null,  // Disabled when not ready
    label: 'Go to Definition',
  ),
  ...
]
```

### 3. New Extensions Created ✅

Created 4 new extensions following the new manifest format:

#### a. Dart Language Extension (Language-only)
- **Path**: `dummy_extensions/dart/`
- **Type**: Language
- **Features**:
  - Tree-sitter syntax highlighting
  - Dart-specific queries (keywords, types, functions, etc.)
  - Bracket matching and auto-close
  - Comment support (line and block)
  - LSP server integration (requires Dart SDK)
  - Go to Definition/Declaration/Implementation
  - Find References
  - Hover documentation
  - Code completion
  - Diagnostics

#### b. PDF Viewer Extension (Renderer-only)
- **Path**: `dummy_extensions/pdf-viewer-new/`
- **Type**: Renderer
- **Features**:
  - PDF.js integration for rendering
  - Page navigation (previous/next)
  - Page counter display
  - Responsive canvas rendering

#### c. Image Viewer Extension (Renderer-only)
- **Path**: `dummy_extensions/image-viewer/`
- **Type**: Renderer
- **Features**:
  - Support for PNG, JPG, GIF, SVG, WebP, BMP, ICO
  - Zoom in/out controls
  - Reset zoom
  - Pixelated rendering toggle
  - Image dimensions display

#### d. Markdown Extension (Dual-mode)
- **Path**: `dummy_extensions/markdown/`
- **Type**: DualMode
- **Features**:
  - Syntax highlighting in editor mode
  - Live preview using marked.js
  - GitHub-style markdown rendering
  - Support for GFM (GitHub Flavored Markdown)
  - Auto-update on file changes

## Extension Manifest Format

### New Format (extension.json)
```json
{
  "id": "extension-id",
  "name": "Extension Name",
  "version": "1.0.0",
  "description": "Description",
  "author": "Author Name",
  "repository": "https://github.com/...",
  "file_types": ["ext1", "ext2"],
  "webview_entry": "webview/index.html",
  "lsp_server": {
    "command": "language-server",
    "args": ["--stdio"],
    "initialization_options": {}
  }
}
```

### Legacy Format (config.json)
Still supported for backward compatibility:
```json
{
  "name": "extension-name",
  "type": "renderer",
  "filetypes": ["ext"],
  "language_id": "language",
  "lsp_executable": "language-server",
  "web_entry": "webview/index.html",
  "ui_mode": "webview",
  "protocol": "erp/1",
  "capabilities": [],
  "rendering": true
}
```

## Extension Structure

```
extension/
├── extension.json          # New manifest
├── config.json            # Legacy manifest (compatibility)
├── languages/             # Language support (optional)
│   └── <language>/
│       ├── config.toml    # Language configuration
│       └── queries/
│           └── highlights.scm  # Tree-sitter queries
└── webview/              # Webview rendering (optional)
    └── index.html        # Webview entry point
```

## Extension Classification

Extensions are automatically classified based on directory structure:

1. **Language**: Has `languages/` directory only
   - Example: dart

2. **Renderer**: Has `webview/` directory or `webview_entry` only
   - Examples: pdf-viewer-new, image-viewer

3. **DualMode**: Has both `languages/` and `webview/`
   - Example: markdown

## Installation

Copy extension folders to:
- **Global**: `~/Library/Application Support/dev.goox.goox/extensions/` (macOS)
- **Workspace**: `<workspace>/.goox/extensions/`

## Testing

1. Copy extensions to global or workspace extensions directory
2. Restart Goox or refresh extensions
3. Open files with supported extensions:
   - `.dart` files → Dart syntax highlighting + LSP features (requires Dart SDK)
   - `.pdf` files → PDF viewer
   - `.png`, `.jpg`, etc. → Image viewer
   - `.md` files → Markdown editor with preview toggle

### Testing LSP Features

For Dart extension:
1. Install Dart SDK: `brew install dart` (macOS)
2. Verify: `dart --version`
3. Open a `.dart` file
4. Right-click to see LSP menu items:
   - Items should be visible (even if disabled initially)
   - Items become active when LSP server starts
   - Hover over code to see documentation
5. Check status bar for LSP status indicator

## Next Steps

1. ✅ **Hover Dialog**: Fixed dismiss behavior
2. ✅ **LSP Actions**: Fixed visibility and disabled state
3. ✅ **Extensions**: Created 4 new extensions with proper LSP configuration
4. **Documentation**: Update user guide with LSP setup instructions
5. **Testing**: Comprehensive testing with real Dart projects
