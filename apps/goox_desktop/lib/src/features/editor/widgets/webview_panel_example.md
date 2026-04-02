# WebviewPanel Usage Example

## Overview

The `WebviewPanel` widget provides a simplified interface for displaying extension webviews with message passing capabilities between Flutter and the webview JavaScript.

## Quick Start

See the complete example template at: `apps/goox_desktop/assets/webview/extension_template.html`

For detailed API documentation, see: `goox_api_reference.md`

## Basic Usage

```dart
import 'package:goox_desktop/src/features/editor/widgets/webview_panel.dart';

// Create a WebviewPanel
WebviewPanel(
  extensionId: 'my-extension',
  htmlPath: '/path/to/extension/webview/index.html',
  fileContent: 'Initial file content',
  onMessage: (message) {
    // Handle messages from the webview
    print('Received message: ${message['type']}');
    
    // Handle custom message types
    if (message['type'] == 'save') {
      final content = message['content'] as String?;
      if (content != null) {
        // Save the content
      }
    }
  },
)
```

## Goox Extension API (gooxAPI)

The webview has access to `window.gooxAPI` with the following methods:

### Core Methods

- **`getFileContent()`**: Returns the current file content
- **`sendMessage(type, data)`**: Sends a message to the editor
- **`requestContent()`**: Requests the current file content
- **`requestSave(content)`**: Requests to save content
- **`ready()`**: Notifies editor that webview is ready

### Event Listeners

- **`onFileContent(callback)`**: Called when file content is received
- **`onFileUpdate(callback)`**: Called when file content changes
- **`onMessage(callback)`**: Called for any message from editor

## Features

### 1. Automatic Content Injection
When the webview loads, the panel automatically sends the file content to the webview:

```javascript
// In your webview JavaScript
window.gooxAPI.onFileContent(function(content, detail) {
  console.log('Received content:', content);
  console.log('Extension ID:', detail.extensionId);
});
```

### 2. Message Passing from Webview to Flutter

```javascript
// Send a custom message
window.gooxAPI.sendMessage('customAction', {
  action: 'highlight',
  line: 42
});

// Request to save content
window.gooxAPI.requestSave(modifiedContent);
```

### 3. Content Updates

The panel automatically updates the webview when the file content changes:

```dart
// The widget will automatically call updateContent when fileContent changes
WebviewPanel(
  extensionId: 'my-extension',
  htmlPath: '/path/to/extension/webview/index.html',
  fileContent: updatedContent, // Changes trigger updateContent
)
```

### 4. Built-in Message Types

The panel handles these message types automatically:

- `ready`: Sent by webview when it's ready to receive content
- `requestContent`: Sent by webview to request the current file content
- `fileContent`: Sent by Flutter to webview with file content
- `fileUpdate`: Sent by Flutter to webview when content changes

## Complete Example

```html
<!DOCTYPE html>
<html>
<head>
  <title>My Extension</title>
</head>
<body>
  <textarea id="editor"></textarea>
  <button onclick="save()">Save</button>

  <script>
    // Initialize
    window.gooxAPI.onFileContent(function(content) {
      document.getElementById('editor').value = content;
    });

    window.gooxAPI.onFileUpdate(function(content) {
      document.getElementById('editor').value = content;
    });

    function save() {
      const content = document.getElementById('editor').value;
      window.gooxAPI.requestSave(content);
    }

    document.addEventListener('DOMContentLoaded', function() {
      window.gooxAPI.ready();
    });
  </script>
</body>
</html>
```

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

- **15.1**: Loads and displays webview from extension HTML file
- **15.2**: Provides access to extension assets via file paths
- **15.3**: Implements message passing API between Flutter and webview
- **15.4**: Provides API for reading file content, receiving file change events, sending UI updates
- **15.6**: Passes file content to webview on load and updates

## Error Handling

The panel includes built-in error handling:

- Shows error UI if webview fails to load
- Displays loading indicator while webview initializes
- Gracefully handles message parsing errors

## Testing

Unit tests are provided for the message serialization:

```bash
flutter test test/widgets/webview_panel_test.dart
```

Note: Full widget tests require platform-specific webview implementation and are better suited for integration tests.

## See Also

- **API Reference**: `goox_api_reference.md` - Complete API documentation
- **Example Template**: `apps/goox_desktop/assets/webview/extension_template.html` - Working example
- **Design Document**: `.kiro/specs/editor-extension-enhancements/design.md` - Architecture details
