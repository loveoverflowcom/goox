import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goox_terminal/src/goox_terminal_controller.dart';
import 'package:xterm/xterm.dart';

/// A simple terminal widget wrapper using xterm and flutter_pty
class GooxTerminal extends StatefulWidget {
  const GooxTerminal({
    super.key,
    this.maxLines = 10000,
    this.autofocus = true,
    this.backgroundOpacity = 0.7,
    this.backgroundColor = Colors.transparent,
    this.enableDebug = false,
    this.useScaffold = true,
    this.shellPath,
    this.shellArguments = const [],
    this.environment,
    this.onTerminalReady,
  });

  /// Maximum number of lines to keep in terminal buffer
  final int maxLines;

  /// Whether to autofocus the terminal
  final bool autofocus;

  /// Background opacity (0.0 to 1.0)
  final double backgroundOpacity;

  /// Background color
  final Color backgroundColor;

  /// Enable debug mode to print shell information
  final bool enableDebug;

  /// Whether to wrap the terminal in its own Scaffold.
  final bool useScaffold;

  /// Optional shell executable path.
  final String? shellPath;

  /// Optional shell arguments.
  final List<String> shellArguments;

  /// Optional shell environment overrides.
  final Map<String, String>? environment;

  /// Callback when terminal is ready
  final void Function(GooxTerminalController controller)? onTerminalReady;

  @override
  State<GooxTerminal> createState() => _GooxTerminalState();
}

class _GooxTerminalState extends State<GooxTerminal> {
  late final GooxTerminalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GooxTerminalController(
      maxLines: widget.maxLines,
      enableDebug: widget.enableDebug,
      shellPath: widget.shellPath,
      shellArguments: widget.shellArguments,
      environment: widget.environment,
    );

    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) {
        _controller.start();
        // Call onTerminalReady after a short delay to ensure PTY is initialized
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            widget.onTerminalReady?.call(_controller);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSecondaryTapDown(
    TapDownDetails details,
    CellOffset offset,
  ) {
    unawaited(_handleSecondaryTapDownAsync(details, offset));
  }

  Future<void> _handleSecondaryTapDownAsync(
    TapDownDetails details,
    CellOffset offset,
  ) async {
    final selectedText = _controller.getSelectedText();

    if (selectedText != null) {
      // Copy selected text
      _controller.clearSelection();
      await Clipboard.setData(ClipboardData(text: selectedText));
    } else {
      // Paste from clipboard
      final data = await Clipboard.getData('text/plain');
      final text = data?.text;
      if (text != null) {
        _controller.paste(text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final terminalView = TerminalView(
      _controller.terminal,
      controller: _controller.terminalController,
      autofocus: widget.autofocus,
      backgroundOpacity: widget.backgroundOpacity,
      onSecondaryTapDown: _handleSecondaryTapDown,
    );

    if (!widget.useScaffold) {
      return ColoredBox(
        color: widget.backgroundColor,
        child: terminalView,
      );
    }

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(child: terminalView),
    );
  }
}
