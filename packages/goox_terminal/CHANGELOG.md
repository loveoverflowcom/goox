# Changelog

## [0.2.0] - 2026-04-09

### Changed
- Complete refactor to simple terminal wrapper
- Removed complex session management
- Removed custom PTY service implementation
- Simplified to use xterm and flutter_pty directly

### Added
- `GooxTerminal` widget - simple terminal widget
- `GooxTerminalController` - basic terminal controller
- Copy/paste support with right-click
- Automatic shell detection

### Removed
- `TerminalPanel` and tab management
- `TerminalSessionManager`
- Complex session lifecycle management
- ANSI parser service
- Custom PTY service
- Multiple dependencies (equatable, meta, path, mocktail)

### Dependencies
- Kept only essential: `xterm` and `flutter_pty`

## [0.1.0] - Previous version
- Initial release with complex session management
