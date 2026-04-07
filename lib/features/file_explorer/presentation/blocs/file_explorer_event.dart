part of 'file_explorer_bloc.dart';

abstract class FileExplorerEvent extends Equatable {
  const FileExplorerEvent();

  @override
  List<Object?> get props => [];
}

final class LoadWorkspaceEvent extends FileExplorerEvent {

  const LoadWorkspaceEvent(this.workspacePath);
  final String workspacePath;

  @override
  List<Object?> get props => [workspacePath];
}

final class ToggleFolderEvent extends FileExplorerEvent {

  const ToggleFolderEvent(this.folderPath);
  final String folderPath;

  @override
  List<Object?> get props => [folderPath];
}

final class SelectFileEvent extends FileExplorerEvent {

  const SelectFileEvent(this.filePath);
  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

final class CreateFileEvent extends FileExplorerEvent {

  const CreateFileEvent({
    required this.parentPath,
    required this.fileName,
  });
  final String parentPath;
  final String fileName;

  @override
  List<Object?> get props => [parentPath, fileName];
}

final class CreateFolderEvent extends FileExplorerEvent {

  const CreateFolderEvent({
    required this.parentPath,
    required this.folderName,
  });
  final String parentPath;
  final String folderName;

  @override
  List<Object?> get props => [parentPath, folderName];
}

final class RenameNodeEvent extends FileExplorerEvent {

  const RenameNodeEvent({
    required this.nodePath,
    required this.newName,
  });
  final String nodePath;
  final String newName;

  @override
  List<Object?> get props => [nodePath, newName];
}

final class DeleteNodeEvent extends FileExplorerEvent {

  const DeleteNodeEvent(this.nodePath);
  final String nodePath;

  @override
  List<Object?> get props => [nodePath];
}

final class CopyPathEvent extends FileExplorerEvent {

  const CopyPathEvent(this.nodePath);
  final String nodePath;

  @override
  List<Object?> get props => [nodePath];
}

final class RefreshWorkspaceEvent extends FileExplorerEvent {

  const RefreshWorkspaceEvent(this.workspacePath);
  final String workspacePath;

  @override
  List<Object?> get props => [workspacePath];
}

// Internal event to clear fileToOpen flag
final class ClearFileToOpenEvent extends FileExplorerEvent {
  const ClearFileToOpenEvent();
}

// Internal event to clear messages after they're displayed
final class ClearMessagesEvent extends FileExplorerEvent {
  const ClearMessagesEvent();
}
