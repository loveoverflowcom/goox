part of 'editor_layout_bloc.dart';

abstract class EditorLayoutEvent extends Equatable {
  const EditorLayoutEvent();

  @override
  List<Object?> get props => [];
}

final class ToggleSidebarEvent extends EditorLayoutEvent {
  const ToggleSidebarEvent();
}

final class ResizeSidebarEvent extends EditorLayoutEvent {

  const ResizeSidebarEvent(this.newWidth);
  final double newWidth;

  @override
  List<Object?> get props => [newWidth];
}

final class InitializeLayoutEvent extends EditorLayoutEvent {

  const InitializeLayoutEvent(this.workspacePath);
  final String workspacePath;

  @override
  List<Object?> get props => [workspacePath];
}
