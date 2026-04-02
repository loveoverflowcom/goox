# LSP Setup Guide for Goox Extensions

This guide explains how to set up Language Server Protocol (LSP) support for your extensions.

## What is LSP?

LSP (Language Server Protocol) provides advanced IDE features:
- Go to Definition/Declaration/Implementation
- Find References
- Hover documentation
- Code completion
- Real-time diagnostics (errors/warnings)
- Rename refactoring

## Quick Start

### 1. Install Language Server

Each language needs its own language server installed:

#### Dart
```bash
# macOS
brew install dart

# Verify
dart --version
```

#### TypeScript/JavaScript
```bash
npm install -g typescript-language-server typescript
```

#### Python
```bash
pip install pyright
```

#### Rust
```bash
rustup component add rust-analyzer
```

#### Go
```bash
go install golang.org/x/tools/gopls@latest
```

### 2. Configure Extension

Add LSP configuration to your extension:

#### extension.json (New Format)
```json
{
  "id": "my-language",
  "name": "My Language Support",
  "version": "1.0.0",
  "file_types": ["mylang"],
  "lsp_server": {
    "command": "my-language-server",
    "args": ["--stdio"],
    "initialization_options": {
      "option1": "value1"
    }
  }
}
```

#### config.json (Legacy Format)
```json
{
  "name": "my-language",
  "filetypes": ["mylang"],
  "language_id": "mylang",
  "lsp_executable": "my-language-server"
}
```

### 3. Test LSP Features

1. Open a file with your extension
2. Right-click in editor
3. You should see LSP menu items:
   - Go to Definition
   - Go to Declaration
   - Go to Implementation
   - Find References
4. Items will be:
   - Visible but grayed out (disabled) when LSP is starting
   - Active (clickable) when LSP is ready
5. Hover over code to see documentation
6. Check status bar for LSP status

## Common LSP Server Configurations

### Dart
```json
{
  "lsp_server": {
    "command": "dart",
    "args": ["language-server", "--protocol=lsp"]
  }
}
```

**Legacy config.json**:
```json
{
  "language_id": "dart",
  "lsp_executable": "dart language-server --protocol=lsp"
}
```

**Note**: In `config.json`, the `lsp_executable` field supports command-line arguments separated by spaces.

### TypeScript
```json
{
  "lsp_server": {
    "command": "typescript-language-server",
    "args": ["--stdio"]
  }
}
```

### Python (Pyright)
```json
{
  "lsp_server": {
    "command": "pyright-langserver",
    "args": ["--stdio"]
  }
}
```

### Rust
```json
{
  "lsp_server": {
    "command": "rust-analyzer"
  }
}
```

### Go
```json
{
  "lsp_server": {
    "command": "gopls"
  }
}
```

## UI Behavior

### Context Menu
- LSP menu items are **always visible** for language extensions
- Items show as **disabled (grayed out)** when:
  - LSP server is not installed
  - LSP server is starting
  - LSP server encountered an error
- Items become **active** when LSP server is ready
- This provides better UX by showing what features are available

### Status Bar
- Shows LSP status indicator when active
- Click to see more details
- Possible states:
  - No indicator: LSP not configured
  - Gray icon: LSP starting
  - Green icon: LSP ready
  - Red icon: LSP error

### Hover Documentation
- Hover over code to see documentation
- Requires LSP server to be running
- Shows type information, function signatures, etc.
- Dismiss by moving mouse away from tooltip

## Troubleshooting

### LSP menu items are disabled

**Check 1: Is language server installed?**
```bash
# Test the command directly
dart --version
typescript-language-server --version
pyright --version
```

**Check 2: Is extension configured correctly?**
- Verify `lsp_server.command` or `lsp_executable` is set
- Check command matches installed executable name
- Verify `language_id` is set (for config.json)

**Check 3: Check console for errors**
- Open developer console
- Look for LSP-related errors
- Common issues:
  - Command not found
  - Permission denied
  - Invalid arguments

### Hover documentation not showing

**Check 1: LSP server running?**
- Look for LSP status in status bar
- Should show green icon when ready

**Check 2: Hover over valid symbol?**
- Try hovering over a function name
- Try hovering over a variable
- Some positions may not have documentation

**Check 3: Wait for LSP to initialize**
- LSP server needs time to analyze code
- Wait a few seconds after opening file
- Large projects take longer to index

### LSP features slow or unresponsive

**Solution 1: Restart LSP server**
- Close and reopen the file
- Or restart Goox editor

**Solution 2: Check system resources**
- LSP servers can be memory-intensive
- Close other applications
- Consider upgrading RAM

**Solution 3: Optimize project**
- Exclude large directories from analysis
- Use .gitignore to skip generated files
- Configure LSP server options

## Advanced Configuration

### Custom Initialization Options

Some LSP servers accept custom options:

```json
{
  "lsp_server": {
    "command": "typescript-language-server",
    "args": ["--stdio"],
    "initialization_options": {
      "preferences": {
        "includeInlayParameterNameHints": "all",
        "includeInlayFunctionParameterTypeHints": true
      }
    }
  }
}
```

### Environment Variables

Set environment variables for LSP server:

```json
{
  "lsp_server": {
    "command": "my-language-server",
    "args": ["--stdio"],
    "env": {
      "MY_VAR": "value"
    }
  }
}
```

### Working Directory

Specify working directory for LSP server:

```json
{
  "lsp_server": {
    "command": "my-language-server",
    "args": ["--stdio"],
    "cwd": "${workspaceFolder}"
  }
}
```

## Best Practices

1. **Always provide LSP configuration** for language extensions
2. **Document requirements** in extension README
3. **Test without LSP** to ensure basic features work
4. **Provide fallbacks** for when LSP is not available
5. **Handle errors gracefully** when LSP fails to start
6. **Show clear status** to users about LSP state

## Resources

- [LSP Specification](https://microsoft.github.io/language-server-protocol/)
- [Language Server Index](https://langserver.org/)
- [Dart Analysis Server](https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server)
- [TypeScript Language Server](https://github.com/typescript-language-server/typescript-language-server)
- [Pyright](https://github.com/microsoft/pyright)
- [rust-analyzer](https://rust-analyzer.github.io/)
- [gopls](https://github.com/golang/tools/tree/master/gopls)
