# Context Menu Action Handler

Helper class for wiring context menu actions to BLoC events and dialogs.

## Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:goox/features/file_explorer/presentation/widgets/helpers/context_menu_action_handler.dart';
import 'package:goox/features/file_explorer/data/models/file_node.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final handler = ContextMenuActionHandler(
      context: context,
      workspacePath: '/path/to/workspace',
    );

    // For a file node
    final fileNode = FileNode(
      name: 'example.dart',
      path: '/path/to/workspace/example.dart',
      type: FileNodeType.file,
    );

    // Get callbacks for the file node
    final callbacks = handler.getCallbacks(node: fileNode);

    // Use callbacks in your context menu
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Text('Rename'),
          onTap: callbacks.onRename,
        ),
        PopupMenuItem(
          child: Text('Delete'),
          onTap: callbacks.onDelete,
        ),
        PopupMenuItem(
          child: Text('Copy Path'),
          onTap: callbacks.onCopyPath,
        ),
      ],
    );
  }
}
```

## Features

- **Automatic Dialog Display**: Shows appropriate dialogs (create, rename, delete) automatically
- **BLoC Event Dispatching**: Dispatches events to FileExplorerBloc after user confirmation
- **Context-Aware**: Returns different callbacks based on node type (file, folder, or empty area)
- **Menu Positioning**: Handles menu positioning logic

## Callback Types

### For File Nodes
- `onRename`: Shows rename dialog and dispatches RenameNodeEvent
- `onDelete`: Shows delete confirmation and dispatches DeleteNodeEvent
- `onCopyPath`: Dispatches CopyPathEvent to copy path to clipboard
- `onNewFile`: Shows create file dialog (parent is workspace)
- `onNewFolder`: Shows create folder dialog (parent is workspace)
- `onRefresh`: Dispatches RefreshWorkspaceEvent

### For Folder Nodes
- All file node callbacks, plus:
- `onNewFile`: Shows create file dialog (parent is the folder)
- `onNewFolder`: Shows create folder dialog (parent is the folder)

### For Empty Area (null node)
- `onNewFile`: Shows create file dialog (parent is workspace)
- `onNewFolder`: Shows create folder dialog (parent is workspace)
- `onRefresh`: Dispatches RefreshWorkspaceEvent
- `onRename`: null
- `onDelete`: null
- `onCopyPath`: null

## Requirements Validated

- **Requirement 2.7**: Rename action with dialog
- **Requirement 2.8**: Delete action with confirmation
- **Requirement 2.9**: Copy path action
- **Requirement 2.10**: Refresh action
