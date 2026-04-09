// Terminal wrapper for Flutter using xterm and flutter_pty.
//
// A simple terminal widget wrapper that manages terminal windows
// for the main goox project.

///
/// ## Usage
///
/// ```dart
/// import 'package:goox_terminal/goox_terminal.dart';
///
/// // Basic usage
/// GooxTerminal(
///   onTerminalReady: (controller) {
///     print('Terminal ready');
///   },
/// )
///
/// // With custom configuration
/// GooxTerminal(
///   maxLines: 10000,
///   autofocus: true,
///   backgroundOpacity: 0.7,
///   onTerminalReady: (controller) {
///     // Terminal is ready
///   },
/// )
/// ```

export 'src/goox_terminal_controller.dart';
export 'src/goox_terminal_panel.dart';
export 'src/goox_terminal_widget.dart';
