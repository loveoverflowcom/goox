/// Shell configuration model
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Configuration for shell process execution
///
/// This class specifies the shell path, arguments, environment variables,
/// and working directory for a terminal session.
///
/// Example:
/// ```dart
/// final config = ShellConfig.bash();
/// final customConfig = ShellConfig(
///   shellPath: '/bin/zsh',
///   arguments: ['-l'],
///   environment: {'TERM': 'xterm-256color'},
///   workingDirectory: '/home/user/projects',
/// );
/// ```
@immutable
class ShellConfig {
  /// Creates a new shell configuration
  ///
  /// The [shellPath] must be an absolute path to a valid shell executable.
  /// The [workingDirectory] must exist if provided.
  /// Environment variable keys and values must be non-empty.
  const ShellConfig({
    required this.shellPath,
    this.arguments = const [],
    this.environment = const {},
    this.workingDirectory,
  });

  /// Path to the shell executable
  ///
  /// Must be an absolute path to a valid shell executable.
  final String shellPath;

  /// Command-line arguments for the shell
  ///
  /// These are passed as a list to prevent shell injection vulnerabilities.
  final List<String> arguments;

  /// Environment variables for the shell process
  ///
  /// Keys and values must be non-empty strings.
  final Map<String, String> environment;

  /// Working directory for the shell process
  ///
  /// If null, the shell will use its default working directory.
  /// If provided, the directory must exist.
  final String? workingDirectory;

  /// Creates a bash shell configuration
  ///
  /// Uses `/bin/bash` with login shell flag.
  factory ShellConfig.bash({
    String? workingDirectory,
    Map<String, String>? additionalEnvironment,
  }) {
    return ShellConfig(
      shellPath: '/bin/bash',
      arguments: const ['-l'],
      environment: {
        'TERM': 'xterm-256color',
        'COLORTERM': 'truecolor',
        ...?additionalEnvironment,
      },
      workingDirectory: workingDirectory,
    );
  }

  /// Creates a zsh shell configuration
  ///
  /// Uses `/bin/zsh` with login shell flag.
  factory ShellConfig.zsh({
    String? workingDirectory,
    Map<String, String>? additionalEnvironment,
  }) {
    return ShellConfig(
      shellPath: '/bin/zsh',
      arguments: const ['-l'],
      environment: {
        'TERM': 'xterm-256color',
        'COLORTERM': 'truecolor',
        ...?additionalEnvironment,
      },
      workingDirectory: workingDirectory,
    );
  }

  /// Creates a fish shell configuration
  ///
  /// Uses `/usr/bin/fish` with login shell flag.
  factory ShellConfig.fish({
    String? workingDirectory,
    Map<String, String>? additionalEnvironment,
  }) {
    return ShellConfig(
      shellPath: '/usr/bin/fish',
      arguments: const ['-l'],
      environment: {
        'TERM': 'xterm-256color',
        'COLORTERM': 'truecolor',
        ...?additionalEnvironment,
      },
      workingDirectory: workingDirectory,
    );
  }

  /// Creates a PowerShell configuration
  ///
  /// Uses `powershell.exe` without logo banner.
  factory ShellConfig.powershell({
    String? workingDirectory,
    Map<String, String>? additionalEnvironment,
  }) {
    return ShellConfig(
      shellPath: 'powershell.exe',
      arguments: const ['-NoLogo'],
      environment: {
        'TERM': 'xterm-256color',
        ...?additionalEnvironment,
      },
      workingDirectory: workingDirectory,
    );
  }

  /// Creates a cmd.exe configuration
  ///
  /// Uses `cmd.exe` for Windows command prompt.
  factory ShellConfig.cmd({
    String? workingDirectory,
    Map<String, String>? additionalEnvironment,
  }) {
    return ShellConfig(
      shellPath: 'cmd.exe',
      arguments: const [],
      environment: {
        'TERM': 'xterm-256color',
        ...?additionalEnvironment,
      },
      workingDirectory: workingDirectory,
    );
  }

