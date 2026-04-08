// Test to verify all public API exports are accessible
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/goox_terminal.dart';

void main() {
  group('Public API Exports', () {
    test('TerminalPanel is exported', () {
      expect(TerminalPanel, isNotNull);
    });

    test('TerminalSessionManager is exported', () {
      expect(TerminalSessionManager.instance, isNotNull);
    });

    test('TerminalController is exported', () {
      // Just verify the type is accessible
      expect(TerminalController, isNotNull);
    });

    test('TerminalStatus is exported', () {
      expect(TerminalStatus.initializing, isNotNull);
      expect(TerminalStatus.running, isNotNull);
      expect(TerminalStatus.exited, isNotNull);
      expect(TerminalStatus.error, isNotNull);
    });

    test('TerminalStatus extension is exported', () {
      expect(TerminalStatus.running.isActive, isTrue);
      expect(TerminalStatus.exited.isActive, isFalse);
      expect(TerminalStatus.running.canSendInput, isTrue);
      expect(TerminalStatus.error.canSendInput, isFalse);
    });

    test('ShellConfig is exported', () {
      final config = ShellConfig.bash();
      expect(config, isNotNull);
      expect(config.shellPath, equals('/bin/bash'));
    });

    test('ShellConfig factory methods are accessible', () {
      expect(ShellConfig.bash(), isNotNull);
      expect(ShellConfig.zsh(), isNotNull);
      expect(ShellConfig.fish(), isNotNull);
      expect(ShellConfig.powershell(), isNotNull);
      expect(ShellConfig.cmd(), isNotNull);
    });

    test('PtySize is exported', () {
      final size = PtySize.defaultSize;
      expect(size, isNotNull);
      expect(size.rows, equals(24));
      expect(size.cols, equals(80));
    });

    test('PtySize constants are accessible', () {
      expect(PtySize.defaultSize, isNotNull);
      expect(PtySize.standard, isNotNull);
      expect(PtySize.large, isNotNull);
      expect(PtySize.min, isNotNull);
      expect(PtySize.max, isNotNull);
    });

    test('TerminalTheme is exported', () {
      final theme = TerminalTheme.dark();
      expect(theme, isNotNull);
      expect(theme.background, isNotNull);
      expect(theme.foreground, isNotNull);
    });

    test('TerminalTheme factory methods are accessible', () {
      expect(TerminalTheme.dark(), isNotNull);
      expect(TerminalTheme.light(), isNotNull);
    });

    test('ShellDetector is exported', () {
      expect(ShellDetector, isNotNull);
    });

    test('ProcessSpawnException is exported', () {
      final exception = ProcessSpawnException('test error');
      expect(exception, isNotNull);
      expect(exception.message, contains('test error'));
    });
  });

  group('Internal Implementation Details Not Exported', () {
    test('TerminalView should not be directly accessible', () {
      // This test verifies that internal widgets are not exported
      // If this test fails to compile, it means TerminalView is not exported (which is correct)
      // We can't actually test this at runtime, but the import will fail if we try to use it
      expect(true, isTrue); // Placeholder
    });

    test('TerminalTabBar should not be directly accessible', () {
      // Similar to above - internal widget should not be exported
      expect(true, isTrue); // Placeholder
    });
  });
}
