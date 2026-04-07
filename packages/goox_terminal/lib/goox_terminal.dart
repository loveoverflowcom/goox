/// PTY Terminal - Cross-platform pseudo-terminal support for Flutter
///
/// This library provides a high-level API for creating and managing
/// PTY (Pseudo-Terminal) sessions through Rust FFI.
///
/// ## Features
///
/// - Create and manage multiple PTY sessions
/// - Read/write data to/from terminal
/// - Resize terminal dynamically
/// - Send Unix signals to processes
/// - Cross-platform support (macOS, Linux, Windows)
///
/// ## Usage
///
/// ```dart
/// import 'package:goox_terminal/goox_terminal.dart';
///
/// // Create a session
/// final config = PtyConfig(shell: '/bin/bash');
/// final sessionId = await PtyManager.instance.createSession(config);
///
/// // Get the session
/// final session = PtyManager.instance.getSession(sessionId)!;
///
/// // Listen to output
/// session.outputStream.listen((data) {
///   print(utf8.decode(data));
/// });
///
/// // Write input
/// await session.write('echo "Hello"\n');
///
/// // Close when done
/// await session.close();
/// ```
library;

// Models and Exceptions (via module exports)
export 'src/backend/terminal_backend.dart';
// Lifecycle helpers
export 'src/bootstrap.dart' show disposeGooxTerminal, initializeGooxTerminal;
export 'src/exceptions.dart';
export 'src/models.dart';
// Core API
export 'src/pty_manager.dart';
export 'src/pty_session.dart';
// UI Components
export 'src/ui/ui.dart';
// Terminal Models
export 'src/models/ansi_style.dart';
export 'src/models/shell_config.dart';
export 'src/models/terminal_output.dart';
// Terminal Services
export 'src/services/ansi_parser.dart';
export 'src/services/pty_service.dart';
export 'src/services/pty_service_impl.dart';
export 'src/services/shell_detector.dart';
