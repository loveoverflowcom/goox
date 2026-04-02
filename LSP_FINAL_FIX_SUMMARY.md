# LSP Final Fix Summary

## Issues Fixed

### 1. ✅ LSP Executable Command
**Problem**: Dart language server cần args `language-server --protocol=lsp` nhưng config chỉ có `"dart"`

**Fix**: Updated `lsp_executable` to include full command with args
```json
{
  "lsp_executable": "dart language-server --protocol=lsp"
}
```

**How it works**: Rust code parses `lsp_executable` by splitting on whitespace:
- First part: executable name (`dart`)
- Remaining parts: arguments (`language-server --protocol=lsp`)
- If no args provided, default `--stdio` is used

### 2. ✅ Context Menu Always Visible
**Problem**: Menu items hidden when LSP not active

**Fix**: Changed condition to show items when extension has `languageId`
- Items visible but disabled when LSP not ready
- Items active when LSP ready
- Better UX: users know features exist

### 3. ✅ Hover Dialog Dismiss
**Problem**: Dialog follows mouse, doesn't dismiss when mouse leaves

**Fix**: Added outer MouseRegion to detect mouse outside tooltip area

## Root Causes Identified

### Why Go to Definition Doesn't Work

**Cause 1: Dart SDK Not Installed** (Most Common)
- User hasn't installed Dart SDK
- `dart` command not in PATH
- LSP server can't start

**Solution**: Install Dart SDK
```bash
brew install dart  # macOS
```

**Cause 2: Wrong LSP Command** (Fixed)
- Was: `"lsp_executable": "dart"`
- Now: `"lsp_executable": "dart language-server --protocol=lsp"`

**Cause 3: LSP Not Initialized Yet**
- LSP needs 2-3 seconds to start
- User clicks too quickly
- Status bar shows "inactive"

**Solution**: Wait for LSP to initialize, check status bar

### Why Hover Documentation Doesn't Show

**Same causes as Go to Definition**, plus:

**Cause 4: Hovering on Wrong Position**
- Must hover on symbol (class, function, variable)
- Not on whitespace, comments, strings

**Cause 5: Symbol Has No Documentation**
- Not all symbols have docs
- User-defined code may not have comments

## Testing Instructions

### Prerequisites
1. Install Dart SDK:
```bash
brew install dart
dart --version  # Verify installation
```

2. Copy extension to extensions directory:
```bash
cp -r dummy_extensions/dart ~/Library/Application\ Support/dev.goox.goox/extensions/
```

3. Restart Goox editor

### Test Go to Definition
1. Create test.dart:
```dart
import 'dart:io';

void main() {
  Directory dir = Directory('/tmp');
  print(dir.path);
}
```

2. Wait 2-3 seconds for LSP to initialize
3. Check status bar shows LSP indicator (not "inactive")
4. Right-click on "Directory" (line 1 or line 4)
5. Select "Go to Definition"
6. **Expected**: Jump to Directory class definition in Dart SDK

### Test Hover Documentation
1. Same test.dart file
2. Wait for LSP to initialize
3. Hover mouse over "Directory" (line 1)
4. Wait 300ms without moving mouse
5. **Expected**: Tooltip shows Directory class documentation

### Test Other LSP Features
- **Go to Declaration**: Right-click → "Go to Declaration"
- **Go to Implementation**: Right-click → "Go to Implementation"  
- **Find References**: Right-click → "Find References"

## Troubleshooting

### LSP Status Shows "inactive"
**Check**:
1. Dart SDK installed? `dart --version`
2. Extension loaded? Check Extensions view
3. File has .dart extension?
4. Wait 2-3 seconds after opening file

### Menu Items Are Disabled (Grayed Out)
**This is expected** when:
- LSP server is starting (wait a few seconds)
- Dart SDK not installed
- LSP server encountered error

**Check console** for error messages

### Go to Definition Does Nothing
**Possible causes**:
1. LSP not ready (check status bar)
2. Symbol not found (try built-in classes first)
3. Cursor not on symbol (click on symbol first)

### Hover Shows Nothing
**Possible causes**:
1. LSP not ready
2. Hovering on wrong position (try class names)
3. Symbol has no documentation
4. Not waiting long enough (wait 300ms)

## Files Modified

1. `dummy_extensions/dart/config.json`
   - Changed: `"lsp_executable": "dart language-server --protocol=lsp"`

2. `packages/goox_ui_shared/lib/src/editor/widgets/goox_editor_canvas.dart`
   - Context menu: Always show items for language extensions
   - Hover: Better dismiss behavior

3. Documentation:
   - `dummy_extensions/dart/README.md`
   - `dummy_extensions/LSP_SETUP_GUIDE.md`
   - `TROUBLESHOOTING_LSP.md`
   - `DEBUG_LSP_ISSUES.md`

## Next Steps

1. **Test with Dart SDK installed**
   - Verify all LSP features work
   - Test on real Dart projects

2. **Add More Language Extensions**
   - TypeScript: `typescript-language-server --stdio`
   - Python: `pyright-langserver --stdio`
   - Rust: `rust-analyzer`

3. **Improve Error Messages**
   - Show clear message when Dart SDK not found
   - Guide user to install SDK
   - Show LSP initialization progress

4. **Add LSP Status Indicator**
   - Show "Starting..." when initializing
   - Show "Ready" when active
   - Show "Error" with details when failed

## Summary

✅ Fixed LSP executable command for Dart
✅ Context menu items always visible
✅ Hover dialog dismisses properly
✅ Comprehensive documentation added
✅ Troubleshooting guides created

**Main requirement**: User must install Dart SDK for LSP features to work!
