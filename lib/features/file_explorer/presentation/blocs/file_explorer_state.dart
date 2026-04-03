part of 'file_explorer_bloc.dart';

enum FileExplorerStatus { initial, loading, loaded, error }

final class FileExplorerState extends Equatable {

  const FileExplorerState({
    this.rootNodes = const [],
    this.expandedFolders = const {},
    this.selectedPath,
    this.status = .initial,
    this.errorMessage,
  });
  final List<FileNode> rootNodes;
  final Map<String, List<FileNode>> expandedFolders;
  final String? selectedPath;
  final FileExplorerStatus status;
  final String? errorMessage;

  FileExplorerState copyWith({
    List<FileNode>? rootNodes,
    Map<String, List<FileNode>>? expandedFolders,
    String? selectedPath,
    FileExplorerStatus? status,
    String? errorMessage,
  }) {
    return FileExplorerState(
      rootNodes: rootNodes ?? this.rootNodes,
      expandedFolders: expandedFolders ?? this.expandedFolders,
      selectedPath: selectedPath ?? this.selectedPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [rootNodes, expandedFolders, selectedPath, status, errorMessage];
}
