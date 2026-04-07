import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

import '../exceptions/pty_exception.dart';
import '../models/pty_signal.dart';
import '../models/pty_size.dart';
import '../models/shell_config.dart';
import '../models/terminal_status.dart';

/// Controller for managing a single terminal session.
///
/// This controller connects xterm (terminal emulator) with flutter_pty
/// (PTY backend) and manages the complete lifecycle of a terminal session.
///
/// The controller handles:
/// - Creating and managing xterm Terminal instance
/// - Creating and managing flutter_pty Pty instance
/// - Connecting PTY output to xterm input
/// - Connecting xterm output to PTY input
/// - Terminal resize events
/// - Status tracking (initializing, running, exited, error)
/// - Terminal title updates
/// - Resource cleanup on disposal
///
/// Example:
/// ```dart
/// final controller = TerminalController(
///   id: 'terminal-1',
///   shellConfig: ShellConfig.bash(),
///   initialSize: PtySize.defaultSize,
/// );
/// await controller.initialize();
/// ```
class TerminalController {
  /// Creates a new terminal controller.
  ///
  /// The controller must be initialized by calling [initialize] before use.
  ///
  /// Parameters:
  /// - [id]: Unique identifier for this terminal session
  /// - [shellConfig]: Configuration for the shell process
  /// - [initialSize]: Initial terminal dimensions
  TerminalController({
    required this.id,
    required ShellConfig shellConfig,
    required PtySize initialSize,
  })  : _shellConfig = shellConfig,
        _size = initialSize,
        _terminal = Terminal(maxLines: 1000),
        _statusController = StreamController<TerminalStatus>.broadcast(),
        _titleNotifier = ValueNotifier<String>(_defaultTitle);

  /// Unique identifier for this terminal session.
  final String id;

  /// Shell configuration for this terminal.
  final ShellConfig _shellConfig;

  /// Current terminal size.
  PtySize _size;

  /// The xterm terminal instance.
  ///
  /// This handles terminal emulation, rendering, and input processing.
  Terminal get terminal => _terminal;
  final Terminal _terminal;

  /// The PTY process instance.
  ///
  /// This is null until [initialize] is called successfully.
  Pty? _pty;

  /// Current terminal status.
  TerminalStatus get status => _status;
  TerminalStatus _status = TerminalStatus.initializing;

  /// Terminal title.
  ///
  /// This can be updated by the shell via ANSI escape sequences.
  String get title => _titleNotifier.value;

  /// Process ID of the shell process.
  ///
  /// Returns null if the process is not running.
  int? get pid => _pty?.pid;

  /// Exit code of the shell process.
  ///
  /// Returns null if the process has not exited.
  int? get exitCode => _exitCode;
  int? _exitCode;

  /// Stream of status changes.
  ///
  /// Emits the current status immediately when subscribed,
  /// then emits new status values whenever the status changes.
  Stream<TerminalStatus> get statusStream => _statusController.stream;
  final StreamController<TerminalStatus> _statusController;

  /// Notifier for title changes.
  ///
  /// Use this to reactively observe title updates.
  ValueListenable<String> get titleNotifier => _titleNotifier;
  final ValueNotifier<String> _titleNotifier;

  /// Subscription to PTY output stream.
  StreamSubscription<List<int>>? _outputSubscription;

  /// Default title format.
  static const String _defaultTitle = 'Terminal';

  /// Regular expression for parsing OSC (Operating System Command) title escape sequences.
  ///
  /// Matches patterns like:
  /// - ESC ] 0 ; title BEL (where BEL is \x07)
  /// - ESC ] 0 ; title ST (where ST is ESC \)
  /// - ESC ] 2 ; title BEL
  /// - ESC ] 2 ; title ST
  ///
  /// OSC 0 sets both icon name and window title
  /// OSC 2 sets window title only
  static final RegExp _titleEscapeSequence = RegExp(
    r'\x1b\](?:0|2);([^\x07\x1b]*?)(?:\x07|\x1b\\)',
  );

