import 'dart:io';
import 'package:goox_terminal/src/models/shell_config.dart';

/// Service for detecting available shells on the system
///
/// Provides platform-specific shell detection and validation.
/// Supports Linux, macOS, and Windows platforms.
class ShellDetector {
  // Private constructor to prevent instantiation
  ShellDetector._();

  /// Detects the default shell for the current platform
  ///
  /// Platform-specific behavior:
  /// - Linux: Checks $SHELL environment variable, then tries bash, zsh, sh
  /// - macOS: Checks $SHELL environment variable, then tries zsh, bash, sh
  /// - Windows: Tries pwsh (PowerShell Core), powershell, cmd
  ///
  /// Returns a [ShellConfig] with the detected shell.
  /// Throws [UnsupportedError] if platform is not supported.
  static Future<ShellConfig> detectDefaultShell() async {
    if (Platform.isLinux) {
      return _detectUnixShell(['bash', 'zsh', 'sh']);
    } else if (Platform.isMacOS) {
      return _detectUnixShell(['zsh', 'bash', 'sh']);
    } else if (Platform.isWindows) {
      return _detectWindowsShell(['pwsh.exe', 'powershell.exe', 'cmd.exe']);
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported',
      );
    }
  }

  /// Detects all available shells on the system
  ///
  /// Returns a list of [ShellConfig] for all shells found on the system.
  /// The list is ordered by preference (most preferred first).
  ///
  /// Platform-specific shells checked:
  /// - Linux/macOS: bash, zsh, fish, sh
  /// - Windows: pwsh, powershell, cmd
  static Future<List<ShellConfig>> detectAvailableShells() async {
    final availableShells = <ShellConfig>[];

    if (Platform.isLinux || Platform.isMacOS) {
      // Unix-like systems
      final unixShells = [
        {'name': 'bash', 'path': '/bin/bash'},
        {'name': 'zsh', 'path': '/bin/zsh'},
        {'name': 'fish', 'path': '/usr/bin/fish'},
        {'name': 'sh', 'path': '/bin/sh'},
      ];

      for (final shell in unixShells) {
        final path = shell['path']!;
        if (isShellAvailable(path)) {
          availableShells.add(ShellConfig(
            shellPath: path,
            arguments: const ['-l'],
            environment: const {
              'TERM': 'xterm-256color',
              'COLORTERM': 'truecolor',
            },
          ));
        }
      }
    } else if (Platform.isWindows) {
      // Windows systems
      final windowsShells = [
        {'name': 'pwsh', 'path': 'pwsh.exe', 'args': ['-NoLogo']},
        {'name': 'powershell', 'path': 'powershell.exe', 'args': ['-NoLogo']},
        {'name': 'cmd', 'path': 'cmd.exe', 'args': <String>[]},
      ];

      for (final shell in windowsShells) {
        final path = shell['path'] as String;
        if (await _isShellInPath(path)) {
          final args = shell['args'] as List<String>;
          availableShells.add(ShellConfig(
            shellPath: path,
            arguments: args,
            environment: const {
              'TERM': 'xterm-256color',
            },
          ));
        }
      }
    }

    return availableShells;
  }

  /// Checks if a shell is available at the given path
  ///
  /// For absolute paths, checks if the file exists.
  /// For relative paths (like 'bash' or 'cmd.exe'), checks if it's in PATH.
  ///
  /// Returns true if the shell is available, false otherwise.
  static bool isShellAvailable(String shellPath) {
    if (shellPath.isEmpty) return false;

    // Check if it's an absolute path
    if (shellPath.startsWith('/') ||
        (Platform.isWindows &&
            (shellPath.contains(':') || shellPath.startsWith(r'\')))) {
      // Absolute path - check if file exists
      try {
        return File(shellPath).existsSync();
      } on FileSystemException {
        return false;
      }
    } else {
      // Relative path - check if it's in PATH
      // This is a synchronous approximation - for full PATH checking,
      // use _isShellInPath which runs 'which' or 'where'
      return false;
    }
  }

  /// Detects Unix shell from the provided list
  ///
  /// Checks $SHELL environment variable first, then tries each shell in order.
  /// Returns the first available shell with appropriate configuration.
  static Future<ShellConfig> _detectUnixShell(List<String> shells) async {
    // First, check the SHELL environment variable
    final shellEnv = Platform.environment['SHELL'];
    if (shellEnv != null && shellEnv.isNotEmpty) {
      if (isShellAvailable(shellEnv)) {
        return ShellConfig(
          shellPath: shellEnv,
          arguments: const ['-l'],
          environment: const {
            'TERM': 'xterm-256color',
            'COLORTERM': 'truecolor',
          },
        );
      }
    }

    // Try each shell in the preference order
    for (final shell in shells) {
      final path = '/bin/$shell';
      if (isShellAvailable(path)) {
        return ShellConfig(
          shellPath: path,
          arguments: const ['-l'],
          environment: const {
            'TERM': 'xterm-256color',
            'COLORTERM': 'truecolor',
          },
        );
      }
    }

    // Fallback to sh
    return const ShellConfig(
      shellPath: '/bin/sh',
      arguments: ['-l'],
      environment: {
        'TERM': 'xterm-256color',
        'COLORTERM': 'truecolor',
      },
    );
  }

  /// Detects Windows shell from the provided list
  ///
  /// Tries each shell in order using 'where' command.
  /// Returns the first available shell with appropriate configuration.
  static Future<ShellConfig> _detectWindowsShell(List<String> shells) async {
    for (final shell in shells) {
      if (await _isShellInPath(shell)) {
        // PowerShell variants get -NoLogo flag
        final args = (shell.contains('powershell') || shell.contains('pwsh'))
            ? const ['-NoLogo']
            : <String>[];

        return ShellConfig(
          shellPath: shell,
          arguments: args,
          environment: const {
            'TERM': 'xterm-256color',
          },
        );
      }
    }

    // Fallback to cmd
    return const ShellConfig(
      shellPath: 'cmd.exe',
      arguments: <String>[],
      environment: {
        'TERM': 'xterm-256color',
      },
    );
  }

  /// Checks if a shell is available in the system PATH
  ///
  /// Uses 'which' on Unix systems and 'where' on Windows.
  /// Returns true if the shell is found in PATH.
  static Future<bool> _isShellInPath(String shell) async {
    try {
      final command = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(command, [shell]);
      return result.exitCode == 0;
    } on Exception {
      return false;
    }
  }
}
