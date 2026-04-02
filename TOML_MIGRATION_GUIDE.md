# Extension Configuration Migration Guide: JSON → TOML

## Overview

Goox extensions now use TOML format for configuration instead of JSON. TOML provides:
- Better readability with clear sections
- Comments support
- Type safety
- Consistent format with language configs

## Migration Steps

### 1. Create extension.toml

Replace `config.json` and `extension.json` with a single `extension.toml` file.

### 2. Language Extension Example

**Before (config.json + extension.json)**:
```json
// config.json
{
  "name": "dart",
  "filetypes": ["dart"],
  "language_id": "dart",
  "lsp_executable": "dart language-server --protocol=lsp",
  "ui_mode": "none",
  "protocol": "erp/1",
  "capabilities": [],
  "rendering": false
}

// extension.json
{
  "id": "dart-language-support",
  "name": "Dart Language Support",
  "version": "1.0.0",
  "description": "Syntax highlighting and language support for Dart",
  "author": "Goox Team",
  "file_types": ["dart"]
}
```

**After (extension.toml)**:
```toml
[extension]
id = "dart-language-support"
name = "Dart Language Support"
version = "1.0.0"
description = "Syntax highlighting and language support for Dart"
author = "Goox Team"

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

### 3. Renderer Extension Example

**Before**:
```json
// config.json
{
  "name": "pdf-viewer",
  "type": "renderer",
  "filetypes": ["pdf"],
  "web_entry": "webview/index.html",
  "ui_mode": "webview",
  "rendering": true
}
```

**After**:
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
```

### 4. Dual-Mode Extension Example

**Before**:
```json
{
  "name": "markdown",
  "filetypes": ["md", "markdown"],
  "language_id": "markdown",
  "web_entry": "webview/index.html",
  "ui_mode": "webview",
  "rendering": true
}
```

**After**:
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

## Field Mapping

### Extension Metadata
| JSON (old) | TOML (new) | Section |
|------------|------------|---------|
| N/A | `id` | `[extension]` |
| `name` | `name` | `[extension]` |
| N/A | `version` | `[extension]` |
| N/A | `description` | `[extension]` |
| N/A | `author` | `[extension]` |
| `type` | `type` | `[extension]` |
| `filetypes` | `types` | `[extension.files]` |

### Language Support
| JSON (old) | TOML (new) | Section |
|------------|------------|---------|
| `language_id` | `id` | `[language]` |
| `lsp_executable` | `lsp_command` + `lsp_args` | `[language]` |

**Important**: `lsp_executable` is now split into:
- `lsp_command`: The executable name
- `lsp_args`: Array of arguments

Example:
```toml
[language]
lsp_command = "dart"
lsp_args = ["language-server", "--protocol=lsp"]
```

### Webview
| JSON (old) | TOML (new) | Section |
|------------|------------|---------|
| `web_entry` | `entry` | `[webview]` |

### UI Configuration
| JSON (old) | TOML (new) | Section |
|------------|------------|---------|
| `ui_mode` | `mode` | `[ui]` |
| `rendering` | `rendering` | `[ui]` |

### Protocol
| JSON (old) | TOML (new) | Section |
|------------|------------|---------|
| `protocol` | `version` | `[protocol]` |
| `capabilities` | `capabilities` | `[protocol]` |

## Benefits of TOML

### 1. Clear Structure
```toml
# TOML - Clear sections
[extension]
name = "My Extension"

[language]
id = "mylang"

[webview]
entry = "index.html"
```

vs

```json
// JSON - Flat structure
{
  "name": "My Extension",
  "language_id": "mylang",
  "web_entry": "index.html"
}
```

### 2. Comments Support
```toml
# This is a comment explaining the configuration
[language]
id = "dart"
# LSP server requires specific arguments
lsp_command = "dart"
lsp_args = ["language-server", "--protocol=lsp"]
```

### 3. Arrays Are Clearer
```toml
# TOML
[extension.files]
types = ["dart", "dart2"]

[language]
lsp_args = ["language-server", "--protocol=lsp"]

[protocol]
capabilities = ["render.pdf", "document.read"]
```

vs

```json
// JSON
{
  "filetypes": ["dart", "dart2"],
  "capabilities": ["render.pdf", "document.read"]
}
```

### 4. Type Safety
TOML has better type distinction:
- Strings: `name = "value"`
- Booleans: `rendering = true`
- Numbers: `version = 1`
- Arrays: `types = ["a", "b"]`

## Backward Compatibility

The system still supports JSON format:
- `config.json` - Legacy configuration
- `extension.json` - Legacy manifest

Priority order:
1. `extension.toml` (if exists)
2. `config.json` (fallback)

You can keep both formats during migration.

## Migration Checklist

- [ ] Create `extension.toml` in extension root
- [ ] Copy metadata from `extension.json` to `[extension]` section
- [ ] Copy file types to `[extension.files]` section
- [ ] Move language config to `[language]` section
- [ ] Split `lsp_executable` into `lsp_command` and `lsp_args`
- [ ] Move webview config to `[webview]` section
- [ ] Move UI config to `[ui]` section
- [ ] Move protocol config to `[protocol]` section
- [ ] Test extension loads correctly
- [ ] (Optional) Remove old JSON files

## Testing

After migration:

1. Copy extension to extensions directory
2. Restart Goox
3. Open Extensions view
4. Verify extension appears
5. Open a file with extension's file type
6. Verify features work (syntax highlighting, LSP, webview)

## Common Issues

### Issue: Extension not loading
**Check**: File name must be exactly `extension.toml`

### Issue: LSP not working
**Check**: Split `lsp_executable` correctly:
```toml
# Wrong
lsp_executable = "dart language-server --protocol=lsp"

# Correct
lsp_command = "dart"
lsp_args = ["language-server", "--protocol=lsp"]
```

### Issue: Webview not showing
**Check**: Path is relative to extension root:
```toml
[webview]
entry = "webview/index.html"  # Correct
# Not: entry = "/webview/index.html"
```

## Examples

See `dummy_extensions/` for complete examples:
- `dart/extension.toml` - Language extension
- `pdf-viewer-new/extension.toml` - Renderer extension
- `markdown/extension.toml` - Dual-mode extension
- `image-viewer/extension.toml` - Renderer extension
