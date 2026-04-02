# Goox Extension API Reference

## Overview

The Goox Extension API (`gooxAPI`) provides a JavaScript interface for webview-based extensions to communicate with the Goox editor. This API enables extensions to read file content, receive updates, and send messages back to the editor.

## API Object

The `window.gooxAPI` object is automatically available in all extension webviews. It provides the following methods:

### Methods

#### `getFileContent()`

Returns the current file content as a string.

**Returns:** `string | null` - The current file content, or `null` if no content is available.

**Example:**
```javascript
const content = window.gooxAPI.getFileContent();
if (content) {
  console.log('File has', content.length, 'characters');
}
```

---

#### `sendMessage(type, data)`

Sends a message to the editor.

**Parameters:**
- `type` (string, required): The message type identifier
- `data` (object, optional): Additional data to send with the message

**Example:**
```javascript
window.gooxAPI.sendMessage('customAction', {
  action: 'highlight',
  line: 42
});
```

---

#### `requestContent()`

Requests the current file content from the editor. The editor will respond with a `fileContent` message.

**Example:**
```javascript
window.gooxAPI.requestContent();
```

---

#### `requestSave(content)`

Requests the editor to save the provided content.

**Parameters:**
- `content` (string, required): The content to save

**Example:**
```javascript
const modifiedContent = '// Modified\n' + window.gooxAPI.getFileContent();
window.gooxAPI.requestSave(modifiedContent);
```

---

#### `onFileUpdate(callback)`

Registers a callback to be called when the file content is updated.

**Parameters:**
- `callback` (function, required): Function to call when file updates
  - `content` (string): The new file content
  - `detail` (object): Additional message details

**Example:**
```javascript
window.gooxAPI.onFileUpdate(function(content, detail) {
  console.log('File updated:', content);
  console.log('Extension ID:', detail.extensionId);
});
```

---

#### `onFileContent(callback)`

Registers a callback to be called when file content is received.

**Parameters:**
- `callback` (function, required): Function to call when content is received
  - `content` (string): The file content
  - `detail` (object): Additional message details including `extensionId`

**Example:**
```javascript
window.gooxAPI.onFileContent(function(content, detail) {
  document.getElementById('editor').textContent = content;
});
```

---

#### `onMessage(callback)`

Registers a callback to be called for any message from the editor.

**Parameters:**
- `callback` (function, required): Function to call for each message
  - `message` (object): The complete message object with `type` and other fields

**Example:**
```javascript
window.gooxAPI.onMessage(function(message) {
  console.log('Received:', message.type);
  
  switch(message.type) {
    case 'fileContent':
      handleContent(message.content);
      break;
    case 'fileUpdate':
      handleUpdate(message.content);
      break;
  }
});
```

---

#### `ready()`

Notifies the editor that the webview is ready to receive messages. This should be called after the webview has finished initializing.

**Example:**
```javascript
document.addEventListener('DOMContentLoaded', function() {
  window.gooxAPI.ready();
});
```

## Message Types

### Messages from Editor to Webview

#### `fileContent`
Sent when the file content is initially loaded or requested.

**Fields:**
- `type`: `"fileContent"`
- `content`: The file content (string)
- `extensionId`: The extension identifier (string)

#### `fileUpdate`
Sent when the file content changes.

**Fields:**
- `type`: `"fileUpdate"`
- `content`: The updated file content (string)
- `extensionId`: The extension identifier (string)

### Messages from Webview to Editor

#### `ready`
Sent by the webview to indicate it's ready to receive messages.

**Fields:**
- `type`: `"ready"`

#### `requestContent`
Requests the current file content.

**Fields:**
- `type`: `"requestContent"`

#### `save`
Requests to save content.

**Fields:**
- `type`: `"save"`
- `content`: The content to save (string)

#### Custom Messages
Extensions can send custom message types for application-specific functionality.

**Example:**
```javascript
window.gooxAPI.sendMessage('highlight', {
  line: 10,
  column: 5
});
```

## Complete Example

```html
<!DOCTYPE html>
<html>
<head>
  <title>My Extension</title>
</head>
<body>
  <div id="content"></div>
  <button onclick="save()">Save</button>

  <script>
    // Listen for file content
    window.gooxAPI.onFileContent(function(content, detail) {
      document.getElementById('content').textContent = content;
    });

    // Listen for updates
    window.gooxAPI.onFileUpdate(function(content) {
      document.getElementById('content').textContent = content;
    });

    // Save function
    function save() {
      const content = document.getElementById('content').textContent;
      window.gooxAPI.requestSave(content);
    }

    // Initialize
    document.addEventListener('DOMContentLoaded', function() {
      window.gooxAPI.ready();
    });
  </script>
</body>
</html>
```

## Best Practices

1. **Always call `ready()`**: Notify the editor when your webview is initialized
2. **Handle null content**: Check if `getFileContent()` returns null before using it
3. **Use specific message types**: Use descriptive message types for custom messages
4. **Error handling**: Wrap API calls in try-catch blocks for robustness
5. **Cleanup**: Remove event listeners when appropriate to prevent memory leaks

## Security Considerations

- The webview is sandboxed and cannot access arbitrary file system paths
- All communication with the editor goes through the message passing API
- Extension assets are accessible via relative paths only
- Custom messages are forwarded to the parent widget's `onMessage` callback

## Requirements Satisfied

This API implementation satisfies:
- **Requirement 15.3**: Message passing API between webview and editor
- **Requirement 15.4**: API for reading file content, receiving file change events, sending UI updates
- **Requirement 15.6**: Passing file content to webview on file open
