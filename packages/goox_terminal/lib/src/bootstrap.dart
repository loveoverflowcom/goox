/// Package initialization helpers.
library;

import 'package:goox_terminal/src/backend/rust_terminal_backend.dart';
import 'package:goox_terminal/src/pty_manager.dart';

/// Initializes the Rust PTY bridge and prepares the default backend.
Future<void> initializeGooxTerminal() {
  return RustTerminalBackend.instance.ensureInitialized();
}

/// Disposes all managed terminal sessions and tears down the Rust bridge.
Future<void> disposeGooxTerminal() async {
  await PtyManager.instance.closeAllSessions();
  await RustTerminalBackend.instance.dispose();
}
