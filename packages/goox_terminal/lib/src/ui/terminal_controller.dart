import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:goox_terminal/src/models/terminal_output.dart';
import 'package:goox_terminal/src/models/terminal_status.dart';
import 'package:goox_terminal/src/services/ansi_parser.dart';
import 'package:goox_terminal/src/services/pty_service.dart';
import 'package:goox_terminal/src/services/shell_detector.dart';

/// Controller for managing a single terminal instance
/// 
/// This controller handles:
/// - PTY process lifecycle (start, stop, restart)
/// - Terminal output buffering and ANSI parsing
/// - Terminal input handling
/// - Status tracking
class TerminalController extends ChangeNotifier {
  /// Creates a terminal controller
  TerminalController({
    required PTYService ptyService,
    required ShellDetector shellDetector,
    required ANSIParser ansiParser,
    required this.workingDirectory,
    this.title,
  })  : _ptyService = ptyService,
        _shellDetector = shellDetector,
        _ansiParser = ansiParser;

  final PTYService _ptyService;
  final ShellDetector _shellDetector;
  final ANSIParser _ansiParser;

  /// Working directory for the terminal
  final String workingDirectory;

  /// Terminal title (defaults to shell name)
  String? title;

  /// Current terminal status
  TerminalStatus _status = TerminalStatus.initializing;
  TerminalStatus get status => _status;

  /// Terminal output buffer
  TerminalOutput _output = const TerminalOutput(lines: []);
  TerminalOutput get output => _output;

  /// Exit code if terminal has exited
  int? _exitCode;
  int? get exitCode => _exitCode;

  /// Error message if terminal encountered an error
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PTYProcess? _ptyProcess;
  StreamSubscription<String>? _outputSubscription;

  /// Start the terminal
  Future<void> start() async {
    if (_status == TerminalStatus.running) {
      return; // Already running
    }

    _status = TerminalStatus.initializing;
    _errorMessage = null;
    _exitCode = null;
    notifyListeners();

    try {
      // Detect shell
      final shellConfig = await _shellDetector.detectShell();
      
      // Set title if not already set
      title ??= shellConfig.shellPath.split('/').last.split(r'\').last;

      // Create PTY
      _ptyProcess = await _ptyService.createPTY(
        shellConfig: shellConfig,
        workingDirectory: workingDirectory,
      );

      // Subscribe to output
      _outputSubscription = _ptyProcess!.stdout.listen(
        _handleOutput,
        onError: _handleError,
      );

      // Listen for exit
      unawaited(
        _ptyProcess!.exitCode.then(_handleExit).catchError(_handleError),
      );

      _status = TerminalStatus.running;
      notifyListeners();
    } catch (e) {
      _status = TerminalStatus.error;
      _errorMessage = 'Failed to start terminal: $e';
      notifyListeners();
    }
  }

  /// Stop the terminal
  Future<void> stop({bool force = false}) async {
    if (_ptyProcess == null) return;

    try {
      await _ptyService.terminate(_ptyProcess!, force: force);
    } catch (e) {
      // Ignore termination errors
    }

    await _outputSubscription?.cancel();
    _outputSubscription = null;
    _ptyProcess = null;

    if (_status != TerminalStatus.exited) {
      _status = TerminalStatus.exited;
      notifyListeners();
    }
  }

  /// Restart the terminal
  Future<void> restart() async {
    await stop(force: true);
    _output = const TerminalOutput(lines: []);
    await start();
  }

  /// Write input to the terminal
  Future<void> write(String input) async {
    if (_ptyProcess == null || _status != TerminalStatus.running) {
      return;
    }

    try {
      await _ptyService.write(_ptyProcess!, input);
    } catch (e) {
      _errorMessage = 'Failed to write input: $e';
      notifyListeners();
    }
  }

  /// Resize the terminal
  Future<void> resize(int cols, int rows) async {
    if (_ptyProcess == null) return;

    try {
      await _ptyService.resize(_ptyProcess!, cols, rows);
    } catch (e) {
      // Ignore resize errors
    }
  }

  void _handleOutput(String rawOutput) {
    // Parse ANSI codes
    final parsedLines = _ansiParser.parse(rawOutput);

    // Append to output buffer (with automatic trimming)
    _output = _output.appendLines(parsedLines);

    notifyListeners();
  }

  void _handleError(dynamic error) {
    _status = TerminalStatus.error;
    _errorMessage = 'Terminal error: $error';
    notifyListeners();
  }

  void _handleExit(int exitCode) {
    _exitCode = exitCode;
    _status = TerminalStatus.exited;

    // Append exit message
    final exitMessage = 'Process exited with code $exitCode';
    final exitLines = [
      const TerminalLine(text: '', styles: []),
      TerminalLine(text: exitMessage, styles: const []),
      const TerminalLine(text: '', styles: []),
      const TerminalLine(
        text: 'Click "Restart Terminal" to start a new session.',
        styles: [],
      ),
    ];

    _output = _output.appendLines(exitLines);
    notifyListeners();
  }

  @override
  void dispose() {
    stop(force: true);
    super.dispose();
  }
}
