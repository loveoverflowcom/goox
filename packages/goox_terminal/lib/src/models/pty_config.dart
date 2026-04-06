/// Configuration for creating a PTY session
library;

import 'pty_size.dart';

/// Configuration for creating a PTY session
///
/// This class defines all the parameters needed to create a new pseudo-terminal
/// session, including the shell to run, arguments, environment, and initial size.
///
/// Example:
/// ```dart
/// final config = PtyConfig(
///   shell: '/bin/bash',
///   args: ['-l'],
///   workingDirectory: '/home/user',
///   size: PtySize(rows: 24, cols: 80),
/// );
/// ```
class PtyConfig {
  /// Shell command to run (default: system shell)
  ///
  /// If null, the system default shell will be used:
  /// - Unix: $SHELL or /bin/sh
  /// - Windows: %COMSPEC% or cmd.exe
  final String? shell;

  /// Command arguments
  ///
  /// Arguments to pass to the shell command.
  final List<String> args;

  /// Working directory
  ///
  /// The directory where the shell process will start.
  /// If null, uses the current working directory.
  final String? workingDirectory;

  /// Environment variables
  ///
  /// Custom environment variables for the shell process.
  /// If null, inherits the parent process environment.
  final Map<String, String>? environment;

  /// Initial terminal size
  ///
  /// The initial size of the terminal in rows and columns.
  final PtySize size;

  /// Creates a new PTY configuration
  const PtyConfig({
    this.shell,
    this.args = const [],
    this.workingDirectory,
    this.environment,
    this.size = const PtySize(rows: 24, cols: 80),
  });

  /// Creates a configuration for the system default shell
  ///
  /// Example:
  /// ```dart
  /// final config = PtyConfig.defaultShell();
  /// ```
  factory PtyConfig.defaultShell({
    PtySize size = const PtySize(rows: 24, cols: 80),
  }) {
    return PtyConfig(size: size);
  }

  /// Creates a configuration for bash
  ///
  /// Example:
  /// ```dart
  /// final config = PtyConfig.bash(args: ['-l']);
  /// ```
  factory PtyConfig.bash({
    List<String> args = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    PtySize size = const PtySize(rows: 24, cols: 80),
  }) {
    return PtyConfig(
      shell: '/bin/bash',
      args: args,
      workingDirectory: workingDirectory,
      environment: environment,
      size: size,
    );
  }

  /// Creates a configuration for zsh
  ///
  /// Example:
  /// ```dart
  /// final config = PtyConfig.zsh();
  /// ```
  factory PtyConfig.zsh({
    List<String> args = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    PtySize size = const PtySize(rows: 24, cols: 80),
  }) {
    return PtyConfig(
      shell: '/bin/zsh',
      args: args,
      workingDirectory: workingDirectory,
      environment: environment,
      size: size,
    );
  }

  /// Validates the configuration
  ///
  /// Throws [ArgumentError] if the configuration is invalid.
  void validate() {
    if (size.rows <= 0 || size.cols <= 0) {
      throw ArgumentError('Terminal size must be positive');
    }
  }

  @override
  String toString() {
    return 'PtyConfig(shell: $shell, args: $args, '
        'workingDirectory: $workingDirectory, size: $size)';
  }
}
