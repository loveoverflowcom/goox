# Terminal Integration Test Guide

## Manual Testing Steps

### Test 1: Basic Terminal Creation
1. Run: `flutter run`
2. Verify terminal panel appears at bottom
3. Type: `echo "Hello World"` and press Enter
4. Verify output is displayed

### Test 2: Multiple Terminals
1. Press `Ctrl+Shift+\`` to create new terminal
2. Verify second tab appears
3. Switch between tabs
4. Verify each terminal maintains its own session

### Test 3: Terminal Resize
1. Hover over top edge of terminal panel
2. Drag to resize
3. Verify terminal adjusts smoothly

### Test 4: Terminal Close
1. Click X on terminal tab
2. Verify terminal closes
3. Verify active terminal switches

### Test 5: Theme Integration
1. Verify terminal uses dark theme by default
2. If app has theme switcher, test light theme
3. Verify theme updates correctly

### Test 6: Keyboard Shortcuts
1. `Ctrl+Shift+\`` - Create new terminal
2. `Ctrl+C` - Interrupt command
3. `Ctrl+D` - Send EOF

## Expected Results
- All terminals work independently
- Theme matches app theme
- Keyboard shortcuts function correctly
- Resource cleanup on close
