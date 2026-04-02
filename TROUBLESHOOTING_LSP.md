# Troubleshooting LSP Issues

## Symptom 1: Go to Definition không hoạt động

### Check 1: Dart SDK installed?
```bash
dart --version
```

**Expected**: `Dart SDK version: 3.x.x`

**If not installed**:
```bash
# macOS
brew install dart

# Linux
sudo apt-get install dart

# Windows
# Download from https://dart.dev/get-dart
```

### Check 2: Extension config correct?
File: `dummy_extensions/dart/config.json`

Should have:
```json
{
  "language_id": "dart",
  "lsp_executable": "dart language-server --protocol=lsp"
}
```

**Important**: Must include `language-server --protocol=lsp` args!

### Check 3: Extension loaded?
1. Open Extensions view in Goox
2. Find "dart" extension
3. Verify it's enabled (not disabled)
4. If not found, copy extension to:
   - `~/Library/Application Support/dev.goox.goox/extensions/dart/`

### Check 4: LSP server running?
1. Open a `.dart` file
2. Check status bar (bottom)
3. Should see LSP indicator
4. If shows "inactive" or "error":
   - Check console for error messages
   - Verify Dart SDK is in PATH: `which dart`

### Check 5: Wait for initialization
- LSP needs 2-3 seconds to start
- Large projects need more time
- Status bar will show when ready

### Check 6: Test with simple code
Create test file:
```dart
import 'dart:io';

void main() {
  Directory dir = Directory('/tmp');
  print(dir.path);
}
```

1. Right-click on "Directory" (line 1)
2. Select "Go to Definition"
3. Should jump to Directory class

## Symptom 2: Hover documentation không hiển thị

### Check 1: LSP running?
Same as Symptom 1, Check 4

### Check 2: Hovering on valid symbol?
- Hover must be on class name, function name, variable
- NOT on whitespace, comments, or strings
- Try hovering on:
  - "Directory" in import
  - "print" function call
  - Variable names

### Check 3: Symbol has documentation?
- Not all symbols have documentation
- Try built-in classes first (Directory, File, String)
- User-defined symbols may not have docs

### Check 4: Hover timing
- Hover and wait 300ms
- Don't move mouse during wait
- Tooltip should appear

## Common Error Messages

### "dart: command not found"
**Solution**: Install Dart SDK (see Check 1)

### "LSP server failed to start"
**Possible causes**:
1. Wrong command in `lsp_executable`
2. Dart SDK not in PATH
3. Permission issues

**Solution**:
```bash
# Verify dart is in PATH
which dart

# Should output: /usr/local/bin/dart or similar

# If not found, add to PATH or reinstall Dart
```

### "LSP status: error"
**Check console logs** for specific error message

**Common causes**:
1. Invalid workspace root
2. File path issues
3. LSP server crashed

**Solution**: Restart editor and try again

## Testing Procedure

### Step 1: Verify Dart SDK
```bash
./dummy_extensions/dart/test_lsp.sh
```

Should output:
```
✓ Dart is installed
✓ Dart language server is available
✓ Test file created
```

### Step 2: Copy Extension
```bash
# Global installation
cp -r dummy_extensions/dart ~/Library/Application\ Support/dev.goox.goox/extensions/

# Or workspace installation
cp -r dummy_extensions/dart <your-workspace>/.goox/extensions/
```

### Step 3: Restart Goox
- Close Goox completely
- Reopen Goox
- Open workspace

### Step 4: Test LSP Features
1. Create test.dart:
```dart
import 'dart:io';

void main() {
  Directory dir = Directory('/tmp');
  print(dir.path);
}
```

2. Wait 2-3 seconds for LSP to initialize
3. Check status bar shows LSP indicator
4. Right-click on "Directory" → "Go to Definition"
5. Hover over "Directory" → Should see documentation

## Still Not Working?

### Enable Debug Logging
Add to your Dart extension config:
```json
{
  "lsp_executable": "dart language-server --protocol=lsp --verbose"
}
```

### Check Console Output
1. Open Developer Tools in Goox
2. Look for LSP-related messages
3. Look for errors starting with "LSP" or "dart"

### Manual Test LSP Server
Test Dart language server manually:
```bash
# Start server
dart language-server --protocol=lsp

# Should wait for input (LSP protocol)
# Press Ctrl+C to exit
```

If this fails, your Dart SDK installation has issues.

### Report Issue
If still not working after all checks:
1. Collect console logs
2. Note Dart SDK version
3. Note OS version
4. Describe exact steps to reproduce
5. Report to Goox team
