/// Abstract repository for terminal panel persistence
abstract class TerminalRepository {
  /// Load saved terminal visibility state
  Future<bool> loadVisibility();

  /// Save terminal visibility state
  Future<void> saveVisibility({required bool isVisible});

  /// Load saved terminal panel height
  Future<double> loadHeight();

  /// Save terminal panel height
  Future<void> saveHeight(double height);
}
