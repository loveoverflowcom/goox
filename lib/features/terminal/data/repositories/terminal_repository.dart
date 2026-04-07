/// Abstract repository for terminal panel persistence
abstract class TerminalRepository {
  /// Load saved terminal visibility state
  Future<bool> loadVisibility();

  /// Save terminal visibility state
  Future<void> saveVisibility({required bool isVisible});

  /// Load terminal panel height
  Future<double> loadHeight();

  /// Save terminal panel height
  Future<void> saveHeight({required double height});

  /// Load number of terminals
  Future<int> loadTerminalCount();

  /// Save number of terminals
  Future<void> saveTerminalCount({required int count});

  /// Load list of working directories
  Future<List<String>> loadWorkingDirectories();

  /// Save list of working directories
  Future<void> saveWorkingDirectories({required List<String> paths});
}