  /// Initializes the terminal session.
  ///
  /// This method:
  /// 1. Creates the xterm terminal instance (already done in constructor)
  /// 2. Starts the PTY process with the configured shell
  /// 3. Connects PTY output to xterm input
  /// 4. Connects xterm output to PTY input
  /// 5. Updates status to running
  ///
  /// Throws [ProcessSpawnException] if PTY creation fails.
  Future<void> initialize() async {
    try {
      // Step 1: Terminal instance already created in constructor
      
      // Step 2: Start PTY process with shell configuration
      _pty = Pty.start(
        _shellConfig.shellPath,
        arguments: _shellConfig.arguments,
        environment: _shellConfig.environment,
        workingDirectory: _shellConfig.workingDirectory,
        columns: _size.cols,
        rows: _size.rows,
      );
      
      // Step 3: Connect PTY output stream to terminal input
      // Decode UTF-8 with malformed character handling
      _outputSubscription = _pty!.output.listen(
        (data) {
          final decoded = utf8.decode(data, allowMalformed: true);
          
          // Parse title escape sequences before writing to terminal
          _parseTitleEscapeSequences(decoded);
          
          _terminal.write(decoded);
        },
        onError: (error) {
          // Handle PTY output stream errors
          _updateStatus(TerminalStatus.error);
        },
        onDone: () async {
          // PTY process has exited - capture exit code
          try {
            _exitCode = await _pty?.exitCode;
          } catch (_) {
            _exitCode = null;
          }
          _updateStatus(TerminalStatus.exited);
        },
      );
      
      // Step 4: Connect terminal output callback to PTY input
      _terminal.onOutput = (output) {
        if (_pty != null && status == TerminalStatus.running) {
          _pty!.write(utf8.encode(output));
        }
      };
      
      // Step 5: Set status to running and capture PID
      _updateStatus(TerminalStatus.running);
      
    } catch (e) {
      // PTY creation failed
      throw ProcessSpawnException(
        'Failed to start shell: ${_shellConfig.shellPath}',
        cause: e,
      );
    }
  }

  /// Disposes the terminal session and cleans up all resources.
  ///
  /// This method:
  /// 1. Cancels the output subscription
  /// 2. Kills the PTY process
  /// 3. Updates status to exited
  /// 4. Closes the status stream controller
  /// 5. Disposes the title notifier
  ///
  /// Note: The xterm Terminal instance does not require explicit disposal.
  Future<void> dispose() async {
    // Step 1: Cancel output subscription
    if (_outputSubscription != null) {
      await _outputSubscription!.cancel();
      _outputSubscription = null;
    }
    
    // Step 2: Kill PTY process
    if (_pty != null) {
      try {
        _pty!.kill();
      } catch (e) {
        // Log error but continue cleanup
        debugPrint('Error killing PTY process: $e');
      }
    }
    
    // Step 3: Update status to exited
    _updateStatus(TerminalStatus.exited);
    
    // Step 4: Close status stream controller
    await _statusController.close();
    
    // Step 5: Dispose title notifier
    _titleNotifier.dispose();
  }

  /// Resizes the terminal to the specified dimensions.
  ///
  /// Updates both the PTY size and xterm view dimensions.
  ///
  /// Parameters:
  /// - [rows]: Number of rows (must be between 1 and 1000)
  /// - [cols]: Number of columns (must be between 1 and 1000)
  ///
  /// Throws [ArgumentError] if dimensions are invalid.
  /// Throws [StateError] if terminal is not running.
  Future<void> resize(int rows, int cols) async {
    // Step 1: Validate dimensions are in valid range (1-1000)
    if (rows < 1 || rows > 1000) {
      throw ArgumentError(
        'Rows must be between 1 and 1000, got $rows',
      );
    }
    if (cols < 1 || cols > 1000) {
      throw ArgumentError(
        'Cols must be between 1 and 1000, got $cols',
      );
    }
    
    // Step 2: Validate terminal is running
    if (status != TerminalStatus.running) {
      throw StateError(
        'Cannot resize terminal: terminal is not running (status: $status)',
      );
    }
    
    // Step 3: Resize PTY with new dimensions
    _pty?.resize(rows, cols);
    
    // Step 4: Update terminal view dimensions
    // Note: xterm Terminal.resize takes (width, height) which is (cols, rows)
    _terminal.resize(cols, rows);
    
    // Step 5: Update stored size property
    _size = PtySize(rows: rows, cols: cols);
  }

  /// Writes input to the PTY process.
  ///
  /// The input is encoded as UTF-8 before being written to the PTY.
  ///
  /// Throws [StateError] if terminal is not running.
  Future<void> write(String data) async {
    // Validate terminal status is running
    if (status != TerminalStatus.running) {
      throw StateError(
        'Cannot write to terminal: terminal is not running (status: $status)',
      );
    }
    
    // Encode input as UTF-8 and write to PTY input
    _pty!.write(utf8.encode(data));
  }

  /// Kills the PTY process with the specified signal.
  ///
  /// Sends the specified signal to the PTY process. Supports SIGTERM and SIGKILL.
  /// On Windows, only SIGKILL is supported and will be used regardless of the
  /// signal parameter.
  ///
  /// Parameters:
  /// - [signal]: The signal to send (defaults to SIGTERM for graceful termination)
  ///
  /// Throws [StateError] if terminal is not running.
  Future<void> kill([PtySignal signal = PtySignal.sigterm]) async {
    // Validate terminal is running
    if (status != TerminalStatus.running) {
      throw StateError(
        'Cannot kill terminal: terminal is not running (status: $status)',
      );
    }
    
    if (_pty == null) {
      throw StateError('Cannot kill terminal: PTY instance is null');
    }
    
    try {
      // Handle different signals
      if (signal == PtySignal.sigkill) {
        // SIGKILL - force kill immediately
        _pty!.kill();
      } else {
        // For other signals (SIGTERM, SIGINT, SIGHUP, SIGQUIT)
        // Use Process.killPid on Unix systems
        if (Platform.isWindows) {
          // Windows doesn't support graceful signals, use force kill
          _pty!.kill();
        } else {
          // On Unix systems, use Process.killPid with the appropriate ProcessSignal
          final processSignal = _convertToProcessSignal(signal);
          Process.killPid(pid!, processSignal);
        }
      }
    } catch (e) {
      throw StateError('Failed to kill PTY process: $e');
    }
  }
  
