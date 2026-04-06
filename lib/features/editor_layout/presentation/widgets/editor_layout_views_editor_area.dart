part of 'editor_layout_views.dart';

/// Editor area widget containing tab bar and text editor.
final class _EditorAreaWidget extends StatelessWidget {
  /// Creates an editor area widget.
  const _EditorAreaWidget({
    required this.theme,
  });

  /// The editor theme.
  final EditorThemeExtension theme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: theme.editorBackground,
      child: const Column(
        children: [
          TabBarWidget(),
          Expanded(child: TextEditorWidget()),
        ],
      ),
    );
  }
}
