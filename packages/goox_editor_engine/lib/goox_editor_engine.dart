/// Core editor functionality and Rust backend communication.
///
/// This library provides interfaces and implementations for interacting with
/// the Rust-based language server backend through flutter_rust_bridge.
library;

// Client interfaces and implementations
export 'src/client/editor_core_client.dart';
export 'src/client/rust_editor_core_client.dart';
// Exceptions
export 'src/exceptions/editor_core_exception.dart';
// Data models
export 'src/models/cursor_position.dart';
export 'src/models/editor_patch.dart';
export 'src/models/editor_view_state.dart';
export 'src/models/language_server_hover.dart';
export 'src/models/language_server_location.dart';
export 'src/models/language_server_range.dart';
