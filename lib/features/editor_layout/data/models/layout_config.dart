import 'package:equatable/equatable.dart';

final class LayoutConfig extends Equatable {

  const LayoutConfig({
    required this.sidebarVisible,
    required this.sidebarWidth,
    required this.workspacePath,
  });
  final bool sidebarVisible;
  final double sidebarWidth;
  final String workspacePath;

  LayoutConfig copyWith({
    bool? sidebarVisible,
    double? sidebarWidth,
    String? workspacePath,
  }) {
    return LayoutConfig(
      sidebarVisible: sidebarVisible ?? this.sidebarVisible,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      workspacePath: workspacePath ?? this.workspacePath,
    );
  }

  @override
  List<Object?> get props => [sidebarVisible, sidebarWidth, workspacePath];
}
