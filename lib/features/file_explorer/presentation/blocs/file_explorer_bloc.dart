import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/core/errors/failures.dart';
import 'package:goox/features/file_explorer/data.dart';

part 'file_explorer_event.dart';
part 'file_explorer_state.dart';

final class FileExplorerBloc
    extends Bloc<FileExplorerEvent, FileExplorerState> {
  FileExplorerBloc({required this.repository})
    : super(const FileExplorerState()) {
    on<LoadWorkspaceEvent>(_onLoadWorkspace);
    on<ToggleFolderEvent>(_onToggleFolder);
    on<SelectFileEvent>(_onSelectFile);
    on<CreateFileEvent>(_onCreateFile);
    on<CreateFolderEvent>(_onCreateFolder);
    on<RenameNodeEvent>(_onRenameNode);
    on<DeleteNodeEvent>(_onDeleteNode);
    on<CopyPathEvent>(_onCopyPath);
    on<RefreshWorkspaceEvent>(_onRefreshWorkspace);
    on<ClearFileToOpenEvent>(_onClearFileToOpen);
    on<ClearMessagesEvent>(_onClearMessages);
  }
  final WorkspaceRepository repository;

  Future<void> _onLoadWorkspace(
    LoadWorkspaceEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    emit(state.copyWith(status: FileExplorerStatus.loading));

    final result = await repository.loadWorkspace(event.workspacePath).run();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FileExplorerStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (nodes) => emit(
        state.copyWith(
          rootNodes: nodes,
          workspacePath: event.workspacePath,
          expandedFolders: const {},
          selectedPath: null,
          errorMessage: null,
          successMessage: null,
          pendingOperation: null,
          fileToOpen: null,
          status: FileExplorerStatus.loaded,
        ),
      ),
    );
  }

  Future<void> _onToggleFolder(
    ToggleFolderEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    final expandedFolders = Map<String, List<FileNode>>.from(
      state.expandedFolders,
    );

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

  Future<void> _onCreateFile(
    CreateFileEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FileExplorerStatus.loading,
        pendingOperation: FileOperation.creating,
        errorMessage: null,
      ),
    );

    // Validate file name
    final validationResult = repository.validateFileName(event.fileName);

    final validationError = validationResult.fold(
      (failure) => failure.message,
      (_) => null,
    );

    if (validationError != null) {
      emit(
        state.copyWith(
          status: FileExplorerStatus.error,
          errorMessage: validationError,
          pendingOperation: null,
        ),
      );
      return;
    }

    // Create file
    final result = await repository
        .createFile(
          event.parentPath,
          event.fileName,
        )
        .run();

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: FileExplorerStatus.error,
            errorMessage: _formatErrorMessage(failure),
            pendingOperation: null,
          ),
        );
      },
      (newNode) async {
        // Ensure parent folder is expanded
        final expandedFolders = await _getExpandedFolders(event.parentPath);

        // Reload workspace to get updated tree
        final reloadedState = await _getReloadedWorkspaceState(expandedFolders);

        if (reloadedState != null) {
          // Select the newly created file and signal it should be opened
          emit(
            reloadedState.copyWith(
              selectedPath: newNode.path,
              fileToOpen: newNode,
              successMessage: 'File created successfully',
              pendingOperation: null,
            ),
          );
        }
      },
    );
  }

  Future<void> _onCreateFolder(
    CreateFolderEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FileExplorerStatus.loading,
        pendingOperation: FileOperation.creating,
        errorMessage: null,
      ),
    );

    // Validate folder name
    final validationResult = repository.validateFileName(event.folderName);

    final validationError = validationResult.fold(
      (failure) => failure.message,
      (_) => null,
    );

    if (validationError != null) {
      emit(
        state.copyWith(
          status: FileExplorerStatus.error,
          errorMessage: validationError,
          pendingOperation: null,
        ),
      );
      return;
    }

    // Create folder
    final result = await repository
        .createFolder(
          event.parentPath,
          event.folderName,
        )
        .run();

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: FileExplorerStatus.error,
            errorMessage: _formatErrorMessage(failure),
            pendingOperation: null,
          ),
        );
      },
      (newNode) async {
        // Ensure parent folder is expanded
        final expandedFolders = await _getExpandedFolders(event.parentPath);

        // Reload workspace to get updated tree
        final reloadedState = await _getReloadedWorkspaceState(expandedFolders);

        if (reloadedState != null) {
          // Select the newly created folder
          emit(
            reloadedState.copyWith(
              selectedPath: newNode.path,
              successMessage: 'Folder created successfully',
              pendingOperation: null,
            ),
          );
        }
      },
    );
  }

  Future<void> _onRenameNode(
    RenameNodeEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FileExplorerStatus.loading,
        pendingOperation: FileOperation.renaming,
        errorMessage: null,
      ),
    );

    // Validate new name
    final validationResult = repository.validateFileName(event.newName);

    final validationError = validationResult.fold(
      (failure) => failure.message,
      (_) => null,
    );

    if (validationError != null) {
      emit(
        state.copyWith(
          status: FileExplorerStatus.error,
          errorMessage: validationError,
          pendingOperation: null,
        ),
      );
      return;
    }

    // Rename node
    final result = await repository
        .renameNode(
          event.nodePath,
          event.newName,
        )
        .run();

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: FileExplorerStatus.error,
            errorMessage: _formatErrorMessage(failure),
            pendingOperation: null,
          ),
        );
      },
      (renamedNode) async {
        // Reload workspace to get updated tree
        final reloadedState = await _getReloadedWorkspaceState(
          state.expandedFolders,
        );

        if (reloadedState != null) {
          // Select the renamed node
          emit(
            reloadedState.copyWith(
              selectedPath: renamedNode.path,
              successMessage: 'Renamed successfully',
              pendingOperation: null,
            ),
          );
        }
      },
    );
  }

  Future<void> _onDeleteNode(
    DeleteNodeEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FileExplorerStatus.loading,
        pendingOperation: FileOperation.deleting,
        errorMessage: null,
      ),
    );

    // Delete node
    final result = await repository.deleteNode(event.nodePath).run();

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: FileExplorerStatus.error,
            errorMessage: _formatErrorMessage(failure),
            pendingOperation: null,
          ),
        );
      },
      (_) async {
        // Clear selection if deleted node was selected
        final newSelectedPath = state.selectedPath == event.nodePath
            ? null
            : state.selectedPath;

        // Reload workspace to get updated tree
        final reloadedState = await _getReloadedWorkspaceState(
          state.expandedFolders,
        );

        if (reloadedState != null) {
          emit(
            FileExplorerState(
              rootNodes: reloadedState.rootNodes,
              expandedFolders: reloadedState.expandedFolders,
              selectedPath: newSelectedPath,
              workspacePath: reloadedState.workspacePath,
              status: FileExplorerStatus.loaded,
              errorMessage: null,
              successMessage: 'Deleted successfully',
              pendingOperation: null,
              fileToOpen: null,
            ),
          );
        }
      },
    );
  }

  Future<void> _onCopyPath(
    CopyPathEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FileExplorerStatus.loading,
        pendingOperation: FileOperation.copying,
        errorMessage: null,
      ),
    );

    try {
      // Copy path to clipboard
      await Clipboard.setData(ClipboardData(text: event.nodePath));

      emit(
        state.copyWith(
          status: FileExplorerStatus.loaded,
          successMessage: 'Path copied to clipboard',
          pendingOperation: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: FileExplorerStatus.error,
          errorMessage: 'Failed to copy path: ${error.toString()}',
          pendingOperation: null,
        ),
      );
    }
  }

  Future<void> _onRefreshWorkspace(
    RefreshWorkspaceEvent event,
    Emitter<FileExplorerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FileExplorerStatus.loading,
        pendingOperation: FileOperation.refreshing,
        errorMessage: null,
      ),
    );

    final result = await repository.refreshWorkspace(event.workspacePath).run();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FileExplorerStatus.error,
          errorMessage: _formatErrorMessage(failure),
          pendingOperation: null,
        ),
      ),
      (nodes) => emit(
        state.copyWith(
          rootNodes: nodes,
          status: FileExplorerStatus.loaded,
          successMessage: 'Workspace refreshed',
          pendingOperation: null,
        ),
      ),
    );
  }

  // Helper methods

  Future<Map<String, List<FileNode>>> _getExpandedFolders(
    String parentPath,
  ) async {
    final expandedFolders = Map<String, List<FileNode>>.from(
      state.expandedFolders,
    );

    // If parent is workspace root, no need to expand
    if (parentPath == state.workspacePath) return expandedFolders;

    // If parent is already expanded, no need to reload
    if (expandedFolders.containsKey(parentPath)) return expandedFolders;

    // Load children for parent folder
    final result = await repository.loadChildren(parentPath).run();

    result.fold(
      (failure) {
        // Ignore failure - parent expansion is not critical
      },
      (children) {
        expandedFolders[parentPath] = children;
      },
    );

    return expandedFolders;
  }

  Future<FileExplorerState?> _getReloadedWorkspaceState(
    Map<String, List<FileNode>> currentExpandedFolders,
  ) async {
    // Use stored workspace path
    if (state.workspacePath == null) return null;

    final result = await repository
        .refreshWorkspace(state.workspacePath!)
        .run();

    return await result.fold(
      (failure) async {
        // Keep current state if reload fails
        return null;
      },
      (nodes) async {
        // Reload children for all previously expanded folders
        final expandedFolders = <String, List<FileNode>>{};

        for (final folderPath in currentExpandedFolders.keys) {
          final childrenResult = await repository
              .loadChildren(folderPath)
              .run();
          childrenResult.fold(
            (failure) {
              // Skip folders that can't be loaded (might have been deleted)
            },
            (children) {
              expandedFolders[folderPath] = children;
            },
          );
        }

        return state.copyWith(
          rootNodes: nodes,
          expandedFolders: expandedFolders,
          status: FileExplorerStatus.loaded,
        );
      },
    );
  }

  String _formatErrorMessage(Failure failure) {
    if (failure is FileSystemFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.message;
    }
    return 'An error occurred: ${failure.message}';
  }

  void _onClearFileToOpen(
    ClearFileToOpenEvent event,
    Emitter<FileExplorerState> emit,
  ) {
    emit(
      FileExplorerState(
        rootNodes: state.rootNodes,
        expandedFolders: state.expandedFolders,
        selectedPath: state.selectedPath,
        workspacePath: state.workspacePath,
        status: state.status,
        errorMessage: state.errorMessage,
        successMessage: state.successMessage,
        pendingOperation: state.pendingOperation,
        fileToOpen: null,
      ),
    );
  }

  void _onClearMessages(
    ClearMessagesEvent event,
    Emitter<FileExplorerState> emit,
  ) {
    emit(
      state.copyWith(
        errorMessage: null,
        successMessage: null,
      ),
    );
  }
}
