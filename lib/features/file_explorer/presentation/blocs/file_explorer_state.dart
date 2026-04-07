part of 'file_explorer_bloc.dart';

enum FileExplorerStatus { initial, loading, loaded, error }

enum FileOperation {
  creating,
  renaming,
  deleting,
  copying,
  refreshing,
}

final class FileExplorerState extends Equatable {

  const FileExplorerState({
    this.rootNodes = const [],
    this.expandedFolders = const {},
    this.selectedPath,
    this.workspacePath,
    this.status = FileExplorerStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.pendingOperation,
    this.fileToOpen,
  });
  final List<FileNode> rootNodes;
  final Map<String, List<FileNode>> expandedFolders;
  final String? selectedPath;
  final String? workspacePath;
  final FileExplorerStatus status;
  final String? errorMessage;
  final String? successMessage;
  final FileOperation? pendingOperation;
  final FileNode? fileToOpen;

  FileExplorerState copyWith({
    List<FileNode>? rootNodes,
    Map<String, List<FileNode>>? expandedFolders,
    String? selectedPath,
    String? workspacePath,
    FileExplorerStatus? status,
    String? errorMessage,
    String? successMessage,
    FileOperation? pendingOperation,
    FileNode? fileToOpen,
  }) {
    return FileExplorerState(
      rootNodes: rootNodes ?? this.rootNodes,
      expandedFolders: expandedFolders ?? this.expandedFolders,
      selectedPath: selectedPath ?? this.selectedPath,
      workspacePath: workspacePath ?? this.workspacePath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      pendingOperation: pendingOperation ?? this.pendingOperation,
      fileToOpen: fileToOpen ?? this.fileToOpen,
    );
  }

  @override
  List<Object?> get props => [rootNodes, expandedFolders, selectedPath, workspacePath, status, errorMessage, successMessage, pendingOperation, fileToOpen];
}
