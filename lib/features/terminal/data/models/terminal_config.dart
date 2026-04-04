/// Configuration model for terminal panel
class TerminalConfig {
  /// Constructor
  const TerminalConfig({
    required this.isVisible,
    required this.height,
  });

  /// Whether the terminal panel is visible
  final bool isVisible;

  /// Height of the terminal panel in pixels
  final double height;

  /// Default height for terminal panel
  static const double defaultHeight = 200.0;

  /// Minimum height for terminal panel
  static const double minHeight = 100.0;

  /// Maximum height ratio (80% of window height)
  static const double maxHeightRatio = 0.8;
}
