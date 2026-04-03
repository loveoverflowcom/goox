import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/editor_layout/presentation/blocs/editor_layout_event.dart';
import 'package:goox/features/editor_layout/presentation/blocs/editor_layout_state.dart';
import 'package:goox_ui/goox_ui.dart';

final class EditorLayoutBloc extends Bloc<EditorLayoutEvent, EditorLayoutState> {
  EditorLayoutBloc() : super(const EditorLayoutState()) {
    on<ToggleSidebarEvent>(_onToggleSidebar);
    on<ResizeSidebarEvent>(_onResizeSidebar);
    on<InitializeLayoutEvent>(_onInitializeLayout);
  }

  void _onToggleSidebar(
    ToggleSidebarEvent event,
    Emitter<EditorLayoutState> emit,
  ) {
    emit(state.copyWith(sidebarVisible: !state.sidebarVisible));
  }

  void _onResizeSidebar(
    ResizeSidebarEvent event,
    Emitter<EditorLayoutState> emit,
  ) {
    final constrainedWidth = event.newWidth.clamp(
      AppSpacing.sidebarMinWidth,
      AppSpacing.sidebarMaxWidth,
    );
    
    emit(state.copyWith(sidebarWidth: constrainedWidth));
  }

  void _onInitializeLayout(
    InitializeLayoutEvent event,
    Emitter<EditorLayoutState> emit,
  ) {
    emit(state.copyWith(
      workspacePath: event.workspacePath,
      status: .loaded,
    ));
  }
}
