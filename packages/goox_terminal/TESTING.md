# Testing Guide for goox_terminal

## Overview

The `goox_terminal` package includes comprehensive test coverage for terminal functionality. However, due to the nature of PTY (pseudo-terminal) operations requiring native code, some tests have specific requirements.

## Test Categories

### 1. Unit Tests (✅ Fully Supported)

Unit tests that don't require PTY initialization run successfully in standard test mode:

```bash
flutter test packages/goox_terminal/test/controllers/terminal_controller_test.dart
flutter test packages/goox_terminal/test/controllers/terminal_controller_buffer_test.dart
flutter test packages/goox_terminal/test/controllers/terminal_controller_initialize_test.dart
flutter test packages/goox_terminal/test/controllers/terminal_controller_kill_test.dart
flutter test packages/goox_terminal/test/controllers/terminal_controller_title_test.dart
flutter test packages/goox_terminal/test/controllers/terminal_controller_utf8_test.dart
```

**Coverage:**
- Terminal controller lifecycle
- Buffer management
- Title parsing
- UTF-8 encoding/decoding
- Session management
- Configuration validation

### 2. Property-Based Tests (✅ Fully Supported)

Property-based tests for terminal resize functionality:

```bash
flutter test packages/goox_terminal/test/controllers/terminal_resize_bug_test.dart
flutter test packages/goox_terminal/test/controllers/terminal_preservation_property_test.dart
```

**Coverage:**
- Bug condition exploration (resize synchronization)
- Preservation properties (non-resize operations)
- Input/output data flow
- Status tracking
- Title updates

### 3. Integration Tests (⚠️ Requires Native Library)

Integration tests that spawn actual PTY processes require the flutter_pty native library:

```bash
# These will fail in standard test mode
flutter test test/terminal_integration_test.dart
flutter test packages/goox_terminal/test/controllers/terminal_controller_error_handling_test.dart
```

## Known Issue: flutter_pty Native Library Loading

### Problem

Tests that initialize PTY processes fail with:

```
PtyException: Failed to spawn process: Failed to start shell: /bin/bash
Caused by: Invalid argument(s): Failed to load dynamic library 'flutter_pty.framework/flutter_pty'
```

### Root Cause

The `flutter_pty` package uses FFI (Foreign Function Interface) to interact with native platform code for PTY operations. This native code **cannot be loaded in the Dart VM test environment** used by `flutter test`.

The flutter_pty native library is only available when running in a full Flutter application context (e.g., `flutter run`), not in the isolated Dart VM used for unit tests.

### Affected Tests

- `terminal_controller_error_handling_test.dart` - Tests that verify error handling when PTY initialization fails
- `terminal_integration_test.dart` - End-to-end integration tests
- `pty_service_integration_test.dart` - PTY service integration tests (already skipped)

### Workarounds

#### Option 1: Manual Testing (Recommended for Now)

1. Run the application:
   ```bash
   flutter run -d macos  # or linux, windows
   ```

2. Test terminal functionality manually:
   - Create a terminal instance
   - Verify shell prompt appears
   - Type commands and verify execution
   - Resize terminal window and verify PTY resizes
   - Close terminal and verify cleanup

#### Option 2: Integration Test Package (Future Enhancement)

Use Flutter's `integration_test` package to run tests on actual devices/emulators where native code is available:

```bash
# Future implementation
flutter test integration_test/terminal_integration_test.dart
```

This requires:
- Setting up integration_test package
- Running tests on actual devices/emulators
- Longer test execution time

#### Option 3: Mock PTY (Not Recommended)

Mocking PTY operations is complex and doesn't provide real confidence in PTY functionality. The actual PTY behavior is critical for terminal operations.

## Running Tests

### Run All Supported Tests

```bash
# From workspace root
flutter test packages/goox_terminal/test/controllers/terminal_controller_test.dart \
  packages/goox_terminal/test/controllers/terminal_controller_buffer_test.dart \
  packages/goox_terminal/test/controllers/terminal_controller_initialize_test.dart \
  packages/goox_terminal/test/controllers/terminal_controller_kill_test.dart \
  packages/goox_terminal/test/controllers/terminal_controller_title_test.dart \
  packages/goox_terminal/test/controllers/terminal_controller_utf8_test.dart \
  packages/goox_terminal/test/controllers/terminal_resize_bug_test.dart \
  packages/goox_terminal/test/controllers/terminal_preservation_property_test.dart
```

### Run Property-Based Tests

```bash
flutter test packages/goox_terminal/test/controllers/terminal_resize_bug_test.dart
flutter test packages/goox_terminal/test/controllers/terminal_preservation_property_test.dart
```

**Note:** Property-based tests may take longer to run as they generate many test cases.

### Skip Integration Tests

Integration tests are automatically skipped or will fail gracefully. To explicitly skip them:

```bash
flutter test --exclude-tags integration
```

## Test Coverage Summary

| Test Category | Status | Count | Notes |
|--------------|--------|-------|-------|
| Unit Tests | ✅ Pass | 72 | All controller unit tests pass |
| Property-Based Tests | ✅ Pass | 29 | Bug condition + preservation tests |
| Error Handling Tests | ⚠️ Skip | 4 | Require PTY native library |
| Integration Tests | ⚠️ Skip | 3 | Require PTY native library |
| **Total Passing** | | **101** | Core functionality verified |

## CI/CD Recommendations

For continuous integration pipelines:

1. **Run supported tests only:**
   ```bash
   flutter test packages/goox_terminal/test/controllers/ \
     --exclude-name "error_handling"
   ```

2. **Accept known failures:**
   - Document that error handling and integration tests require native library
   - Focus on unit and property-based test results

3. **Manual verification:**
   - Include manual testing checklist in release process
   - Verify terminal functionality on each platform before release

## Future Improvements

1. **Integration Test Package:**
   - Migrate integration tests to `integration_test` package
   - Run on actual devices/emulators in CI/CD

2. **Platform-Specific Test Runners:**
   - Set up platform-specific test environments
   - Run tests with native library available

3. **Test Fixtures:**
   - Create recorded PTY sessions for playback testing
   - Reduce dependency on live PTY processes

## Related Documentation

- [PLATFORM_SETUP.md](PLATFORM_SETUP.md) - Platform-specific setup instructions
- [README.md](README.md) - Package overview and usage
- [Design Document](.kiro/specs/terminal-resize-fix/design.md) - Terminal resize fix design

## Questions?

If you encounter test failures not documented here, please:
1. Check if the test requires PTY initialization
2. Verify your Flutter version (3.0.0+)
3. Ensure dependencies are up to date: `flutter pub get`
4. Review platform-specific requirements in PLATFORM_SETUP.md
