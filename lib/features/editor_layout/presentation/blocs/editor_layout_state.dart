import 'package:equatable/equatable.dart';
import 'package:goox_ui/goox_ui.dart';

enum LayoutStatus { initial, loaded }

final class EditorLayoutState extends Equatable {

  const EditorLayoutState({
    this.sidebarVisible = true,
    this.sidebarWidth = AppSpacing.sidebarDefaultWidth,
    this.workspacePath = '',
    this.status = .initial,
  });
  final bool sidebarVisible;
  final double sidebarWidth;
  final String workspacePath;
  final LayoutStatus status;

  EditorLayoutState copyWith({
    bool? sidebarVisible,
    double? sidebarWidth,
    String? workspacePath,
    LayoutStatus? status,
  }) {
    return EditorLayoutState(
      sidebarVisible: sidebarVisible ?? this.sidebarVisible,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      workspacePath: workspacePath ?? this.workspacePath,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [sidebarVisible, sidebarWidth, workspacePath, status];
}
