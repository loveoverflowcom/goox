import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/terminal_session_manager.dart';
import 'terminal_tab_bar.dart';
import 'terminal_theme.dart';
import 'terminal_view.dart';

/// Main terminal panel widget that combines tab bar and terminal view.
///
/// This widget provides:
/// - Terminal tab bar at the top
/// - Active terminal view below tabs
/// - Panel visibility toggle
/// - Panel resize with drag handle
/// - Keyboard shortcuts (Ctrl+Shift+` to create new terminal)
/// - Integration with TerminalSessionManager
///
/// Example:
/// ```dart
/// TerminalPanel(
///   initialHeight: 300,
///   visible: true,
///   theme: TerminalTheme.dark(),
/// )
/// ```
class TerminalPanel extends StatefulWidget {
  /// Creates a terminal panel widget.
  ///
  /// Parameters:
  /// - [sessionManager]: Optional session manager (defaults to singleton instance)
  /// - [theme]: Optional theme for terminal appearance
  /// - [initialHeight]: Initial height of the panel in pixels (defaults to 300)
  /// - [visible]: Initial visibility state (defaults to true)
  const TerminalPanel({
    TerminalSessionManager? sessionManager,
    this.theme,
    this.initialHeight = 300.0,
    this.visible = true,
    super.key,
  }) : _sessionManager = sessionManager;

  /// Session manager for managing terminal sessions.
  final TerminalSessionManager? _sessionManager;

  /// Theme for terminal appearance.
  final TerminalTheme? theme;

  /// Initial height of the panel in pixels.
  final double initialHeight;

  /// Initial visibility state of the panel.
  final bool visible;

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  /// Current height of the panel.
  late double _panelHeight;

  /// Current visibility state.
  late bool _isVisible;

  /// Session manager instance.
  late TerminalSessionManager _sessionManager;

  /// Minimum panel height in pixels.
  static const double _minHeight = 100.0;

  /// Maximum panel height as a fraction of screen height.
  static const double _maxHeightFraction = 0.8;

  /// Drag handle height in pixels.
  static const double _dragHandleHeight = 4.0;

  @override
  void initState() {
    super.initState();
    _panelHeight = widget.initialHeight;
    _isVisible = widget.visible;
    _sessionManager =
        widget._sessionManager ?? TerminalSessionManager.instance;
    
    // Automatically create first terminal session if none exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sessionManager.sessionCount == 0) {
        _createNewTerminal();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    final theme = widget.theme ?? TerminalTheme.dark();
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * _maxHeightFraction;

    // Clamp panel height to valid range
    _panelHeight = _panelHeight.clamp(_minHeight, maxHeight);

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // Ctrl+Shift+` to create new terminal
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.backquote,
        ): const _CreateTerminalIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CreateTerminalIntent: CallbackAction<_CreateTerminalIntent>(
            onInvoke: (_) => _createNewTerminal(),
          ),
        },
        child: Focus(
          autofocus: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle for resizing
              _buildDragHandle(theme),
              // Terminal panel content
              SizedBox(
                height: _panelHeight,
                child: Column(
                  children: [
                    // Terminal tab bar
                    TerminalTabBar(
                      sessionManager: _sessionManager,
                      theme: theme,
                    ),
                    // Active terminal view
                    Expanded(
                      child: _buildTerminalView(theme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the drag handle for resizing the panel.
  Widget _buildDragHandle(TerminalTheme theme) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          // Subtract delta because dragging up should increase height
          _panelHeight -= details.delta.dy;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpDown,
        child: Container(
          height: _dragHandleHeight,
          decoration: BoxDecoration(
            color: theme.background,
            border: Border(
              top: BorderSide(
                color: Color.alphaBlend(
                  theme.foreground.withOpacity(0.2),
                  theme.background,
                ),
              ),
            ),
          ),
          child: Center(
            child: Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                color: theme.foreground.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the terminal view for the active session.
  Widget _buildTerminalView(TerminalTheme theme) {
    return ListenableBuilder(
      listenable: _sessionManager,
      builder: (context, child) {
        final activeSession = _sessionManager.activeSession;

        if (activeSession == null) {
          return Container(
            color: theme.background,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.terminal,
                    size: 48,
                    color: theme.foreground.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active terminal',
                    style: TextStyle(
                      color: theme.foreground.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Press Ctrl+Shift+` to create a new terminal',
                    style: TextStyle(
                      color: theme.foreground.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return TerminalView(
          controller: activeSession,
          theme: theme,
        );
      },
    );
  }

  /// Creates a new terminal session.
  Future<void> _createNewTerminal() async {
    if (_sessionManager.canCreateSession) {
      try {
        await _sessionManager.createSession();
      } catch (e) {
        debugPrint('Failed to create terminal session: $e');
      }
    }
  }

  /// Toggles panel visibility.
  void toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  /// Sets panel visibility.
  void setVisible(bool visible) {
    setState(() {
      _isVisible = visible;
    });
  }

  /// Sets panel height.
  void setHeight(double height) {
    setState(() {
      _panelHeight = height;
    });
  }
}

/// Intent for creating a new terminal via keyboard shortcut.
class _CreateTerminalIntent extends Intent {
  const _CreateTerminalIntent();
}
