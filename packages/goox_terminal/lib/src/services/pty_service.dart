import 'dart:async';

import 'package:goox_terminal/src/models/shell_config.dart';

/// Abstract interface for PTY (pseudo-terminal) service
/// 
/// This service manages the lifecycle of PTY processes, which are used to run
/// shell processes with proper terminal I/O handling.
abstract class PTYService {
  /// Create a new PTY with shell process
  /// 
  /// [shellConfig] - Configuration for the shell to spawn
  /// [workingDirectory] - Initial working directory for the shell
  /// 
  /// Returns a [PTYProcess] instance representing the spawned process
  /// 
  /// Throws [PTYException] if PTY creation fails
  Future<PTYProcess> createPTY({
    required ShellConfig shellConfig,
    required String workingDirectory,
  });

  /// Write input to PTY
  /// 
  /// [process] - The PTY process to write to
  /// [input] - The text input to send to the shell
  /// 
  /// Throws [PTYException] if write fails
  Future<void> write(PTYProcess process, String input);

  /// Terminate PTY process
  /// 
  /// [process] - The PTY process to terminate
  /// [force] - If true, force kill immediately. If false, attempt graceful shutdown
  /// 
  /// When [force] is false, waits up to 2 seconds for graceful termination
  /// before force killing the process.
  Future<void> terminate(PTYProcess process, {bool force = false});

  /// Resize PTY dimensions
  /// 
  /// [process] - The PTY process to resize
  /// [cols] - Number of columns (width in characters)
  /// [rows] - Number of rows (height in lines)
  /// 
  /// Throws [PTYException] if resize fails
  Future<void> resize(PTYProcess process, int cols, int rows);
}

/// Represents a PTY process with its I/O streams
class PTYProcess {
  const PTYProcess({
    required this.pid,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.nativeHandle,
  });

  /// Process ID of the shell process
  final int pid;

  /// Stream of stdout output from the shell
  final Stream<String> stdout;

  /// Stream of stderr output from the shell
  final Stream<String> stderr;

  /// Future that completes with the exit code when the process terminates
  final Future<int> exitCode;

  /// Platform-specific PTY handle (internal use by implementation)
  final dynamic nativeHandle;
}

/// Exception thrown by PTY operations
class PTYException implements Exception {
  const PTYException(this.message, [this.cause]);

  final String message;
  final dynamic cause;

  @override
  String toString() => 'PTYException: $message${cause != null ? ' ($cause)' : ''}';
}
