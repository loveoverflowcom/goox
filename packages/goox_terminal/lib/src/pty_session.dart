/// PTY Session - Represents an active PTY session
library;

import 'dart:typed_data';

import 'package:goox_terminal/src/models.dart';

/// Represents an active PTY session
///
/// A [PtySession] provides methods to interact with a running pseudo-terminal,
/// including writing input, reading output, resizing, and sending signals.
///
/// Do not create instances directly. Use [PtyManager.createSession] instead.
class PtySession {
  /// Unique session identifier
  final String id;

  /// Configuration used to create this session
  final PtyConfig config;

  /// Creates a new PTY session
  ///
  /// This constructor is internal. Use [PtyManager.createSession] to create sessions.
  PtySession({
    required this.id,
    required this.config,
  });

  /// Write string data to the PTY
  ///
  /// Writes the given [data] string to the PTY input.
  /// Returns the number of bytes written.
  ///
  /// Example:
  /// ```dart
  /// await session.write('ls -la\n');
  /// ```
  ///
  /// Throws [PtyIOException] if write fails.
  Future<int> write(String data) async {
    // TODO: Implement using Rust FFI
    throw UnimplementedError('write not yet implemented');
  }

  /// Write binary data to the PTY
  ///
  /// Writes the given binary [data] to the PTY input.
  /// Returns the number of bytes written.
  ///
  /// Example:
  /// ```dart
  /// // Send Ctrl+C
  /// await session.writeBytes(Uint8List.fromList([0x03]));
  /// ```
  ///
  /// Throws [PtyIOException] if write fails.
  Future<int> writeBytes(Uint8List data) async {
    // TODO: Implement using Rust FFI
    throw UnimplementedError('writeBytes not yet implemented');
  }

  /// Get the output stream
  ///
  /// Returns a broadcast stream that emits output data from the PTY.
  /// The stream emits [Uint8List] chunks as they become available.
  ///
  /// Example:
  /// ```dart
  /// session.outputStream.listen((data) {
  ///   print(utf8.decode(data));
  /// });
  /// ```
  Stream<Uint8List> get outputStream {
    // TODO: Implement using Rust FFI
    throw UnimplementedError('outputStream not yet implemented');
  }

  /// Resize the terminal
  ///
  /// Changes the terminal size to [rows] rows and [cols] columns.
  /// This sends a SIGWINCH signal to the child process.
  ///
  /// Example:
  /// ```dart
  /// await session.resize(30, 100);
  /// ```
  ///
  /// Throws [PtyException] if resize fails.
  Future<void> resize(int rows, int cols) async {
    // TODO: Implement using Rust FFI
    throw UnimplementedError('resize not yet implemented');
  }

  /// Get current terminal size
  ///
  /// Returns the current size of the terminal.
  ///
  /// Example:
  /// ```dart
  /// final size = await session.getSize();
  /// print('Terminal: ${size.rows}x${size.cols}');
  /// ```
  Future<PtySize> getSize() async {
    // TODO: Implement using Rust FFI
    throw UnimplementedError('getSize not yet implemented');
  }

  /// Send a signal to the process
  ///
  /// Sends the given [signal] to the child process.
  ///
  /// Example:
  /// ```dart
  /// // Send Ctrl+C
  /// await session.sendSignal(PtySignal.sigint);
  /// ```
  ///
  /// Throws [PtyException] if signal sending fails.
  Future<void> sendSignal(PtySignal signal) async {
    // TODO: Implement using Rust FFI
    throw UnimplementedError('sendSignal not yet implemented');
  }

  /// Get process ID
  ///
  /// Returns the PID of the child process, or null if not available.
  int? get pid {
    // TODO: Implement using Rust FFI
    return null;
  }

  /// Get exit code
  ///
  /// Returns the exit code of the process if it has exited, or null if still running.
  int? get exitCode {
    // TODO: Implement using Rust FFI
    return null;
  }

  /// Wait for the process to exit
  ///
  /// Waits for the child process to exit and returns its exit code.
  ///
  /// Example:
  /// ```dart
  /// final exitCode = await session.waitForExit();
  /// print('Process exited with code: $exitCode');
  /// ```
  Future<int> waitForExit() async {
    // TODO: Implement using Rust FFI
    throw UnimplementedError('waitForExit not yet implemented');
  }

  /// Close the session
  ///
  /// Closes this PTY session and cleans up all resources.
  /// This will terminate the child process if still running.
  ///
  /// Example:
  /// ```dart
  /// await session.close();
  /// ```
  Future<void> close() async {
    // TODO: Implement using Rust FFI
    throw UnimplementedError('close not yet implemented');
  }
}
