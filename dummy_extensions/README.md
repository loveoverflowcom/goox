# Goox Extensions

This directory contains sample extensions for the Goox editor following the new extension manifest format.

## Extension Types

### 1. Language Extensions
Extensions that provide syntax highlighting and language support only.

- **dart**: Dart language support with Tree-sitter syntax highlighting

### 2. Renderer Extensions
Extensions that provide webview-based rendering only.

- **pdf-viewer-new**: PDF document viewer using PDF.js
- **image-viewer**: Image viewer for PNG, JPG, GIF, SVG, WebP, etc.

### 3. Dual-Mode Extensions
Extensions that provide both language editing and preview capabilities.

- **markdown**: Markdown editor with live preview using marked.js

## Extension Structure

### TOML Format (Recommended)
```
extension/
├── extension.toml         # Main configuration (TOML format)
├── languages/             # Language support (optional)
│   └── <language>/
│       ├── config.toml
│       └── queries/
│           └── highlights.scm
└── webview/              # Webview rendering (optional)
    └── index.html
```

### Legacy JSON Format (Still Supported)
```
extension/
├── config.json           # Legacy configuration
├── extension.json        # Legacy manifest
├── languages/
└── webview/
```

### extension.toml Format

#### Language Extension Example (Dart)
```toml
[extension]
id = "dart-language-support"
name = "Dart Language Support"
version = "1.0.0"
description = "Syntax highlighting and language support for Dart"
author = "Goox Team"
repository = "https://github.com/goox/extensions"

[extension.files]
types = ["dart"]

[language]
id = "dart"
lsp_command = "dart"
lsp_args = ["language-server", "--protocol=lsp"]

[ui]
mode = "none"
rendering = false

[protocol]
version = "erp/1"
capabilities = []
```

#### Renderer Extension Example (PDF Viewer)
```toml
[extension]
id = "pdf-viewer"
name = "PDF Viewer"
version = "1.0.0"
type = "renderer"

[extension.files]
types = ["pdf"]

[webview]
entry = "webview/index.html"

[ui]
mode = "webview"
rendering = true

[protocol]
version = "erp/1"
capabilities = ["render.pdf"]
```

#### Dual-Mode Extension Example (Markdown)
```toml
[extension]
id = "markdown-support"
name = "Markdown Support"
version = "1.0.0"

[extension.files]
types = ["md", "markdown"]

[language]
id = "markdown"

[webview]
entry = "webview/index.html"

[ui]
mode = "webview"
rendering = true
```

### extension.toml Fields

#### [extension] Section
- `id`: Unique extension identifier (required)
- `name`: Display name (required)
- `version`: Semver version, e.g., "1.0.0" (required)
- `description`: Short description (optional)
- `author`: Author name (optional)
- `repository`: Repository URL (optional)
- `type`: Extension type: "language", "renderer", or omit for auto-detect (optional)

#### [extension.files] Section
- `types`: Array of file extensions (required)

#### [language] Section (Optional)
- `id`: Language identifier for LSP (required if section present)
- `lsp_command`: LSP server executable (optional)
- `lsp_args`: Command line arguments array (optional)

#### [webview] Section (Optional)
- `entry`: Path to webview HTML file (required if section present)

#### [ui] Section (Optional)
- `mode`: UI mode: "none", "webview", "canvas" (optional, default: auto-detect)
- `rendering`: Boolean for rendering support (optional, default: false)

#### [protocol] Section (Optional)
- `version`: Protocol version (optional, default: "erp/1")
- `capabilities`: Array of capabilities (optional, default: [])

## Extension Classification

Extensions are automatically classified based on their structure:

1. **Language**: Has `languages/` directory only
2. **Renderer**: Has `webview/` directory or `webview_entry` only
3. **DualMode**: Has both `languages/` and `webview/`

## LSP Server Configuration

Language extensions can provide LSP (Language Server Protocol) support for advanced features:

### Features Provided by LSP
- Go to Definition
- Go to Declaration
- Go to Implementation
- Find References
- Hover documentation
- Code completion
- Diagnostics (errors/warnings)

### Configuration in extension.json
```json
{
  "lsp_server": {
    "command": "language-server-executable",
    "args": ["--stdio"],
    "initialization_options": {
      "option1": "value1"
    }
  }
}
```

### Configuration in config.json (Legacy)
```json
{
  "language_id": "dart",
  "lsp_executable": "dart"
}
```

### Common LSP Servers
- **Dart**: `dart language-server --protocol=lsp`
- **TypeScript**: `typescript-language-server --stdio`
- **Python**: `pyright-langserver --stdio`
- **Rust**: `rust-analyzer`
- **Go**: `gopls`

### Context Menu Behavior
- LSP menu items (Go to Definition, etc.) are always visible for language extensions
- Items are disabled (grayed out) when LSP server is not running
- Items become active when LSP server is ready
- This provides better UX by showing available features even before LSP starts

## Installation

Copy extension folders to:
- **Global**: `~/Library/Application Support/dev.goox.goox/extensions/` (macOS)
- **Workspace**: `<workspace>/.goox/extensions/`

## Usage

1. Open a file with a supported extension
2. For dual-mode extensions, use the Editor/Preview toggle in the toolbar
3. For renderer-only extensions, the webview opens automatically

## Development

### Creating a Language Extension
1. Create `extension.json` with metadata
2. Add `languages/<lang>/config.toml` with language configuration
3. Add `languages/<lang>/queries/highlights.scm` with Tree-sitter queries

### Creating a Renderer Extension
1. Create `extension.json` with `webview_entry`
2. Create `webview/index.html` with viewer implementation
3. Use `window.gooxAPI` to communicate with the editor

### Creating a Dual-Mode Extension
Combine both language and webview structures.
