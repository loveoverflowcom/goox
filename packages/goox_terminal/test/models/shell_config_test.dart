import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/goox_terminal.dart';

void main() {
  group('ShellConfig', () {
    group('constructor', () {
      test('creates instance with required shellPath', () {
        const config = ShellConfig(shellPath: '/bin/bash');
        expect(config.shellPath, equals('/bin/bash'));
        expect(config.arguments, isEmpty);
        expect(config.environment, isEmpty);
        expect(config.workingDirectory, isNull);
      });

      test('creates instance with all parameters', () {
        const config = ShellConfig(
          shellPath: '/bin/zsh',
          arguments: ['-l', '-i'],
          environment: {'TERM': 'xterm-256color'},
          workingDirectory: '/home/user',
        );
        expect(config.shellPath, equals('/bin/zsh'));
        expect(config.arguments, equals(['-l', '-i']));
        expect(config.environment, equals({'TERM': 'xterm-256color'}));
        expect(config.workingDirectory, equals('/home/user'));
      });
    });

    group('factory methods', () {
      test('bash() creates bash configuration', () {
        final config = ShellConfig.bash();
        expect(config.shellPath, equals('/bin/bash'));
        expect(config.arguments, equals(['-l']));
        expect(config.environment['TERM'], equals('xterm-256color'));
        expect(config.environment['COLORTERM'], equals('truecolor'));
      });

      test('bash() accepts workingDirectory', () {
        final config = ShellConfig.bash(workingDirectory: '/tmp');
        expect(config.workingDirectory, equals('/tmp'));
      });

      test('bash() accepts additionalEnvironment', () {
        final config = ShellConfig.bash(
          additionalEnvironment: {'MY_VAR': 'value'},
        );
        expect(config.environment['MY_VAR'], equals('value'));
        expect(config.environment['TERM'], equals('xterm-256color'));
      });

      test('zsh() creates zsh configuration', () {
        final config = ShellConfig.zsh();
        expect(config.shellPath, equals('/bin/zsh'));
        expect(config.arguments, equals(['-l']));
        expect(config.environment['TERM'], equals('xterm-256color'));
      });

      test('fish() creates fish configuration', () {
        final config = ShellConfig.fish();
        expect(config.shellPath, equals('/usr/bin/fish'));
        expect(config.arguments, equals(['-l']));
        expect(config.environment['TERM'], equals('xterm-256color'));
      });

      test('powershell() creates PowerShell configuration', () {
        final config = ShellConfig.powershell();
        expect(config.shellPath, equals('powershell.exe'));
        expect(config.arguments, equals(['-NoLogo']));
        expect(config.environment['TERM'], equals('xterm-256color'));
      });

      test('cmd() creates cmd.exe configuration', () {
        final config = ShellConfig.cmd();
        expect(config.shellPath, equals('cmd.exe'));
        expect(config.arguments, isEmpty);
        expect(config.environment['TERM'], equals('xterm-256color'));
      });

      test('forPlatform() creates appropriate config for Linux', () {
        final config = ShellConfig.forPlatform();
        if (Platform.isLinux) {
          expect(config.shellPath, equals('/bin/bash'));
        }
      }, skip: !Platform.isLinux);

      test('forPlatform() creates appropriate config for macOS', () {
        final config = ShellConfig.forPlatform();
        if (Platform.isMacOS) {
          expect(config.shellPath, equals('/bin/zsh'));
        }
      }, skip: !Platform.isMacOS);

      test('forPlatform() creates appropriate config for Windows', () {
        final config = ShellConfig.forPlatform();
        if (Platform.isWindows) {
          expect(config.shellPath, equals('powershell.exe'));
        }
      }, skip: !Platform.isWindows);
    });

    group('validation - shell path', () {
      test('isShellPathValid returns true for absolute path', () {
        const config = ShellConfig(shellPath: '/bin/bash');
        expect(config.isShellPathValid, isTrue);
      });

      test('isShellPathValid returns false for empty path', () {
        const config = ShellConfig(shellPath: '');
        expect(config.isShellPathValid, isFalse);
      });

      test('isShellPathValid returns false for relative path', () {
        const config = ShellConfig(shellPath: 'bash');
        expect(config.isShellPathValid, isFalse);
      });

      test('validate() throws for empty shell path', () {
        const config = ShellConfig(shellPath: '');
        expect(
          () => config.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Shell path must not be empty'),
            ),
          ),
        );
      });

      test('validate() throws for relative shell path', () {
        const config = ShellConfig(shellPath: 'bash');
        expect(
          () => config.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Shell path must be absolute'),
            ),
          ),
        );
      });
    });

    group('validation - working directory', () {
      test('isWorkingDirectoryValid returns true for null', () {
        const config = ShellConfig(shellPath: '/bin/bash');
        expect(config.isWorkingDirectoryValid, isTrue);
      });

      test('isWorkingDirectoryValid returns true for existing directory', () {
        final tempDir = Directory.systemTemp;
        final config = ShellConfig(
          shellPath: '/bin/bash',
          workingDirectory: tempDir.path,
        );
        expect(config.isWorkingDirectoryValid, isTrue);
      });

      test('isWorkingDirectoryValid returns false for non-existent directory',
          () {
        const config = ShellConfig(
          shellPath: '/bin/bash',
          workingDirectory: '/non/existent/directory',
        );
        expect(config.isWorkingDirectoryValid, isFalse);
      });

      test('validate() throws for non-existent working directory', () {
        const config = ShellConfig(
          shellPath: '/bin/bash',
          workingDirectory: '/non/existent/directory',
        );
        expect(
          () => config.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Working directory does not exist'),
            ),
          ),
        );
      });
    });

    group('validation - environment variables', () {
      test('areEnvironmentVariablesValid returns true for empty map', () {
        const config = ShellConfig(shellPath: '/bin/bash');
        expect(config.areEnvironmentVariablesValid, isTrue);
      });

      test('areEnvironmentVariablesValid returns true for valid variables', () {
        const config = ShellConfig(
          shellPath: '/bin/bash',
          environment: {'TERM': 'xterm', 'PATH': '/usr/bin'},
        );
        expect(config.areEnvironmentVariablesValid, isTrue);
      });

      test('areEnvironmentVariablesValid returns false for empty key', () {
        const config = ShellConfig(
          shellPath: '/bin/bash',
          environment: {'': 'value'},
        );
        expect(config.areEnvironmentVariablesValid, isFalse);
      });

      test('areEnvironmentVariablesValid returns false for empty value', () {
        const config = ShellConfig(
          shellPath: '/bin/bash',
          environment: {'KEY': ''},
        );
        expect(config.areEnvironmentVariablesValid, isFalse);
      });

      test('validate() throws for empty environment key', () {
        const config = ShellConfig(
          shellPath: '/bin/bash',
          environment: {'': 'value'},
        );
        expect(
          () => config.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Environment variable key must not be empty'),
            ),
          ),
        );
      });

      test('validate() throws for empty environment value', () {
        const config = ShellConfig(
          shellPath: '/bin/bash',
          environment: {'KEY': ''},
        );
        expect(
          () => config.validate(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Environment variable value must not be empty'),
            ),
          ),
        );
      });
    });

    group('validation - isValid', () {
      test('isValid returns true for valid configuration', () {
        final tempDir = Directory.systemTemp;
        final config = ShellConfig(
          shellPath: '/bin/bash',
          arguments: ['-l'],
          environment: {'TERM': 'xterm'},
          workingDirectory: tempDir.path,
        );
        expect(config.isValid, isTrue);
      });

      test('isValid returns false for invalid shell path', () {
        const config = ShellConfig(shellPath: 'bash');
        expect(config.isValid, isFalse);
      });

      test('isValid returns false for invalid working directory', () {
        const config = ShellConfig(
          shellPath: '/bin/bash',
          workingDirectory: '/non/existent',
        );
        expect(config.isValid, isFalse);
      });

      test('isValid returns false for invalid environment', () {
        const config = ShellConfig(
          shellPath: '/bin/bash',
          environment: {'': 'value'},
        );
        expect(config.isValid, isFalse);
      });
    });

    group('shellPathExists', () {
      test('returns true for existing shell', () {
        // Use a shell that should exist on the current platform
        final shellPath = Platform.isWindows ? 'C:\\Windows\\System32\\cmd.exe' : '/bin/sh';
        final config = ShellConfig(shellPath: shellPath);
        expect(config.shellPathExists(), isTrue);
      });

      test('returns false for non-existent shell', () {
        const config = ShellConfig(shellPath: '/non/existent/shell');
        expect(config.shellPathExists(), isFalse);
      });
    });

    group('copyWith', () {
      test('copies with updated shellPath', () {
        const original = ShellConfig(shellPath: '/bin/bash');
        final copy = original.copyWith(shellPath: '/bin/zsh');
        expect(copy.shellPath, equals('/bin/zsh'));
        expect(copy.arguments, equals(original.arguments));
      });

      test('copies with updated arguments', () {
        const original = ShellConfig(shellPath: '/bin/bash');
        final copy = original.copyWith(arguments: ['-l', '-i']);
        expect(copy.arguments, equals(['-l', '-i']));
        expect(copy.shellPath, equals(original.shellPath));
      });

      test('copies with updated environment', () {
        const original = ShellConfig(shellPath: '/bin/bash');
        final copy = original.copyWith(environment: {'NEW': 'value'});
        expect(copy.environment, equals({'NEW': 'value'}));
        expect(copy.shellPath, equals(original.shellPath));
      });

      test('copies with updated workingDirectory', () {
        const original = ShellConfig(shellPath: '/bin/bash');
        final copy = original.copyWith(workingDirectory: '/tmp');
        expect(copy.workingDirectory, equals('/tmp'));
        expect(copy.shellPath, equals(original.shellPath));
      });

      test('copies without changes when no parameters provided', () {
        const original = ShellConfig(
          shellPath: '/bin/bash',
          arguments: ['-l'],
          environment: {'TERM': 'xterm'},
          workingDirectory: '/home',
        );
        final copy = original.copyWith();
        expect(copy.shellPath, equals(original.shellPath));
        expect(copy.arguments, equals(original.arguments));
        expect(copy.environment, equals(original.environment));
        expect(copy.workingDirectory, equals(original.workingDirectory));
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        const config1 = ShellConfig(
          shellPath: '/bin/bash',
          arguments: ['-l'],
          environment: {'TERM': 'xterm'},
          workingDirectory: '/home',
        );
        const config2 = ShellConfig(
          shellPath: '/bin/bash',
          arguments: ['-l'],
          environment: {'TERM': 'xterm'},
          workingDirectory: '/home',
        );
        expect(config1, equals(config2));
      });

      test('different shellPath are not equal', () {
        const config1 = ShellConfig(shellPath: '/bin/bash');
        const config2 = ShellConfig(shellPath: '/bin/zsh');
        expect(config1, isNot(equals(config2)));
      });

      test('different arguments are not equal', () {
        const config1 = ShellConfig(shellPath: '/bin/bash', arguments: ['-l']);
        const config2 = ShellConfig(shellPath: '/bin/bash', arguments: ['-i']);
        expect(config1, isNot(equals(config2)));
      });

      test('different environment are not equal', () {
        const config1 = ShellConfig(
          shellPath: '/bin/bash',
          environment: {'A': '1'},
        );
        const config2 = ShellConfig(
          shellPath: '/bin/bash',
          environment: {'B': '2'},
        );
        expect(config1, isNot(equals(config2)));
      });

      test('different workingDirectory are not equal', () {
        const config1 = ShellConfig(
          shellPath: '/bin/bash',
          workingDirectory: '/home',
        );
        const config2 = ShellConfig(
          shellPath: '/bin/bash',
          workingDirectory: '/tmp',
        );
        expect(config1, isNot(equals(config2)));
      });

      test('hashCode is consistent', () {
        const config1 = ShellConfig(
          shellPath: '/bin/bash',
          arguments: ['-l'],
          environment: {'TERM': 'xterm'},
        );
        const config2 = ShellConfig(
          shellPath: '/bin/bash',
          arguments: ['-l'],
          environment: {'TERM': 'xterm'},
        );
        expect(config1.hashCode, equals(config2.hashCode));
      });
    });

    group('toString', () {
      test('returns formatted string with all fields', () {
        const config = ShellConfig(
          shellPath: '/bin/bash',
          arguments: ['-l'],
          environment: {'TERM': 'xterm'},
          workingDirectory: '/home',
        );
        final str = config.toString();
        expect(str, contains('ShellConfig'));
        expect(str, contains('/bin/bash'));
        expect(str, contains('[-l]'));
        expect(str, contains('TERM'));
        expect(str, contains('/home'));
      });
    });
  });
}
