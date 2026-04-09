import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

import 'package:goox_terminal/src/goox_terminal_debug.dart';

final class GooxTerminalSessionView extends StatefulWidget {
  const GooxTerminalSessionView({
    super.key,
    this.maxLines = 10000,
    this.enableDebug = false,
  });

  final int maxLines;
  final bool enableDebug;

  @override
  State<GooxTerminalSessionView> createState() =>
      _GooxTerminalSessionViewState();
}

final class _GooxTerminalSessionViewState
    extends State<GooxTerminalSessionView> {
  late final Terminal terminal;
  final TerminalController terminalController = TerminalController();
  Pty? _pty;

  @override
  void initState() {
    super.initState();
    terminal = Terminal(maxLines: widget.maxLines);
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        _startPty();
      }
    });
  }

  void _startPty() {
    final shellPath = GooxTerminalDebug.getShellPath();

    if (widget.enableDebug) {
      GooxTerminalDebug.printShellInfo();
      terminal.write(
        '\r\nStarting shell: $shellPath\r\n'
        'Columns: ${terminal.viewWidth > 0 ? terminal.viewWidth : 80}, '
        'Rows: ${terminal.viewHeight > 0 ? terminal.viewHeight : 24}\r\n',
      );
    }

    // Fix HOME environment for sandboxed apps
    final environment = _buildEnvironment();

    // For sandboxed apps, use bash with --norc to avoid config file issues
    final useSimpleShell = Platform.isMacOS &&
        Platform.environment['HOME']?.contains('/Containers/') == true;

    final actualShell = useSimpleShell ? '/bin/bash' : shellPath;
    final arguments = useSimpleShell ? ['--norc', '-i'] : <String>[];

    if (widget.enableDebug && useSimpleShell) {
      terminal.write(
        'Using simple shell mode: $actualShell with args $arguments\r\n',
      );
    }

    _pty = Pty.start(
      actualShell,
      arguments: arguments,
      columns: terminal.viewWidth > 0 ? terminal.viewWidth : 80,
      rows: terminal.viewHeight > 0 ? terminal.viewHeight : 24,
      environment: environment,
    );

    _pty!.output
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(terminal.write);

    _pty!.exitCode.then((code) {
      terminal.write('the process exited with exit code $code');
    });

    terminal.onOutput = (data) {
      _pty?.write(const Utf8Encoder().convert(data));
    };

    terminal.onResize = (w, h, pw, ph) {
      _pty?.resize(h, w);
    };
  }

  Map<String, String> _buildEnvironment() {
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

          if (widget.enableDebug) {
            terminal.write(
              'Fixed HOME: $currentHome -> $realHome\r\n',
            );
          }
        }
      }
    }

    // Ensure TERM is set
    if (!env.containsKey('TERM')) {
      env['TERM'] = 'xterm-256color';
    }

    return env;
  }

  @override
  void dispose() {
    _pty?.kill();
    terminal.onOutput = null;
    terminal.onResize = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: TerminalView(
          terminal,
          controller: terminalController,
          autofocus: true,
          backgroundOpacity: 0.7,
          onSecondaryTapDown: (details, offset) async {
            final selection = terminalController.selection;
            if (selection != null) {
              final text = terminal.buffer.getText(selection);
              terminalController.clearSelection();
              await Clipboard.setData(ClipboardData(text: text));
            } else {
              final data = await Clipboard.getData('text/plain');
              final text = data?.text;
              if (text != null) {
                terminal.paste(text);
              }
            }
          },
        ),
      ),
    );
  }
}
