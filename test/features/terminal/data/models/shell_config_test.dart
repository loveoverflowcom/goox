import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/terminal/data/models/shell_config.dart';

void main() {
  group('ShellConfig', () {
    group('forPlatform', () {
      test('should return bash configuration on Linux', () {
        // Note: This test will only pass on Linux
        if (Platform.isLinux) {
          // Act
          final config = ShellConfig.forPlatform();

          // Assert
          expect(config.executable, 'bash');
          expect(config.args, contains('-l'));
          expect(config.environment['TERM'], 'xterm-256color');
          expect(config.environment['COLORTERM'], 'truecolor');
        }
      });

      test('should return zsh configuration on macOS', () {
        // Note: This test will only pass on macOS
        if (Platform.isMacOS) {
          // Act
          final config = ShellConfig.forPlatform();

          // Assert
          expect(config.executable, 'zsh');
          expect(config.args, contains('-l'));
          expect(config.environment['TERM'], 'xterm-256color');
          expect(config.environment['COLORTERM'], 'truecolor');
        }
      });

      test('should return PowerShell configuration on Windows', () {
        // Note: This test will only pass on Windows
        if (Platform.isWindows) {
          // Act
          final config = ShellConfig.forPlatform();

          // Assert
          expect(config.executable, 'powershell.exe');
          expect(config.args, contains('-NoLogo'));
          expect(config.environment['TERM'], 'xterm-256color');
        }
      });

      test('should include login shell flag for Unix platforms', () {
        // Note: This test will only pass on Unix-like platforms
        if (Platform.isLinux || Platform.isMacOS) {
          // Act
          final config = ShellConfig.forPlatform();

          // Assert
          expect(config.args, contains('-l'));
        }
      });

      test('should set TERM environment variable for all platforms', () {
        // Act
        final config = ShellConfig.forPlatform();

        // Assert
        expect(config.environment.containsKey('TERM'), true);
        expect(config.environment['TERM'], 'xterm-256color');
      });

      test('should set COLORTERM for Unix platforms', () {
        // Note: This test will only pass on Unix-like platforms
        if (Platform.isLinux || Platform.isMacOS) {
          // Act
          final config = ShellConfig.forPlatform();

          // Assert
          expect(config.environment.containsKey('COLORTERM'), true);
          expect(config.environment['COLORTERM'], 'truecolor');
        }
      });
    });

    group('copyWith', () {
      test('should create copy with updated executable', () {
        // Arrange
        const config = ShellConfig(
          executable: 'bash',
          args: ['-l'],
          environment: {'TERM': 'xterm'},
        );

        // Act
        final result = config.copyWith(executable: 'zsh');

        // Assert
        expect(result.executable, 'zsh');
        expect(result.args, config.args);
        expect(result.environment, config.environment);
      });

      test('should create copy with updated args', () {
        // Arrange
        const config = ShellConfig(
          executable: 'bash',
          args: ['-l'],
          environment: {'TERM': 'xterm'},
        );

        // Act
        final result = config.copyWith(args: ['-i', '-l']);

        // Assert
        expect(result.args, ['-i', '-l']);
        expect(result.executable, config.executable);
        expect(result.environment, config.environment);
      });

      test('should create copy with updated environment', () {
        // Arrange
        const config = ShellConfig(
          executable: 'bash',
          args: ['-l'],
          environment: {'TERM': 'xterm'},
        );

        // Act
        final result = config.copyWith(
          environment: {'TERM': 'xterm-256color', 'COLORTERM': 'truecolor'},
        );

        // Assert
        expect(result.environment['TERM'], 'xterm-256color');
        expect(result.environment['COLORTERM'], 'truecolor');
        expect(result.executable, config.executable);
        expect(result.args, config.args);
      });
    });

    group('platform-specific configurations', () {
      test('Linux config should use bash with login shell', () {
        // Arrange
        const expectedExecutable = 'bash';
        const expectedArgs = ['-l'];

        // Act
        if (Platform.isLinux) {
          final config = ShellConfig.forPlatform();

          // Assert
          expect(config.executable, expectedExecutable);
          expect(config.args, expectedArgs);
        }
      });

      test('macOS config should use zsh with login shell', () {
        // Arrange
        const expectedExecutable = 'zsh';
        const expectedArgs = ['-l'];

        // Act
        if (Platform.isMacOS) {
          final config = ShellConfig.forPlatform();

          // Assert
          expect(config.executable, expectedExecutable);
          expect(config.args, expectedArgs);
        }
      });

      test('Windows config should use PowerShell with NoLogo flag', () {
        // Arrange
        const expectedExecutable = 'powershell.exe';
        const expectedArgs = ['-NoLogo'];

        // Act
        if (Platform.isWindows) {
          final config = ShellConfig.forPlatform();

          // Assert
          expect(config.executable, expectedExecutable);
          expect(config.args, expectedArgs);
        }
      });
    });
  });
}
