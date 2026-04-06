part of 'editor_layout_views.dart';

/// Sidebar widget containing navigation rail and tab contents.
final class _SidebarWidget extends StatelessWidget {
  /// Creates a sidebar widget.
  const _SidebarWidget({
    required this.width,
    required this.theme,
  });

  /// The total sidebar width (including activity bar).
  final double width;

  /// The editor theme.
  final EditorThemeExtension theme;

  @override
  Widget build(BuildContext context) {
    // Width includes activity bar + content area
    final contentWidth = width - AppSpacing.activityBarWidth;

    return SizedBox(
      width: width,
      child: GooxNavigationRail(
        initialSelectedId: 'explorer',
        destinations: [
          GooxDestinationTab(
            id: 'explorer',
            title: 'Explorer',
            icon: Icons.copy_rounded,
            builder: (context) => _ExplorerTabContent(
              contentWidth: contentWidth,
              theme: theme,
            ),
          ),
          GooxDestinationTab(
            id: 'search',
            title: 'Search',
            icon: Icons.search,
            builder: (context) => _SearchTabContent(
              contentWidth: contentWidth,
              theme: theme,
            ),
          ),
          GooxDestinationTab(
            id: 'source-control',
            title: 'Source Control',
            icon: Icons.account_tree_outlined,
            builder: (context) => _SourceControlTabContent(
              contentWidth: contentWidth,
              theme: theme,
            ),
          ),
          GooxDestinationTab(
            id: 'extensions',
            title: 'Extensions',
            icon: Icons.extension_outlined,
            builder: (context) => _ExtensionsTabContent(
              contentWidth: contentWidth,
              theme: theme,
            ),
          ),
          GooxDestinationTab(
            id: 'settings',
            title: 'Settings',
            icon: Icons.settings_outlined,
            alignment: GooxTabAlignment.bottom,
            builder: (context) => _SettingsTabContent(
              contentWidth: contentWidth,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}
