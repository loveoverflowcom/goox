import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/file_explorer/data.dart';

part 'file_explorer_event.dart';
part 'file_explorer_state.dart';

final class FileExplorerBloc extends Bloc<FileExplorerEvent, FileExplorerState> {

  FileExplorerBloc({required this.repository}) : super(const FileExplorerState()) {
    on<LoadWorkspaceEvent>(_onLoadWorkspace);
    on<ToggleFolderEvent>(_onToggleFolder);
    on<SelectFileEvent>(_onSelectFile);
  }
  final WorkspaceRepository repository;

  Future<void> _onLoadWorkspace(
    LoadWorkspaceEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    emit(state.copyWith(status: .loading));

    final result = await repository.loadWorkspace(event.workspacePath).run();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: .error,
          errorMessage: failure.message,
        ),
      ),
      (nodes) => emit(
        state.copyWith(
          rootNodes: nodes,
          status: .loaded,
        ),
      ),
    );
  }

  Future<void> _onToggleFolder(
    ToggleFolderEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    final expandedFolders = Map<String, List<FileNode>>.from(state.expandedFolders);
    
    if (expandedFolders.containsKey(event.folderPath)) {
      // Collapse folder
      expandedFolders.remove(event.folderPath);
      emit(state.copyWith(expandedFolders: expandedFolders));
    } else {
      // Expand folder - load children
      final result = await repository.loadChildren(event.folderPath).run();
      
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: .error,
            errorMessage: failure.message,
          ),
        ),
        (children) {
          expandedFolders[event.folderPath] = children;
          emit(
            state.copyWith(
              expandedFolders: expandedFolders,
              status: .loaded,
            ),
          );
        },
      );
    }
  }

  void _onSelectFile(
    SelectFileEvent event,
    Emitter<FileExplorerState> emit,
  ) {
    emit(state.copyWith(selectedPath: event.filePath));
  }
}
