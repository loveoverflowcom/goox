import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/src/controllers/terminal_controller.dart';
import 'package:goox_terminal/src/models/pty_size.dart';
import 'package:goox_terminal/src/models/shell_config.dart';
import 'package:goox_terminal/src/models/terminal_status.dart';

void main() {
  group('TerminalController.initialize()', () {
    test('should be implemented (not throw UnimplementedError)', () {
      final controller = TerminalController(
        id: 'test-terminal',
        shellConfig: ShellConfig.bash(),
        initialSize: PtySize.defaultSize,
      );

      // Verify that initialize() is implemented
      // In test environment without native plugin, it will throw ProcessSpawnException
      // but NOT UnimplementedError
      expect(
        () => controller.initialize(),
        throwsA(isNot(isA<UnimplementedError>())),
      );
    });

    test('should have terminal instance created in constructor', () {
      final controller = TerminalController(
        id: 'test-terminal',
        shellConfig: ShellConfig.bash(),
        initialSize: PtySize.defaultSize,
      );

      // Verify terminal is created (maxLines: 1000 is set internally)
      expect(controller.terminal, isNotNull);
    });

    test('should start with initializing status', () {
      final controller = TerminalController(
        id: 'test-terminal',
        shellConfig: ShellConfig.bash(),
        initialSize: PtySize.defaultSize,
      );

      expect(controller.status, equals(TerminalStatus.initializing));
    });

    test('should have null PID before initialization', () {
      final controller = TerminalController(
        id: 'test-terminal',
        shellConfig: ShellConfig.bash(),
        initialSize: PtySize.defaultSize,
      );

      expect(controller.pid, isNull);
    });

    test('should have null exit code before initialization', () {
      final controller = TerminalController(
        id: 'test-terminal',
        shellConfig: ShellConfig.bash(),
        initialSize: PtySize.defaultSize,
      );

      expect(controller.exitCode, isNull);
    });

    test('should have default title before initialization', () {
      final controller = TerminalController(
        id: 'test-terminal',
        shellConfig: ShellConfig.bash(),
        initialSize: PtySize.defaultSize,
      );

      expect(controller.title, equals('Terminal'));
    });
  });
}
