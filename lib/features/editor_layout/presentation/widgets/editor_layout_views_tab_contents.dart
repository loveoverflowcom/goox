part of 'editor_layout_views.dart';

/// Explorer tab content widget.
final class _ExplorerTabContent extends StatelessWidget {
  /// Creates an explorer tab content widget.
  const _ExplorerTabContent({
    required this.contentWidth,
    required this.theme,
  });

  /// The content width.
  final double contentWidth;

  /// The editor theme.
  final EditorThemeExtension theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: contentWidth,
      decoration: BoxDecoration(
        color: theme.sidebarBackground,
        border: Border(
          right: BorderSide(color: theme.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              'EXPLORER',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: FileExplorerWidget(
              onFileSelected: (filePath, fileName) => context
                .read<TabManagerBloc>()
                .add(
                  OpenTabEvent(
                    filePath: filePath,
                    fileName: fileName,
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Search tab content widget.
final class _SearchTabContent extends StatelessWidget {
  /// Creates a search tab content widget.
  const _SearchTabContent({
    required this.contentWidth,
    required this.theme,
  });

  /// The content width.
  final double contentWidth;

  /// The editor theme.
  final EditorThemeExtension theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: contentWidth,
      decoration: BoxDecoration(
        color: theme.sidebarBackground,
        border: Border(
          right: BorderSide(color: theme.borderColor),
        ),
      ),
      child: Center(
        child: Text(
          'Search',
          style: TextStyle(color: theme.textColor),
        ),
      ),
    );
  }
}

/// Source Control tab content widget.
final class _SourceControlTabContent extends StatelessWidget {
  /// Creates a source control tab content widget.
  const _SourceControlTabContent({
    required this.contentWidth,
    required this.theme,
  });

  /// The content width.
  final double contentWidth;

  /// The editor theme.
  final EditorThemeExtension theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: contentWidth,
      decoration: BoxDecoration(
        color: theme.sidebarBackground,
        border: Border(
          right: BorderSide(color: theme.borderColor),
        ),
      ),
      child: Center(
        child: Text(
          'Source Control',
          style: TextStyle(color: theme.textColor),
        ),
      ),
    );
  }
}

/// Extensions tab content widget.
final class _ExtensionsTabContent extends StatelessWidget {
  /// Creates an extensions tab content widget.
  const _ExtensionsTabContent({
    required this.contentWidth,
    required this.theme,
  });

  /// The content width.
  final double contentWidth;

  /// The editor theme.
  final EditorThemeExtension theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: contentWidth,
      decoration: BoxDecoration(
        color: theme.sidebarBackground,
        border: Border(
          right: BorderSide(color: theme.borderColor),
        ),
      ),
      child: Center(
        child: Text(
          'Extensions',
          style: TextStyle(color: theme.textColor),
        ),
      ),
    );
  }
}

/// Settings tab content widget.
final class _SettingsTabContent extends StatelessWidget {
  /// Creates a settings tab content widget.
  const _SettingsTabContent({
    required this.contentWidth,
    required this.theme,
  });

  /// The content width.
  final double contentWidth;

  /// The editor theme.
  final EditorThemeExtension theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: contentWidth,
      decoration: BoxDecoration(
        color: theme.sidebarBackground,
        border: Border(
          right: BorderSide(color: theme.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              'SETTINGS',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ThemeSelectorWidget(),
        ],
      ),
    );
  }
}
