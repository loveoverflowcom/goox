// ignore_for_file: avoid_print

import 'dart:io';

/// Debug utilities for terminal
class GooxTerminalDebug {
  /// Print shell information for debugging
  static void printShellInfo() {
    print('=== Terminal Debug Info ===');
    print('Platform: ${Platform.operatingSystem}');
    print('SHELL env: ${Platform.environment['SHELL']}');
    print('HOME env: ${Platform.environment['HOME']}');
    print('PATH env: ${Platform.environment['PATH']}');
    print('TERM env: ${Platform.environment['TERM']}');

    if (Platform.isMacOS || Platform.isLinux) {
      print('\nChecking common shells:');
      final shells = [
        '/bin/bash',
        '/bin/zsh',
        '/bin/sh',
        '/usr/bin/bash',
        '/usr/bin/zsh',
      ];

      for (final shell in shells) {
        final exists = File(shell).existsSync();
        print('  $shell: ${exists ? "✓" : "✗"}');
      }
    }

    print('========================');
  }

  /// Get detailed shell path
  static String getShellPath() {
    if (Platform.isMacOS || Platform.isLinux) {
      final shell = Platform.environment['SHELL'];
      if (shell != null && shell.isNotEmpty) {
        return shell;
      }
      
      // Try common shells with full paths
      const fallbacks = ['/bin/bash', '/bin/zsh', '/bin/sh'];
      for (final path in fallbacks) {
        if (File(path).existsSync()) {
          return path;
        }
      }
      
      return '/bin/sh';  // Last resort
    }

    if (Platform.isWindows) {
      return 'cmd.exe';
    }

    return 'sh';
  }
}
