# Error Handling Implementation

This document describes the error handling implementation for the goox_terminal package.

## Overview

The error handling system provides comprehensive error detection, reporting, and recovery mechanisms throughout the terminal lifecycle. It includes custom exceptions, validation, error state management, and UI indicators.

## Components

### 1. Custom Exceptions (Task 14.1)

#### PtyCreationException

A type alias for `ProcessSpawnException` that provides semantic clarity when PTY creation fails.

**Location**: `lib/src/exceptions/pty_exception.dart`

**Usage**:
```dart
try {
  await controller.initialize();
} on PtyCreationException catch (e) {
  print('Failed to create PTY: ${e.message}');
  print('Cause: ${e.cause}');
}
```

**When thrown**:
- Shell path does not exist
- Shell is not executable
- Insufficient permissions
- System resource exhaustion

### 2. TerminalController Error Handling (Task 14.2)

#### PTY Creation Error Handling

**Location**: `lib/src/controllers/terminal_controller.dart` - `initialize()` method

The controller wraps PTY.start in a try-catch block and throws `ProcessSpawnException` (PtyCreationException) with descriptive error messages.

```dart
try {
  _pty = Pty.start(
    _shellConfig.shellPath,
    arguments: _shellConfig.arguments,
    environment: _shellConfig.environment,
    workingDirectory: _shellConfig.workingDirectory,
    columns: _size.cols,
    rows: _size.rows,
  );
} catch (e) {
  throw ProcessSpawnException(
    'Failed to start shell: ${_shellConfig.shellPath}',
    cause: e,
  );
}
```

#### PTY Output Stream Error Handling

**Location**: `lib/src/controllers/terminal_controller.dart` - `initialize()` and `restart()` methods

The controller handles PTY output stream errors by setting status to error:

```dart
_outputSubscription = _pty!.output.listen(
  (data) {
    // Process data...
  },
  onError: (error) {
    // Handle PTY output stream errors
    _updateStatus(TerminalStatus.error);
  },
  onDone: () async {
    // Handle process exit...
  },
);
```

#### Input Validation

The controller validates inputs and throws appropriate errors:

**ArgumentError** - Invalid dimensions:
```dart
Future<void> resize(int rows, int cols) async {
  if (rows < 1 || rows > 1000) {
    throw ArgumentError(
      'Rows must be between 1 and 1000, got $rows',
    );
  }
  if (cols < 1 || cols > 1000) {
    throw ArgumentError(
      'Cols must be between 1 and 1000, got $cols',
    );
  }
  // ...
}
```

**StateError** - Operations on non-running terminal:
```dart
Future<void> write(String data) async {
  if (status != TerminalStatus.running) {
    throw StateError(
      'Cannot write to terminal: terminal is not running (status: $status)',
    );
  }
  // ...
}

Future<void> resize(int rows, int cols) async {
  // ... validation ...
  if (status != TerminalStatus.running) {
    throw StateError(
      'Cannot resize terminal: terminal is not running (status: $status)',
    );
  }
  // ...
}

Future<void> kill([PtySignal signal = PtySignal.sigterm]) async {
  if (status != TerminalStatus.running) {
    throw StateError(
      'Cannot kill terminal: terminal is not running (status: $status)',
    );
  }
  // ...
}
```

### 3. Error UI Indicators (Task 14.3)

#### Terminal Tab Error Indicator

**Location**: `lib/src/ui/terminal_tab_bar.dart`

The terminal tab bar shows an error icon and red color when terminal status is error:

```dart
IconData _getStatusIcon(TerminalStatus status) {
  switch (status) {
    case TerminalStatus.error:
      return Icons.error_outline;
    // ...
  }
}

Color _getStatusColor(TerminalStatus status, TerminalTheme theme) {
  switch (status) {
    case TerminalStatus.error:
      return theme.red; // Error color
    // ...
  }
}
```

#### Terminal View Error Overlay

**Location**: `lib/src/ui/terminal_view.dart`

The terminal view shows an error overlay with restart button when status is error:

```dart
@override
Widget build(BuildContext context) {
  return StreamBuilder<TerminalStatus>(
    stream: widget.controller.statusStream,
    initialData: widget.controller.status,
    builder: (context, snapshot) {
      final status = snapshot.data ?? TerminalStatus.initializing;

      // Show error overlay when terminal is in error state
      if (status == TerminalStatus.error) {
        return _buildErrorOverlay(context, theme);
      }

      // Normal terminal view...
    },
  );
}
```