  /// Creates shell configuration appropriate for the current platform
  ///
  /// Returns bash on Linux, zsh on macOS, and PowerShell on Windows.
  factory ShellConfig.forPlatform({
    String? workingDirectory,
    Map<String, String>? additionalEnvironment,
  }) {
    if (Platform.isLinux) {
      return ShellConfig.bash(
        workingDirectory: workingDirectory,
        additionalEnvironment: additionalEnvironment,
      );
    } else if (Platform.isMacOS) {
      return ShellConfig.zsh(
        workingDirectory: workingDirectory,
        additionalEnvironment: additionalEnvironment,
      );
    } else if (Platform.isWindows) {
      return ShellConfig.powershell(
        workingDirectory: workingDirectory,
        additionalEnvironment: additionalEnvironment,
      );
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported',
      );
    }
  }

  /// Validates the shell path
  ///
  /// Returns true if the shell path is non-empty and absolute.
  /// Does not check if the file exists.
  bool get isShellPathValid {
    if (shellPath.isEmpty) return false;
    return p.isAbsolute(shellPath);
  }

  /// Validates the working directory
  ///
  /// Returns true if working directory is null or exists.
  bool get isWorkingDirectoryValid {
    if (workingDirectory == null) return true;
    try {
      return Directory(workingDirectory!).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Validates environment variables
  ///
  /// Returns true if all keys and values are non-empty.
  bool get areEnvironmentVariablesValid {
    for (final entry in environment.entries) {
      if (entry.key.isEmpty || entry.value.isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// Validates the entire configuration
  ///
  /// Returns true if shell path, working directory, and environment
  /// variables are all valid.
  bool get isValid {
    return isShellPathValid &&
        isWorkingDirectoryValid &&
        areEnvironmentVariablesValid;
  }

  /// Validates and throws if invalid
  ///
  /// Throws [ArgumentError] if any validation fails.
  void validate() {
    if (shellPath.isEmpty) {
      throw ArgumentError('Shell path must not be empty');
    }

    if (!p.isAbsolute(shellPath)) {
      throw ArgumentError(
        'Shell path must be absolute, got: $shellPath',
      );
    }

    if (workingDirectory != null) {
      if (!Directory(workingDirectory!).existsSync()) {
        throw ArgumentError(
          'Working directory does not exist: $workingDirectory',
        );
      }
    }

    for (final entry in environment.entries) {
      if (entry.key.isEmpty) {
        throw ArgumentError('Environment variable key must not be empty');
      }
      if (entry.value.isEmpty) {
        throw ArgumentError(
          'Environment variable value must not be empty for key: ${entry.key}',
        );
      }
    }
  }

  /// Validates shell path exists on the file system
  ///
  /// Returns true if the shell executable exists and is a file.
  bool shellPathExists() {
    try {
      final file = File(shellPath);
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Creates a copy with updated fields
  ShellConfig copyWith({
    String? shellPath,
    List<String>? arguments,
    Map<String, String>? environment,
    String? workingDirectory,
  }) {
    return ShellConfig(
      shellPath: shellPath ?? this.shellPath,
      arguments: arguments ?? this.arguments,
      environment: environment ?? this.environment,
      workingDirectory: workingDirectory ?? this.workingDirectory,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShellConfig &&
        other.shellPath == shellPath &&
        listEquals(other.arguments, arguments) &&
        mapEquals(other.environment, environment) &&
        other.workingDirectory == workingDirectory;
  }

  @override
  int get hashCode => Object.hash(
        shellPath,
        Object.hashAll(arguments),
        Object.hashAll(environment.entries),
        workingDirectory,
      );

  @override
  String toString() {
    return 'ShellConfig('
        'shellPath: $shellPath, '
        'arguments: $arguments, '
        'environment: $environment, '
        'workingDirectory: $workingDirectory'
        ')';
  }
}
