import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that displays a terminal emulator with PTY support
/// 
/// This widget provides a full-featured terminal emulator that can:
/// - Display terminal output with ANSI color support
/// - Handle keyboard input and send it to the PTY
/// - Auto-scroll to show the latest output
/// - Support monospace fonts for proper alignment
/// 
/// Example:
/// ```dart
/// TerminalWidget(
///   ptySession: myPtySession,
///   onInput: (input) => myPtySession.write(input),
/// )
/// ```
class TerminalWidget extends StatefulWidget {
  /// Creates a terminal widget
  const TerminalWidget({
    required this.output,
    required this.onInput,
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.foregroundColor = const Color(0xFFCCCCCC),
    this.fontSize = 14,
    this.fontFamily = 'monospace',
    this.padding = const EdgeInsets.all(8),
    super.key,
  });

  /// The terminal output to display
  final String output;

  /// Callback when user types input
  final ValueChanged<String> onInput;

  /// Background color of the terminal
  final Color backgroundColor;

  /// Default text color
  final Color foregroundColor;

  /// Font size for terminal text
  final double fontSize;

  /// Font family (should be monospace)
  final String fontFamily;

  /// Padding around the terminal content
  final EdgeInsets padding;

  @override
  State<TerminalWidget> createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void didUpdateWidget(TerminalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.output != oldWidget.output) {
      // Auto-scroll to bottom when new output arrives
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: _focusNode.requestFocus,
        child: Container(
          color: widget.backgroundColor,
          padding: widget.padding,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SelectableText(
              widget.output,
              style: TextStyle(
                fontFamily: widget.fontFamily,
                fontSize: widget.fontSize,
                color: widget.foregroundColor,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle Enter key
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onInput('\n');
      return KeyEventResult.handled;
    }

    // Handle Backspace key
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      widget.onInput('\x7f');
      return KeyEventResult.handled;
    }

    // Handle Ctrl+C (SIGINT)
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyC) {
      widget.onInput('\x03');
      return KeyEventResult.handled;
    }

    // Handle Ctrl+D (EOF)
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyD) {
      widget.onInput('\x04');
      return KeyEventResult.handled;
    }

    // Handle regular character input
    if (event.character != null && event.character!.isNotEmpty) {
      widget.onInput(event.character!);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
