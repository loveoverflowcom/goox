import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart' as xterm;

import '../controllers/terminal_controller.dart';
import '../models/terminal_status.dart';
import 'terminal_theme.dart';

/// Widget that renders a terminal using xterm and handles user interactions.
///
/// This widget provides:
/// - Terminal rendering using xterm TerminalView
/// - Keyboard input handling with special key support
/// - Mouse input handling for cursor positioning and scrolling
/// - Auto-scroll behavior
/// - Theme application
/// - Focus management
///
/// Example:
/// ```dart
/// TerminalView(
///   controller: myTerminalController,
///   theme: TerminalTheme.dark(),
/// )
/// ```
class TerminalView extends StatefulWidget {
  /// Creates a terminal view widget.
  ///
  /// Parameters:
  /// - [controller]: The terminal controller managing this terminal session
  /// - [theme]: Optional theme for terminal appearance (defaults to dark theme)
  const TerminalView({
    required this.controller,
    this.theme,
    super.key,
  });

  /// The terminal controller managing this terminal session.
  final TerminalController controller;

  /// Theme for terminal appearance.
  final TerminalTheme? theme;

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  /// Focus node for keyboard input handling.
  late final FocusNode _focusNode;

  /// Terminal view controller for xterm.
  late final xterm.TerminalController _terminalViewController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _terminalViewController = xterm.TerminalController();

    // Request focus when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _terminalViewController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Note: xterm handles auto-scrolling internally
  }

  /// Handles keyboard input events.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle Enter key
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _sendInput('\r');
      return KeyEventResult.handled;
    }

    // Handle Backspace key
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _sendInput('\x7f');
      return KeyEventResult.handled;
    }

    // Handle Tab key
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _sendInput('\t');
      return KeyEventResult.handled;
    }

    // Handle Escape key
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _sendInput('\x1b');
      return KeyEventResult.handled;
    }

    // Handle Arrow keys
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _sendInput('\x1b[A');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _sendInput('\x1b[B');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _sendInput('\x1b[C');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _sendInput('\x1b[D');
      return KeyEventResult.handled;
    }

    // Handle Home key
    if (event.logicalKey == LogicalKeyboardKey.home) {
      _sendInput('\x1b[H');
      return KeyEventResult.handled;
    }

    // Handle End key
    if (event.logicalKey == LogicalKeyboardKey.end) {
      _sendInput('\x1b[F');
      return KeyEventResult.handled;
    }

    // Handle Page Up key
    if (event.logicalKey == LogicalKeyboardKey.pageUp) {
      _sendInput('\x1b[5~');
      return KeyEventResult.handled;
    }

    // Handle Page Down key
    if (event.logicalKey == LogicalKeyboardKey.pageDown) {
      _sendInput('\x1b[6~');
      return KeyEventResult.handled;
    }

    // Handle Delete key
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      _sendInput('\x1b[3~');
      return KeyEventResult.handled;
    }

    // Handle Insert key
    if (event.logicalKey == LogicalKeyboardKey.insert) {
      _sendInput('\x1b[2~');
      return KeyEventResult.handled;
    }

    // Handle Ctrl+C (SIGINT)
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyC) {
      _sendInput('\x03');
      return KeyEventResult.handled;
    }

    // Handle Ctrl+D (EOF)
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyD) {
      _sendInput('\x04');
      return KeyEventResult.handled;
    }

    // Handle Ctrl+Z (SIGTSTP)
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyZ) {
      _sendInput('\x1a');
      return KeyEventResult.handled;
    }

    // Handle Ctrl+L (clear screen)
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyL) {
      _sendInput('\x0c');
      return KeyEventResult.handled;
    }

    // Handle Ctrl+A (beginning of line)
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyA) {
      _sendInput('\x01');
      return KeyEventResult.handled;
    }

    // Handle Ctrl+E (end of line)
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyE) {
      _sendInput('\x05');
      return KeyEventResult.handled;
    }

    // Handle Ctrl+K (kill line)
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyK) {
      _sendInput('\x0b');
      return KeyEventResult.handled;
    }

    // Handle Ctrl+U (kill line backwards)
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyU) {
      _sendInput('\x15');
      return KeyEventResult.handled;
    }

    // Handle Ctrl+W (kill word backwards)
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyW) {
      _sendInput('\x17');
      return KeyEventResult.handled;
    }

    // Handle regular character input
    if (event.character != null && event.character!.isNotEmpty) {
      _sendInput(event.character!);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Sends input to the terminal controller.
  void _sendInput(String input) {
    try {
      widget.controller.write(input);
    } catch (e) {
      // Terminal might not be running, ignore the error
      debugPrint('Failed to send input to terminal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? TerminalTheme.dark();

    return StreamBuilder<TerminalStatus>(
      stream: widget.controller.statusStream,
      initialData: widget.controller.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? TerminalStatus.initializing;

        // Show error overlay when terminal is in error state
        if (status == TerminalStatus.error) {
          return _buildErrorOverlay(context, theme);
        }

        return Focus(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: GestureDetector(
            onTap: () {
              _focusNode.requestFocus();
            },
            child: xterm.TerminalView(
              widget.controller.terminal,
              controller: _terminalViewController,
              theme: theme.toXTermTheme(),
              backgroundOpacity: 1.0,
              padding: const EdgeInsets.all(8.0),
              autofocus: true,
              // Enable mouse input for cursor positioning
              onTapUp: (details, offset) {
                _focusNode.requestFocus();
              },
            ),
          ),
        );
      },
    );
  }

  /// Builds the error overlay with restart button.
  Widget _buildErrorOverlay(BuildContext context, TerminalTheme theme) {
    return Container(
      color: theme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Terminal Error',
              style: TextStyle(
                color: theme.foreground,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The terminal process has encountered an error',
              style: TextStyle(
                color: theme.foreground.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await widget.controller.restart();
                } catch (e) {
                  // If restart fails, show error in debug console
                  debugPrint('Failed to restart terminal: $e');
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Restart Terminal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.blue,
                foregroundColor: theme.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
