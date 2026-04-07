# File Explorer Widgets

## FileExplorerToolbarCallbacks

This class provides static callback methods for handling toolbar actions in the File Explorer.

### Usage

The callbacks are designed to be passed to the `FileExplorerToolbar` widget:

```dart
FileExplorerToolbar(
  onNewFile: () => FileExplorerToolbarCallbacks.handleNewFile(context),
  onNewFolder: () => FileExplorerToolbarCallbacks.handleNewFolder(context),
)
```

### Behavior

#### handleNewFile(BuildContext context)

Shows the `CreateFileDialog` and dispatches a `CreateFileEvent` when confirmed.

The file will be created in:
- The currently selected folder if a folder is selected
- The parent of the currently selected file if a file is selected  
- The workspace root if nothing is selected

#### handleNewFolder(BuildContext context)

Shows the `CreateFolderDialog` and dispatches a `CreateFolderEvent` when confirmed.

The folder will be created in:
- The currently selected folder if a folder is selected
- The parent of the currently selected file if a file is selected
- The workspace root if nothing is selected

### Integration

These callbacks will be integrated into `FileExplorerWidget` in task 9.1 of the implementation plan.
