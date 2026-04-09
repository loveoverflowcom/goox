import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:goox_terminal/src/models/shell_config.dart';
import 'package:goox_terminal/src/services/pty_service.dart';

/// Implementation of PTYService using flutter_pty package
/// 
/// This implementation provides cross-platform PTY support for Linux, macOS, and Windows.
/// The flutter_pty package handles platform-specific PTY implementations internally.
class PTYServiceImpl implements PTYService {
  /// Graceful termination timeout in seconds
  static const int _terminationTimeoutSeconds = 2;

  @override
  Future<PTYProcess> createPTY({
    required ShellConfig shellConfig,
    required String workingDirectory,
  }) async {
    try {
      // Create PTY instance
      final pty = Pty.start(
        shellConfig.shellPath,
        arguments: shellConfig.arguments,
        workingDirectory: workingDirectory,
        environment: {
          ...shellConfig.environment,
          'TERM': 'xterm-256color', // Ensure TERM is set
        },
      );

      // Create stdout stream controller
      final stdoutController = StreamController<String>();
      final stderrController = StreamController<String>();

      // Listen to PTY output and decode as UTF-8
      // The output stream is already a Stream<List<int>>, so we decode it
      final outputStream = pty.output.map((data) => utf8.decode(data));
      
      outputStream.listen(
        stdoutController.add,
        onError: stdoutController.addError,
        onDone: stdoutController.close,
      );

      // Create exit code future
      final exitCodeCompleter = Completer<int>();
      unawaited(
        pty.exitCode.then((code) {
          exitCodeCompleter.complete(code);
          unawaited(stderrController.close());
        }).catchError((Object error) {
          exitCodeCompleter.completeError(error);
          unawaited(stderrController.close());
        }),
      );

      return PTYProcess(
        pid: pty.pid,
        stdout: stdoutController.stream,
        stderr: stderrController.stream, // flutter_pty combines stdout/stderr
        exitCode: exitCodeCompleter.future,
        nativeHandle: pty,
      );
    } catch (e) {
      throw PTYException('Failed to create PTY', e);
    }
  }

  @override
  Future<void> write(PTYProcess process, String input) async {
    try {
      final pty = process.nativeHandle as Pty;
      pty.write(utf8.encode(input));
    } catch (e) {
      throw PTYException('Failed to write to PTY', e);
    }
  }

  @override
  Future<void> terminate(PTYProcess process, {bool force = false}) async {
    try {
      final pty = process.nativeHandle as Pty;

      if (force) {
        // Force kill immediately
        pty.kill();
        return;
      }

      // Attempt graceful termination
      // Send SIGTERM on Unix or close handle on Windows
      if (Platform.isWindows) {
        // On Windows, we need to force kill as there's no graceful SIGTERM
        pty.kill();
      } else {
        // On Unix, send SIGTERM
        Process.killPid(process.pid);

        // Wait up to 2 seconds for graceful exit
        try {
          await process.exitCode.timeout(
            const Duration(seconds: _terminationTimeoutSeconds),
          );
        } on TimeoutException {
          // Timeout expired, force kill
          pty.kill();
        }
      }
    } catch (e) {
      throw PTYException('Failed to terminate PTY', e);
    }
  }

  @override
  Future<void> resize(PTYProcess process, int cols, int rows) async {
    try {
      final pty = process.nativeHandle as Pty;
      pty.resize(rows, cols);
    } catch (e) {
      throw PTYException('Failed to resize PTY', e);
    }
  }
}
