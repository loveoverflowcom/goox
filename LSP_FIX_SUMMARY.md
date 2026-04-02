# LSP Context Menu Fix Summary

## Problem
Khi mở file Dart với extension mới, các nút LSP actions (Go to Definition, Go to Declaration, etc.) và hover documentation bị ẩn hoàn toàn.

## Root Cause
1. Context menu items chỉ hiển thị khi `lspStatus != 'inactive'`
2. Extension mới không có LSP server configured → status = 'inactive'
3. Menu items bị ẩn hoàn toàn, user không biết có features gì

## Solution

### 1. Fixed Context Menu Logic
**File**: `packages/goox_ui_shared/lib/src/editor/widgets/goox_editor_canvas.dart`

**Before**:
```dart
if (widget.state.lspStatus != 'inactive') ...[
  // Menu items
]
```

**After**:
```dart
final hasLanguageSupport = widget.state.activeExtension?.languageId != null;
final lspReady = widget.state.lspStatus != 'inactive';

if (hasLanguageSupport) ...[
  ContextMenuButtonItem(
    onPressed: lspReady ? () { ... } : null,  // Disabled when not ready
    label: 'Go to Definition',
  ),
  // Other items...
]
```

**Result**:
- Menu items luôn hiển thị cho language extensions
- Items bị disable (grayed out) khi LSP chưa ready
- Items active khi LSP ready
- Better UX: user biết có features gì available

### 2. Added LSP Configuration to Dart Extension

**File**: `dummy_extensions/dart/config.json`
```json
{
  "language_id": "dart",
  "lsp_executable": "dart"
}
```

**File**: `dummy_extensions/dart/extension.json`
```json
{
  "lsp_server": {
    "command": "dart",
    "args": ["language-server", "--protocol=lsp"]
  }
}
```

### 3. Fixed Hover Dialog Dismiss
**File**: `packages/goox_ui_shared/lib/src/editor/widgets/goox_editor_canvas.dart`

- Added outer MouseRegion to detect mouse outside tooltip
- Tooltip tự động dismiss khi chuột ra ngoài
- Added border cho tooltip dễ nhìn hơn

## Testing

### Without Dart SDK
1. Open `.dart` file
2. Right-click → See LSP menu items (disabled/grayed out)
3. Hover → No documentation (LSP not running)
4. Status bar → No LSP indicator

### With Dart SDK
1. Install: `brew install dart`
2. Open `.dart` file
3. Right-click → See LSP menu items (active after LSP starts)
4. Hover → See documentation
5. Status bar → Shows LSP status

## Files Modified
1. `packages/goox_ui_shared/lib/src/editor/widgets/goox_editor_canvas.dart`
2. `dummy_extensions/dart/config.json`
3. `dummy_extensions/dart/extension.json`

## Documentation Added
1. `dummy_extensions/dart/README.md` - Dart extension guide
2. `dummy_extensions/LSP_SETUP_GUIDE.md` - LSP setup guide
3. `dummy_extensions/README.md` - Updated with LSP info

## Result
✅ LSP menu items luôn visible cho language extensions
✅ Items disabled khi LSP chưa ready, active khi ready
✅ Hover dialog dismiss properly
✅ Better UX với clear indication về LSP features
