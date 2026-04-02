# Debug LSP Issues

## Issue 1: Go to Definition không hoạt động

### Possible Causes

1. **Dart SDK chưa được cài đặt**
   - Check: `dart --version`
   - Install: `brew install dart` (macOS)

2. **LSP server không start được**
   - Check console logs
   - Look for error messages about "dart" command

3. **Extension config không đúng**
   - Verify `lsp_executable` field in config.json
   - Should be: `"lsp_executable": "dart"`

4. **LSP server chưa ready**
   - LSP cần thời gian để initialize
   - Wait 2-3 seconds sau khi mở file
   - Check status bar for LSP status

### Debug Steps

1. Run test script:
```bash
./dummy_extensions/dart/test_lsp.sh
```

2. Check extension is loaded:
   - Open Extensions view
   - Find "dart" extension
   - Verify it's enabled

3. Open a Dart file and check:
   - Status bar shows LSP indicator
   - Console shows LSP messages
   - Right-click menu items are active (not grayed out)

4. Test with simple Dart code:
```dart
import 'dart:io';

void main() {
  Directory dir = Directory('/tmp');
  print(dir.path);
}
```
   - Right-click on "Directory"
   - Select "Go to Definition"
   - Should jump to Directory class definition

## Issue 2: Hover documentation không hiển thị

### Possible Causes

1. **LSP server không running**
   - Same as Issue 1

2. **Hover position không đúng**
   - Hover phải đúng trên symbol (class name, function name, etc.)
   - Không phải whitespace hoặc comments

3. **LSP chưa analyze code**
   - Wait for LSP to finish initialization
   - Large projects need more time

### Debug Steps

1. Verify LSP is running:
   - Check status bar for green LSP indicator
   - Should not be "inactive"

2. Test hover on known symbols:
   - Hover over "Directory" in import statement
   - Hover over "print" function
   - Hover over variable names

3. Check console for hover requests:
   - Should see hover request/response logs
   - Look for errors

## Quick Fix Checklist

- [ ] Dart SDK installed: `dart --version`
- [ ] Extension loaded in Extensions view
- [ ] File opened with .dart extension
- [ ] LSP status in status bar (not "inactive")
- [ ] Wait 2-3 seconds for LSP initialization
- [ ] Try hover on simple symbols first
- [ ] Try Go to Definition on import statements
- [ ] Check console for errors

## Common Solutions

### Solution 1: Install Dart SDK
```bash
brew install dart
```

### Solution 2: Restart Editor
- Close Goox
- Reopen Goox
- Open Dart file again

### Solution 3: Reload Extension
- Go to Extensions view
- Find dart extension
- Click refresh/reload

### Solution 4: Check Extension Path
- Extension should be in:
  - Global: `~/Library/Application Support/dev.goox.goox/extensions/dart/`
  - Workspace: `<workspace>/.goox/extensions/dart/`
