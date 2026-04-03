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
