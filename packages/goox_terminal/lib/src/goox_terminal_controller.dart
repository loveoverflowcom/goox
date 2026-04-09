import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

import 'package:goox_terminal/src/goox_terminal_debug.dart';

/// Controller for managing terminal instance
class GooxTerminalController {
  GooxTerminalController({
    int maxLines = 10000,
    this.enableDebug = false,
    this.shellPath,
    this.shellArguments = const [],
    this.environment,
  }) : terminal = Terminal(maxLines: maxLines);

  final Terminal terminal;
  final TerminalController terminalController = TerminalController();
  final bool enableDebug;
  final String? shellPath;
  final List<String> shellArguments;
  final Map<String, String>? environment;

  Pty? _pty;
  bool _isDisposed = false;

  /// Start the PTY process
  void start({
    int? columns,
    int? rows,
  }) {
    if (_isDisposed || _pty != null) return;

    try {
      final executable = _resolveShellPath();
      final resolvedColumns =
          columns ?? (terminal.viewWidth > 0 ? terminal.viewWidth : 80);
      final resolvedRows =
          rows ?? (terminal.viewHeight > 0 ? terminal.viewHeight : 24);

      if (enableDebug) {
        GooxTerminalDebug.printShellInfo();
        terminal.write(
          '\r\nStarting shell: $executable\r\n'
          'Columns: $resolvedColumns, Rows: $resolvedRows\r\n'
          'Terminal viewWidth: ${terminal.viewWidth}, viewHeight: ${terminal.viewHeight}\r\n',
        );
      }

      // Start PTY with minimal parameters - matching working draft
      _pty = Pty.start(
        executable,
        columns: resolvedColumns,
        rows: resolvedRows,
      );

      _pty!.output.cast<List<int>>().transform(const Utf8Decoder()).listen(
        terminal.write,
        onError: (Object error) {
          if (!_isDisposed) {
            terminal.write('\r\nTerminal error: $error\r\n');
          }
        },
      );

      unawaited(_pty!.exitCode.then((code) {
        if (!_isDisposed) {
          terminal.write('the process exited with exit code $code');
        }
      }));

      terminal.onOutput = (data) {
        _pty?.write(const Utf8Encoder().convert(data));
      };

      terminal.onResize = (w, h, pw, ph) {
        _pty?.resize(h, w);
      };
    } on Object catch (e) {
      terminal.write('Failed to start terminal: $e\r\n');
    }
  }

  String _resolveShellPath() {
    if (shellPath != null && shellPath!.isNotEmpty) {
      return shellPath!;
    }

    return GooxTerminalDebug.getShellPath();
  }

  List<String> _getDefaultShellArguments(String shellPath) {
    // For zsh and bash, use interactive login shell flags
    final shellName = shellPath.split('/').last;
    
    if (shellName == 'zsh' || shellName == 'bash') {
      return ['-i', '-l'];  // Interactive + Login shell
    }
    
    return [];
  }

  Map<String, String> _buildEnvironment() {
    // Start with system environment
    final env = Map<String, String>.from(Platform.environment);
    
    // Fix HOME for sandboxed macOS apps
    if (Platform.isMacOS) {
      final currentHome = env['HOME'];
      if (currentHome != null && currentHome.contains('/Containers/')) {
        // Extract real username from sandboxed path
        // /Users/username/Library/Containers/... -> /Users/username
        final parts = currentHome.split('/');
        if (parts.length >= 3 && parts[1] == 'Users') {
          final realHome = '/Users/${parts[2]}';
          env['HOME'] = realHome;
          
          if (enableDebug) {
            terminal.write(
              'Fixed HOME: $currentHome -> $realHome\r\n',
            );
          }
        }
      }
    }
    
    // Ensure TERM is set for proper terminal emulation
    if (!env.containsKey('TERM')) {
      env['TERM'] = 'xterm-256color';
    }
    
    // Merge user-provided environment overrides
    if (environment != null) {
      env.addAll(environment!);
    }
    
    return env;
  }

  /// Write data to terminal
  void write(String data) {
    if (!_isDisposed) {
      terminal.write(data);
    }
  }

  /// Paste text into terminal
  void paste(String text) {
    if (!_isDisposed) {
      terminal.paste(text);
    }
  }

  /// Clear terminal selection
  void clearSelection() {
    if (!_isDisposed) {
      terminalController.clearSelection();
    }
  }

  /// Get selected text
  String? getSelectedText() {
    if (_isDisposed) return null;

    final selection = terminalController.selection;
    if (selection != null) {
      return terminal.buffer.getText(selection);
    }
    return null;
  }

  /// Dispose resources
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _pty?.kill();
    terminal.onOutput = null;
    terminal.onResize = null;
  }
}