  /// Converts PtySignal to ProcessSignal for use with Process.killPid
  ProcessSignal _convertToProcessSignal(PtySignal signal) {
    switch (signal) {
      case PtySignal.sigint:
        return ProcessSignal.sigint;
      case PtySignal.sigterm:
        return ProcessSignal.sigterm;
      case PtySignal.sigkill:
        return ProcessSignal.sigkill;
      case PtySignal.sighup:
        return ProcessSignal.sighup;
      case PtySignal.sigquit:
        return ProcessSignal.sigquit;
    }
  }

  /// Restarts the terminal session.
  ///
  /// This method:
  /// 1. Disposes the current PTY and terminal
  /// 2. Creates a new PTY with the same configuration
  /// 3. Creates a new xterm terminal instance
  /// 4. Updates status to running on success, or error on failure
  Future<void> restart() async {
    try {
      // Step 1: Dispose current PTY and terminal
      // Cancel output subscription
      if (_outputSubscription != null) {
        await _outputSubscription!.cancel();
        _outputSubscription = null;
      }
      
      // Kill PTY process
      if (_pty != null) {
        try {
          _pty!.kill();
        } catch (e) {
          debugPrint('Error killing PTY process during restart: $e');
        }
      }
      
      // Clear terminal content
      _terminal.buffer.clear();
      
      // Reset exit code
      _exitCode = null;
      
      // Step 2: Create new PTY with same ShellConfig
      _pty = Pty.start(
        _shellConfig.shellPath,
        arguments: _shellConfig.arguments,
        environment: _shellConfig.environment,
        workingDirectory: _shellConfig.workingDirectory,
        columns: _size.cols,
        rows: _size.rows,
      );
      
      // Step 3: Connect PTY output stream to terminal input
      _outputSubscription = _pty!.output.listen(
        (data) {
          final decoded = utf8.decode(data, allowMalformed: true);
          
          // Parse title escape sequences before writing to terminal
          _parseTitleEscapeSequences(decoded);
          
          _terminal.write(decoded);
        },
        onError: (error) {
          _updateStatus(TerminalStatus.error);
        },
        onDone: () async {
          try {
            _exitCode = await _pty?.exitCode;
          } catch (_) {
            _exitCode = null;
          }
          _updateStatus(TerminalStatus.exited);
        },
      );
      
      // Connect terminal output callback to PTY input
      _terminal.onOutput = (output) {
        if (_pty != null && status == TerminalStatus.running) {
          _pty!.write(utf8.encode(output));
        }
      };
      
      // Step 4: Update status to running on success
      _updateStatus(TerminalStatus.running);
      
    } catch (e) {
      // Step 4: Update status to error on failure
      _updateStatus(TerminalStatus.error);
      throw ProcessSpawnException(
        'Failed to restart terminal with shell: ${_shellConfig.shellPath}',
        cause: e,
      );
    }
  }

  /// Updates the terminal status and notifies listeners.
  void _updateStatus(TerminalStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// Updates the terminal title and notifies listeners.
  void _updateTitle(String newTitle) {
    if (_titleNotifier.value != newTitle) {
      _titleNotifier.value = newTitle;
    }
  }

  /// Parses title escape sequences from PTY output.
  ///
  /// Scans the output for OSC (Operating System Command) escape sequences
  /// that set the terminal title. When found, extracts the title and updates
  /// the title notifier.
  ///
  /// Supported sequences:
  /// - ESC ] 0 ; title BEL (sets both icon and window title)
  /// - ESC ] 0 ; title ST (sets both icon and window title)
  /// - ESC ] 2 ; title BEL (sets window title only)
  /// - ESC ] 2 ; title ST (sets window title only)
  ///
  /// Where:
  /// - ESC is \x1b
  /// - BEL is \x07
  /// - ST is ESC \ (i.e., \x1b\)
  void _parseTitleEscapeSequences(String output) {
    final matches = _titleEscapeSequence.allMatches(output);
    
    for (final match in matches) {
      final title = match.group(1);
      if (title != null && title.isNotEmpty) {
        _updateTitle(title);
      }
    }
  }
}