The error overlay includes:
- Large error icon (red)
- "Terminal Error" heading
- Descriptive error message
- "Restart Terminal" button that calls `controller.restart()`

## Error Scenarios

### 1. PTY Creation Failure

**Trigger**: Invalid shell path, missing permissions, resource exhaustion

**Response**:
- Throws `PtyCreationException` with descriptive message
- Session is not added to registry
- User sees error message

**Recovery**:
- Check shell path
- Try default shell
- Verify permissions

### 2. PTY Output Stream Error

**Trigger**: Process crash, pipe broken, I/O error

**Response**:
- Sets `controller.status` to `TerminalStatus.error`
- Error icon appears in terminal tab (red)
- Error overlay appears in terminal view
- "Restart Terminal" button is shown

**Recovery**:
- Click "Restart Terminal" button
- Creates new PTY with same configuration
- Terminal returns to running state

### 3. Invalid Resize Dimensions

**Trigger**: `resize()` called with rows or cols outside valid range (1-1000)

**Response**:
- Throws `ArgumentError` with message
- Terminal dimensions remain unchanged

**Recovery**:
- Clamp dimensions to valid range
- Retry resize with valid dimensions

### 4. Write to Closed Terminal

**Trigger**: `write()` called when status != running

**Response**:
- Throws `StateError` with message
- Input is not sent to PTY

**Recovery**:
- Check terminal status before writing
- Restart terminal if needed
- Ignore input if terminal is closed

### 5. Kill Non-Running Terminal

**Trigger**: `kill()` called when status != running

**Response**:
- Throws `StateError` with message
- No signal is sent

**Recovery**:
- Check terminal status before killing
- Handle already-closed terminals gracefully

## Testing

### Unit Tests

**Location**: `test/controllers/terminal_controller_error_handling_test.dart`

Tests cover:
- PtyCreationException on invalid shell
- StateError when writing to non-running terminal
- ArgumentError with invalid resize dimensions
- StateError when resizing non-running terminal
- StateError when killing non-running terminal
- Status stream error handling

### Widget Tests

**Location**: `test/ui/terminal_view_error_test.dart`

Tests cover:
- Error overlay visibility when status is error
- Error icon and message display
- Restart button functionality

### Demo Application

**Location**: `example/error_handling_demo.dart`

Interactive demo showing:
- Invalid shell path handling
- Write to closed terminal handling
- Invalid resize handling
- Error UI overlay with restart button

## Requirements Validation

This implementation validates the following requirements:

- **Requirement 9.1**: PTY creation failures throw PtyCreationException ✓
- **Requirement 9.2**: PTY output stream errors set status to error ✓
- **Requirement 9.4**: Invalid resize dimensions throw ArgumentError ✓
- **Requirement 9.5**: Write to closed terminal throws StateError ✓

## Design Properties

This implementation validates the following design properties:

- **Property 25**: Stream error handling - PTY output stream errors update status to error ✓
- **Property 23**: Input rejection when not running - StateError thrown ✓
- **Property 11**: Invalid resize rejection - ArgumentError thrown ✓

## API Reference

### Exceptions

```dart
// Type alias for semantic clarity
typedef PtyCreationException = ProcessSpawnException;

// Base exception
class PtyException implements Exception {
  final String message;
  final String? sessionId;
  final Object? cause;
}

// Process spawn exception
class ProcessSpawnException extends PtyException {
  const ProcessSpawnException(String message, {Object? cause});
}
```

### Error Handling Methods

```dart
// TerminalController
Future<void> initialize(); // throws PtyCreationException
Future<void> write(String data); // throws StateError
Future<void> resize(int rows, int cols); // throws ArgumentError, StateError
Future<void> kill([PtySignal signal]); // throws StateError
Future<void> restart(); // throws PtyCreationException
```

### Status Stream

```dart
// Listen to status changes
controller.statusStream.listen((status) {
  if (status == TerminalStatus.error) {
    // Handle error state
  }
});
```

## Best Practices

1. **Always check terminal status** before performing operations
2. **Wrap operations in try-catch** to handle exceptions gracefully
3. **Listen to status stream** to react to error states
4. **Provide user feedback** when errors occur
5. **Offer recovery options** like restart button
6. **Log errors** for debugging purposes
7. **Validate inputs** before passing to controller methods

## Future Enhancements

- Add error codes for programmatic error handling
- Implement retry logic with exponential backoff
- Add telemetry for error tracking
- Provide more granular error types
- Add error recovery strategies
