import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/terminal/data/models/ansi_style.dart';
import 'package:goox/features/terminal/data/models/terminal_instance.dart';
import 'package:goox/features/terminal/data/models/terminal_output.dart';
import 'package:goox/features/terminal/presentation/blocs/terminal_bloc.dart';

/// Widget that renders terminal output and handles keyboard input
class TerminalEmulator extends StatefulWidget {
  /// The terminal instance to display
  final TerminalInstance terminal;

  /// Constructor
  const TerminalEmulator({
    required this.terminal,
    super.key,
  });

  @override
  State<TerminalEmulator> createState() => _TerminalEmulatorState();
}

class _TerminalEmulatorState extends State<TerminalEmulator> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void didUpdateWidget(TerminalEmulator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-scroll to bottom when new output arrives
    if (widget.terminal.output.lines.length !=
        oldWidget.terminal.output.lines.length) {
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
    final theme = Theme.of(context);
    final isDead = widget.terminal.status == TerminalInstanceStatus.exited ||
        widget.terminal.status == TerminalInstanceStatus.error;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: isDead ? null : _handleKeyEvent,
      child: Tooltip(
        message: isDead 
            ? 'Terminal has exited. Click "Restart Terminal" to start a new session.'
            : 'Click to focus terminal. Type to send input to shell.',
        waitDuration: const Duration(milliseconds: 800),
        child: GestureDetector(
          onTap: isDead ? null : _focusNode.requestFocus,
          child: Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: widget.terminal.output.lines.length,
                    itemBuilder: (context, index) {
                      return _buildTerminalLine(
                        widget.terminal.output.lines[index],
                        theme,
                      );
                    },
                  ),
                ),
                if (isDead) _buildRestartButton(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build restart button for dead terminals
  Widget _buildRestartButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tooltip(
        message: 'Start a new shell session in this terminal',
        child: ElevatedButton.icon(
          onPressed: () {
            context.read<TerminalBloc>().add(
                  RestartTerminalEvent(widget.terminal.id),
                );
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Restart Terminal'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
    );
  }

  /// Build a single terminal line with styling
  Widget _buildTerminalLine(TerminalLine line, ThemeData theme) {
    if (line.styles.isEmpty) {
      // Plain text without styling
      return Text(
        line.text,
        style: TextStyle(
          fontFamily: _getMonospaceFont(),
          fontSize: 13,
          color: theme.colorScheme.onSurface,
          height: 1.35, // Optimal line height for readability
        ),
      );
    }

    // Build styled text with ANSI styles applied
    return Text.rich(
      TextSpan(
        children: _buildStyledSpans(line, theme),
        style: TextStyle(
          fontFamily: _getMonospaceFont(),
          fontSize: 13,
          height: 1.35, // Optimal line height for readability
        ),
      ),
    );
  }

  /// Build styled TextSpan objects from ANSI styles
  List<TextSpan> _buildStyledSpans(TerminalLine line, ThemeData theme) {
    final spans = <TextSpan>[];
    final text = line.text;
    final styles = line.styles;

    if (styles.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: TextStyle(color: theme.colorScheme.onSurface),
      ));
      return spans;
    }

    // Sort styles by start index
    final sortedStyles = List<ANSIStyle>.from(styles)
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    var currentIndex = 0;

    for (final style in sortedStyles) {
      // Add unstyled text before this style
      if (currentIndex < style.startIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, style.startIndex),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ));
      }

      // Add styled text
      final endIndex = style.endIndex.clamp(0, text.length);
      if (style.startIndex < endIndex) {
        spans.add(TextSpan(
          text: text.substring(style.startIndex, endIndex),
          style: _buildTextStyle(style, theme),
        ));
        currentIndex = endIndex;
      }
    }

    // Add remaining unstyled text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: TextStyle(color: theme.colorScheme.onSurface),
      ));
    }

    return spans;
  }

  /// Build TextStyle from ANSIStyle
  TextStyle _buildTextStyle(ANSIStyle style, ThemeData theme) {
    return TextStyle(
      color: style.foregroundColor ?? theme.colorScheme.onSurface,
      backgroundColor: style.backgroundColor,
      fontWeight: style.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: style.italic ? FontStyle.italic : FontStyle.normal,
      decoration: style.underline ? TextDecoration.underline : null,
    );
  }

  /// Get monospace font family
  /// 
  /// Tries high-quality monospace fonts in order:
  /// 1. Fira Code - Popular coding font with ligatures
  /// 2. JetBrains Mono - Designed for developers
  /// 3. Cascadia Code - Microsoft's modern monospace font
  /// 4. Consolas - Windows default
  /// 5. SF Mono - macOS default
  /// 6. monospace - System fallback
  String _getMonospaceFont() {
    return 'Fira Code, JetBrains Mono, Cascadia Code, Consolas, SF Mono, monospace';
  }

  /// Handle keyboard input events
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle Enter key
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _sendInput('\n');
      return KeyEventResult.handled;
    }

    // Handle Backspace key
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _sendInput('\x7f');
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

    // Handle regular character input
    if (event.character != null && event.character!.isNotEmpty) {
      _sendInput(event.character!);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Send input to the terminal
  void _sendInput(String input) {
    context.read<TerminalBloc>().add(
          TerminalInputEvent(
            terminalId: widget.terminal.id,
            input: input,
          ),
        );
  }
}
