# Dart Language Support Extension

Provides syntax highlighting and language server support for Dart files.

## Features

- Tree-sitter based syntax highlighting
- LSP integration for:
  - Go to Definition
  - Go to Declaration
  - Go to Implementation
  - Find References
  - Hover documentation
  - Code completion
  - Diagnostics

## Requirements

To use LSP features, you need to have Dart SDK installed:

### macOS
```bash
brew install dart
```

### Linux
```bash
sudo apt-get update
sudo apt-get install dart
```

### Windows
Download from: https://dart.dev/get-dart

## Configuration

The extension uses the Dart Analysis Server via the `dart` command with specific arguments:

```json
{
  "lsp_executable": "dart language-server --protocol=lsp"
}
```

**Important**: The `lsp_executable` field supports command-line arguments separated by spaces. The Dart language server requires:
- `language-server`: Subcommand to start the language server
- `--protocol=lsp`: Use LSP protocol (instead of legacy protocol)

If no arguments are provided, the default `--stdio` is used, which won't work for Dart.

## Verification

After installing Dart SDK, verify it's available:

```bash
dart --version
```

You should see output like:
```
Dart SDK version: 3.x.x
```

## Usage

1. Install Dart SDK (see Requirements)
2. Copy this extension to your extensions directory
3. Open a `.dart` file
4. Right-click to access LSP features:
   - Go to Definition
   - Go to Declaration
   - Go to Implementation
   - Find References
5. Hover over symbols to see documentation

## Troubleshooting

### LSP features not working

1. Check Dart SDK is installed: `dart --version`
2. Check extension is enabled in Extensions view
3. Check status bar shows LSP status (should not be "inactive")
4. Check console for LSP errors

### Syntax highlighting not working

1. Verify `languages/dart/queries/highlights.scm` exists
2. Check extension is properly loaded
3. Restart Goox editor

## File Structure

```
dart/
├── extension.json              # Extension metadata
├── config.json                 # Legacy config
├── README.md                   # This file
└── languages/
    └── dart/
        ├── config.toml         # Language configuration
        └── queries/
            └── highlights.scm  # Syntax highlighting queries
```

## Development

To modify syntax highlighting:

1. Edit `languages/dart/queries/highlights.scm`
2. Use Tree-sitter query syntax
3. Reload extension or restart editor

## License

MIT
