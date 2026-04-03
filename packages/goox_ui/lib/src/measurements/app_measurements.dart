/// Spacing constants for the Goox editor.
final class AppSpacing {
  /// Private constructor to prevent instantiation.
  const AppSpacing._();

  // ========== New Measurements System ==========
  /// The default unit of spacing
  static const double spaceUnit = 16;

  /// xxxs spacing value (1pt)
  static const double xxxs = 0.0625 * spaceUnit;

  /// xxs spacing value (2pt)
  static const double xxs = 0.125 * spaceUnit;

  /// xs spacing value (4pt)
  static const double xs = 0.25 * spaceUnit;

  /// sm spacing value (8pt)
  static const double sm = 0.5 * spaceUnit;

  /// md spacing value (12pt)
  static const double md = 0.75 * spaceUnit;

  /// lg spacing value (16pt)
  static const double lg = spaceUnit;

  /// xlg spacing value (24pt)
  static const double xlg = 1.5 * spaceUnit;

  /// lx spacing value (32pt)
  static const double lx = spaceUnit * 2;

  /// xxlg spacing value (40pt)
  static const double xxlg = 2.5 * spaceUnit;

  /// xxxlg spacing value (64pt)
  static const double xxxlg = 4 * spaceUnit;

  // ========== Legacy Editor Constants ==========
  // Activity Bar
  /// Width of the activity bar in pixels.
  static const double activityBarWidth = 48;

  // Sidebar
  /// Minimum width of the sidebar in pixels.
  static const double sidebarMinWidth = 200;

  /// Maximum width of the sidebar in pixels.
  static const double sidebarMaxWidth = 600;

  /// Default width of the sidebar in pixels (includes activity bar).
  static const double sidebarDefaultWidth = 250 + activityBarWidth;

  // Layout
  /// Height of the status bar in pixels.
  static const double statusBarHeight = 22;

  /// Height of each tab in pixels.
  static const double tabHeight = 35;

  /// Width of the resize handle in pixels.
  static const double resizeHandleWidth = 4;

  // Responsive
  /// Breakpoint for responsive layout in pixels.
  static const double responsiveBreakpoint = 800;

  /// Minimum layout width in pixels.
  static const double minLayoutWidth = 600;

  /// Minimum layout height in pixels.
  static const double minLayoutHeight = 400;

  // Editor
  /// Width of the line number column in pixels.
  static const double lineNumberWidth = 50;

  /// Padding around editor content in pixels.
  static const double editorPadding = 8;

  /// Line height multiplier for text.
  static const double lineHeight = 1.5;

  /// Font size for editor text in pixels.
  static const double fontSize = 14;

  // History
  /// Maximum number of undo/redo actions to keep.
  static const int maxHistorySize = 100;

  // File Explorer
  /// Height of each file item in pixels.
  static const double fileItemHeight = 24;

  /// Indentation per level in file tree in pixels.
  static const double fileItemIndent = 16;

  /// Size of file/folder icons in pixels.
  static const double iconSize = 16;

  // Tab
  /// Minimum width of a tab in pixels.
  static const double tabMinWidth = 120;

  /// Maximum width of a tab in pixels.
  static const double tabMaxWidth = 200;

  /// Horizontal padding inside tabs in pixels.
  static const double tabPadding = 12;
}

/// Border radius constants.
abstract final class AppRadii {
  /// Small radius (4pt)
  static const double sm = 4;

  /// Medium radius (8pt)
  static const double md = 8;

  /// Large radius (16pt)
  static const double lg = 16;

  /// Extra large radius (24pt)
  static const double xl = 24;
}

/// Elevation constants.
abstract final class AppElevations {
  /// Small elevation (4pt)
  static const double sm = 4;

  /// Medium elevation (8pt)
  static const double md = 8;

  /// Large elevation (16pt)
  static const double lg = 16;
}
