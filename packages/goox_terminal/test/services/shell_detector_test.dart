import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/src/services/shell_detector.dart';
import 'package:goox_terminal/src/models/shell_config.dart';

void main() {
  group('ShellDetector', () {
    group('detectDefaultShell()', () {
      test('returns valid shell config on Linux', () async {
        // This test will only run on Linux
        if (!Platform.isLinux) {
          return;
        }

        // Act
        final config = await ShellDetector.detectDefaultShell();

        // Assert
        expect(config.shellPath, isNotEmpty);
        expect(config.shellPath, anyOf(
          contains('bash'),
          contains('zsh'),
          contains('sh'),
        ));
        expect(config.arguments, contains('-l')); // Login shell flag
        expect(config.environment['TERM'], 'xterm-256color');
        expect(config.environment['COLORTERM'], 'truecolor');
      });

      test('returns valid shell config on macOS', () async {
        // This test will only run on macOS
        if (!Platform.isMacOS) {
          return;
        }

        // Act
        final config = await ShellDetector.detectDefaultShell();

        // Assert
        expect(config.shellPath, isNotEmpty);
        expect(config.shellPath, anyOf(
          contains('zsh'),
          contains('bash'),
          contains('sh'),
        ));
        expect(config.arguments, contains('-l')); // Login shell flag
        expect(config.environment['TERM'], 'xterm-256color');
        expect(config.environment['COLORTERM'], 'truecolor');
      });

      test('returns valid shell config on Windows', () async {
        // This test will only run on Windows
        if (!Platform.isWindows) {
          return;
        }

        // Act
        final config = await ShellDetector.detectDefaultShell();

        // Assert
        expect(config.shellPath, isNotEmpty);
        expect(
          config.shellPath,
          anyOf(
            equals('pwsh.exe'),
            equals('powershell.exe'),
            equals('cmd.exe'),
          ),
        );
        expect(config.environment['TERM'], 'xterm-256color');
        
        // PowerShell variants should have -NoLogo flag
        if (config.shellPath.contains('powershell') || 
            config.shellPath.contains('pwsh')) {
          expect(config.arguments, contains('-NoLogo'));
        }
      });

      test('respects SHELL environment variable on Unix', () async {
        // Skip on Windows
        if (Platform.isWindows) {
          return;
        }

        // The detector should check $SHELL first
        final shellEnv = Platform.environment['SHELL'];
        if (shellEnv != null && shellEnv.isNotEmpty) {
          final config = await ShellDetector.detectDefaultShell();
          
          // If SHELL is set and the shell exists, it should be used
          if (File(shellEnv).existsSync()) {
            expect(config.shellPath, equals(shellEnv));
          }
        }
      });
    });

    group('detectAvailableShells()', () {
      test('returns list of available shells on Linux', () async {
        // This test will only run on Linux
        if (!Platform.isLinux) {
          return;
        }

        // Act
        final shells = await ShellDetector.detectAvailableShells();

        // Assert
        expect(shells, isNotEmpty);
        expect(shells, isA<List<ShellConfig>>());
        
        // At least one shell should be available
        expect(shells.length, greaterThan(0));
        
        // All shells should have valid paths
        for (final shell in shells) {
          expect(shell.shellPath, isNotEmpty);
          expect(shell.shellPath, startsWith('/'));
        }
      });

      test('returns list of available shells on macOS', () async {
        // This test will only run on macOS
        if (!Platform.isMacOS) {
          return;
        }

        // Act
        final shells = await ShellDetector.detectAvailableShells();

        // Assert
        expect(shells, isNotEmpty);
        expect(shells, isA<List<ShellConfig>>());
        
        // At least one shell should be available
        expect(shells.length, greaterThan(0));
        
        // All shells should have valid paths
        for (final shell in shells) {
          expect(shell.shellPath, isNotEmpty);
          expect(shell.shellPath, startsWith('/'));
        }
      });

      test('returns list of available shells on Windows', () async {
        // This test will only run on Windows
        if (!Platform.isWindows) {
          return;
        }

        // Act
        final shells = await ShellDetector.detectAvailableShells();

        // Assert
        expect(shells, isNotEmpty);
        expect(shells, isA<List<ShellConfig>>());
        
        // At least one shell should be available (cmd.exe should always exist)
        expect(shells.length, greaterThan(0));
        
        // All shells should have valid paths
        for (final shell in shells) {
          expect(shell.shellPath, isNotEmpty);
          expect(shell.shellPath, endsWith('.exe'));
        }
      });

      test('all returned shells have proper configuration', () async {
        // Act
        final shells = await ShellDetector.detectAvailableShells();

        // Assert
        for (final shell in shells) {
          expect(shell.shellPath, isNotEmpty);
          expect(shell.environment, isNotEmpty);
          expect(shell.environment['TERM'], 'xterm-256color');
          
          // Unix shells should have COLORTERM
          if (!Platform.isWindows) {
            expect(shell.environment['COLORTERM'], 'truecolor');
          }
        }
      });
    });

    group('isShellAvailable()', () {
      test('returns true for existing absolute path on Unix', () {
        // Skip on Windows
        if (Platform.isWindows) {
          return;
        }

        // Act & Assert
        // /bin/sh should exist on all Unix systems
        expect(ShellDetector.isShellAvailable('/bin/sh'), isTrue);
      });

      test('returns false for non-existing absolute path', () {
        // Act & Assert
        final nonExistentPath = Platform.isWindows 
            ? 'C:\\nonexistent\\shell.exe'
            : '/nonexistent/shell';
        expect(ShellDetector.isShellAvailable(nonExistentPath), isFalse);
      });

      test('returns false for empty path', () {
        // Act & Assert
        expect(ShellDetector.isShellAvailable(''), isFalse);
      });

      test('returns false for relative paths', () {
        // Act & Assert
        // Relative paths should return false (they need PATH checking)
        expect(ShellDetector.isShellAvailable('bash'), isFalse);
        expect(ShellDetector.isShellAvailable('cmd.exe'), isFalse);
      });

      test('handles file system exceptions gracefully', () {
        // Act & Assert
        // Should not throw, just return false
        expect(
          () => ShellDetector.isShellAvailable('/invalid\x00path'),
          returnsNormally,
        );
      });
    });

    group('Platform-specific defaults', () {
      test('Linux defaults to bash or zsh', () async {
        if (!Platform.isLinux) {
          return;
        }

        final config = await ShellDetector.detectDefaultShell();
        expect(config.shellPath, anyOf(
          contains('bash'),
          contains('zsh'),
          contains('sh'),
        ));
      });

      test('macOS defaults to zsh', () async {
        if (!Platform.isMacOS) {
          return;
        }

        final config = await ShellDetector.detectDefaultShell();
        // macOS should prefer zsh, but may fall back to bash or sh
        expect(config.shellPath, anyOf(
          contains('zsh'),
          contains('bash'),
          contains('sh'),
        ));
      });

      test('Windows defaults to PowerShell or cmd', () async {
        if (!Platform.isWindows) {
          return;
        }

        final config = await ShellDetector.detectDefaultShell();
        expect(config.shellPath, anyOf(
          equals('pwsh.exe'),
          equals('powershell.exe'),
          equals('cmd.exe'),
        ));
      });
    });
  });
}
