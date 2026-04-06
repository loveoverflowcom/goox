part of 'editor_layout_views.dart';

/// Widget for resizing the sidebar.
final class _ResizeHandleWidget extends StatelessWidget {
  /// Creates a resize handle widget.
  const _ResizeHandleWidget({
    required this.currentWidth,
    required this.theme,
  });

  /// The current sidebar width.
  final double currentWidth;

  /// The editor theme.
  final EditorThemeExtension theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        context
            .read<EditorLayoutBloc>()
            .add(ResizeSidebarEvent(currentWidth + details.delta.dx));
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: AppSpacing.resizeHandleWidth,
          color: theme.borderColor,
        ),
      ),
    );
  }
}
