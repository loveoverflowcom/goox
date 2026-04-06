# Design: PTY Terminal Rust FFI Package

## 1. Architecture Overview

### 1.1 High-Level Architecture

```
Flutter Application Layer
    |
    v
Dart API Layer (goox_terminal package)
    |
    v
FFI Bridge Layer (flutter_rust_bridge)
    |
    v
Rust Core Layer (pty_core)
    |
    v
Platform PTY Layer (portable-pty)
    |
    v
OS PTY APIs (Unix PTY / Windows ConPTY)
```

### 1.2 Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  Flutter Application                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Dart Layer (goox_terminal)                      │
│  ┌─────────────────┐  ┌──────────────────┐                 │
│  │  PtyManager     │  │  PtySession      │                 │
│  │  - create()     │  │  - write()       │                 │
│  │  - close()      │  │  - outputStream  │                 │
│  │  - list()       │  │  - resize()      │                 │
│  └─────────────────┘  └──────────────────┘                 │
│           │                     │                            │
│           └──────────┬──────────┘                            │
│                      ▼                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         FFI Bridge (Generated)                       │   │
│  │  - Type conversions                                  │   │
│  │  - Memory management                                 │   │
│  │  - Async handling                                    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Rust Layer (pty_core)                           │
│  ┌─────────────────┐  ┌──────────────────┐                 │
│  │  PtyCore        │  │  SessionManager  │                 │
│  │  - new_session()│  │  - sessions: Map │                 │
│  │  - write_input()│  │  - next_id()     │                 │
│  │  - read_output()│  │  - cleanup()     │                 │
│  └─────────────────┘  └──────────────────┘                 │
│           │                     │                            │
│           └──────────┬──────────┘                            │
│                      ▼                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Platform Abstraction                         │   │
│  │  - UnixPty / WindowsPty                             │   │
│  │  - portable-pty crate                               │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  OS PTY APIs                                 │
│  Unix: posix_openpt, grantpt, unlockpt                     │
│  Windows: CreatePseudoConsole (ConPTY)                     │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 Data Flow

**Session Creation Flow:**
```
User Code
  └─> PtyManager.createSession(config)
      └─> FFI Bridge
          └─> PtyCore::new_session()
              └─> portable_pty::native_pty_system()
                  └─> OS PTY API
                      └─> Return PTY handle
              └─> Spawn child process
              └─> Setup I/O streams
              └─> Return session_id
          └─> Store session reference
      └─> Return session_id to Dart
```

**Write Flow:**
```
User Code
  └─> session.write(data)
      └─> FFI Bridge (convert String to bytes)
          └─> PtyCore::write_input(session_id, bytes)
              └─> Get PTY writer
              └─> Write to PTY master
              └─> Return bytes_written
          └─> Return result
      └─> Return to user
```

**Read Flow (Stream):**
```
PTY Output Available
  └─> Rust async task reads from PTY
      └─> PtyCore::read_output()
          └─> Read from PTY master
          └─> Send to Dart via StreamSink
              └─> FFI Bridge (convert bytes to Uint8List)
                  └─> Dart Stream emits data
                      └─> User's StreamSubscription receives data
```

## 2. Detailed Design

### 2.1 Dart API Layer

#### 2.1.1 PtyManager Class

```dart
/// Main entry point for PTY operations
class PtyManager {
  /// Singleton instance
  static final PtyManager instance = PtyManager._();
  
  PtyManager._();
  
  /// Create a new PTY session
  Future<String> createSession(PtyConfig config);
  
  /// Close a PTY session
  Future<void> closeSession(String sessionId);
  
  /// Get a PTY session by ID
  PtySession? getSession(String sessionId);
  
  /// List all active session IDs
  List<String> listSessions();
  
  /// Check if a session is running
  bool isSessionRunning(String sessionId);
}
```

#### 2.1.2 PtySession Class

```dart
/// Represents an active PTY session
class PtySession {
  final String id;
  final PtyConfig config;
  
  /// Write data to the PTY
  Future<int> write(String data);
  
  /// Write binary data to the PTY
  Future<int> writeBytes(Uint8List data);
  
  /// Get the output stream (stdout + stderr)
  Stream<Uint8List> get outputStream;
  
  /// Resize the terminal
  Future<void> resize(int rows, int cols);
  
  /// Get current terminal size
  Future<PtySize> getSize();
  
  /// Send a signal to the process
  Future<void> sendSignal(PtySignal signal);
  
  /// Get process ID
  int? get pid;
  
  /// Get exit code (null if still running)
  int? get exitCode;
  
  /// Wait for the process to exit
  Future<int> waitForExit();
  
  /// Close the session
  Future<void> close();
}
```

#### 2.1.3 Configuration Models

```dart
/// Configuration for creating a PTY session
class PtyConfig {
  /// Shell command to run (default: system shell)
  final String? shell;
  
  /// Command arguments
  final List<String> args;
  
  /// Working directory
  final String? workingDirectory;
  
  /// Environment variables
  final Map<String, String>? environment;
  
  /// Initial terminal size
  final PtySize size;
  
  const PtyConfig({
    this.shell,
    this.args = const [],
    this.workingDirectory,
    this.environment,
    this.size = const PtySize(rows: 24, cols: 80),
  });
}

/// Terminal size
class PtySize {
  final int rows;
  final int cols;
  
  const PtySize({required this.rows, required this.cols});
}

/// Unix signals
enum PtySignal {
  sigint,   // Ctrl+C
  sigterm,  // Terminate
  sigkill,  // Force kill
  sighup,   // Hangup
  sigquit,  // Quit
}
```

#### 2.1.4 Exception Types

```dart
/// Base exception for PTY operations
class PtyException implements Exception {
  final String message;
  final String? sessionId;
  final Object? cause;
  
  const PtyException(this.message, {this.sessionId, this.cause});
  
  @override
  String toString() => 'PtyException: $message';
}

/// Session not found
class SessionNotFoundException extends PtyException {
  const SessionNotFoundException(String sessionId)
      : super('Session not found: $sessionId', sessionId: sessionId);
}

/// Session creation failed
class SessionCreationException extends PtyException {
  const SessionCreationException(String message, {Object? cause})
      : super('Failed to create session: $message', cause: cause);
}

/// I/O operation failed
class PtyIOException extends PtyException {
  const PtyIOException(String message, {String? sessionId, Object? cause})
      : super('I/O error: $message', sessionId: sessionId, cause: cause);
}
```

### 2.2 Rust Core Layer

#### 2.2.1 Module Structure

```
pty_core/
├── src/
│   ├── lib.rs              # Main entry point, FFI exports
│   ├── session.rs          # Session management
│   ├── pty_wrapper.rs      # PTY abstraction
│   ├── io_handler.rs       # I/O handling
│   ├── error.rs            # Error types
│   └── bridge.rs           # FFI bridge helpers
├── Cargo.toml
└── build.rs
```

#### 2.2.2 Core Types (Rust)

```rust
// lib.rs
use flutter_rust_bridge::frb;

/// Initialize the PTY core
#[frb(init)]
pub fn init_pty_core() {
    // Initialize logging, etc.
}

/// Create a new PTY session
#[frb]
pub async fn create_session(config: PtyConfigRust) -> Result<String, PtyError> {
    SESSION_MANAGER.create_session(config).await
}

/// Write data to a session
#[frb]
pub async fn write_to_session(
    session_id: String,
    data: Vec<u8>
) -> Result<usize, PtyError> {
    SESSION_MANAGER.write(session_id, data).await
}

/// Get output stream for a session
#[frb(stream)]
pub async fn get_output_stream(
    session_id: String
) -> Result<impl Stream<Item = Vec<u8>>, PtyError> {
    SESSION_MANAGER.get_output_stream(session_id).await
}

/// Resize a session
#[frb]
pub async fn resize_session(
    session_id: String,
    rows: u16,
    cols: u16
) -> Result<(), PtyError> {
    SESSION_MANAGER.resize(session_id, rows, cols).await
}

/// Close a session
#[frb]
pub async fn close_session(session_id: String) -> Result<(), PtyError> {
    SESSION_MANAGER.close_session(session_id).await
}
```

```rust
// session.rs
use portable_pty::{native_pty_system, PtySize, CommandBuilder};
use tokio::sync::RwLock;
use std::collections::HashMap;

pub struct SessionManager {
    sessions: RwLock<HashMap<String, PtySession>>,
    next_id: AtomicU64,
}

impl SessionManager {
    pub async fn create_session(
        &self,
        config: PtyConfigRust
    ) -> Result<String, PtyError> {
        let session_id = self.generate_id();
        
        // Create PTY
        let pty_system = native_pty_system();
        let pair = pty_system.openpty(PtySize {
            rows: config.rows,
            cols: config.cols,
            pixel_width: 0,
            pixel_height: 0,
        })?;
        
        // Spawn process
        let mut cmd = CommandBuilder::new(&config.shell);
        cmd.args(&config.args);
        if let Some(cwd) = config.working_directory {
            cmd.cwd(cwd);
        }
        if let Some(env) = config.environment {
            cmd.env_clear();
            for (k, v) in env {
                cmd.env(k, v);
            }
        }
        
        let child = pair.slave.spawn_command(cmd)?;
        
        // Create session
        let session = PtySession::new(
            session_id.clone(),
            pair.master,
            child,
        );
        
        // Start I/O tasks
        session.start_io_tasks().await;
        
        // Store session
        self.sessions.write().await.insert(session_id.clone(), session);
        
        Ok(session_id)
    }
    
    pub async fn write(
        &self,
        session_id: String,
        data: Vec<u8>
    ) -> Result<usize, PtyError> {
        let sessions = self.sessions.read().await;
        let session = sessions.get(&session_id)
            .ok_or(PtyError::SessionNotFound)?;
        
        session.write(data).await
    }
    
    pub async fn get_output_stream(
        &self,
        session_id: String
    ) -> Result<impl Stream<Item = Vec<u8>>, PtyError> {
        let sessions = self.sessions.read().await;
        let session = sessions.get(&session_id)
            .ok_or(PtyError::SessionNotFound)?;
        
        Ok(session.output_stream())
    }
    
    pub async fn close_session(
        &self,
        session_id: String
    ) -> Result<(), PtyError> {
        let mut sessions = self.sessions.write().await;
        if let Some(session) = sessions.remove(&session_id) {
            session.close().await?;
        }
        Ok(())
    }
    
    fn generate_id(&self) -> String {
        let id = self.next_id.fetch_add(1, Ordering::SeqCst);
        format!("pty_{}", id)
    }
}

// Global session manager
lazy_static! {
    pub static ref SESSION_MANAGER: SessionManager = SessionManager::new();
}
```

```rust
// pty_wrapper.rs
use portable_pty::{MasterPty, Child};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::sync::mpsc;

pub struct PtySession {
    id: String,
    master: Box<dyn MasterPty + Send>,
    child: Box<dyn Child + Send>,
    output_tx: mpsc::UnboundedSender<Vec<u8>>,
    output_rx: RwLock<Option<mpsc::UnboundedReceiver<Vec<u8>>>>,
}

impl PtySession {
    pub fn new(
        id: String,
        master: Box<dyn MasterPty + Send>,
        child: Box<dyn Child + Send>,
    ) -> Self {
        let (output_tx, output_rx) = mpsc::unbounded_channel();
        
        Self {
            id,
            master,
            child,
            output_tx,
            output_rx: RwLock::new(Some(output_rx)),
        }
    }
    
    pub async fn start_io_tasks(&self) {
        // Spawn task to read from PTY and send to output channel
        let mut reader = self.master.try_clone_reader().unwrap();
        let tx = self.output_tx.clone();
        
        tokio::spawn(async move {
            let mut buffer = vec![0u8; 4096];
            loop {
                match reader.read(&mut buffer).await {
                    Ok(0) => break, // EOF
                    Ok(n) => {
                        let data = buffer[..n].to_vec();
                        if tx.send(data).is_err() {
                            break; // Channel closed
                        }
                    }
                    Err(e) => {
                        eprintln!("PTY read error: {}", e);
                        break;
                    }
                }
            }
        });
    }
    
    pub async fn write(&self, data: Vec<u8>) -> Result<usize, PtyError> {
        let mut writer = self.master.take_writer().unwrap();
        writer.write_all(&data).await?;
        Ok(data.len())
    }
    
    pub fn output_stream(&self) -> impl Stream<Item = Vec<u8>> {
        let rx = self.output_rx.write().await.take()
            .expect("Output stream already taken");
        
        tokio_stream::wrappers::UnboundedReceiverStream::new(rx)
    }
    
    pub async fn resize(&self, rows: u16, cols: u16) -> Result<(), PtyError> {
        self.master.resize(PtySize {
            rows,
            cols,
            pixel_width: 0,
            pixel_height: 0,
        })?;
        Ok(())
    }
    
    pub async fn close(self) -> Result<(), PtyError> {
        // Kill child process
        self.child.kill()?;
        
        // Wait for process to exit
        let _ = self.child.wait().await;
        
        // PTY will be closed when dropped
        Ok(())
    }
}
```

### 2.3 FFI Bridge Layer

#### 2.3.1 Code Generation

Using `flutter_rust_bridge_codegen`:

```bash
# Generate FFI bindings
flutter_rust_bridge_codegen \
  --rust-input pty_core/src/lib.rs \
  --dart-output lib/src/bridge_generated.dart \
  --dart-decl-output lib/src/bridge_definitions.dart
```

#### 2.3.2 Memory Management

**Dart → Rust:**
- Strings: Converted to `String` (owned)
- Lists: Converted to `Vec<T>` (owned)
- Objects: Converted to Rust structs

**Rust → Dart:**
- Strings: Converted to Dart `String`
- Vectors: Converted to Dart `List` or `Uint8List`
- Streams: Converted to Dart `Stream<T>`

**Resource Cleanup:**
- Rust objects are reference-counted
- Dart finalizers ensure Rust resources are freed
- Explicit `close()` methods for immediate cleanup

### 2.4 Platform-Specific Considerations

#### 2.4.1 Unix (macOS, Linux)

**PTY Implementation:**
- Use `posix_openpt()` to create PTY master
- Use `grantpt()` and `unlockpt()` to setup PTY
- Use `ptsname()` to get slave PTY path
- Fork and exec child process with slave PTY as stdin/stdout/stderr

**Signal Handling:**
- Use `kill()` syscall to send signals
- Support SIGINT, SIGTERM, SIGKILL, SIGHUP, SIGQUIT

#### 2.4.2 Windows

**ConPTY Implementation:**
- Use `CreatePseudoConsole()` API (Windows 10 1809+)
- Create pipes for input/output
- Use `CreateProcess()` with `STARTUPINFOEX` and `PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE`

**Signal Handling:**
- Use `GenerateConsoleCtrlEvent()` for Ctrl+C
- Use `TerminateProcess()` for force kill
- Limited signal support compared to Unix

### 2.5 Error Handling Strategy

#### 2.5.1 Error Propagation

```rust
// Rust error type
#[derive(Debug, thiserror::Error)]
pub enum PtyError {
    #[error("Session not found: {0}")]
    SessionNotFound(String),
    
    #[error("Failed to create PTY: {0}")]
    PtyCreationFailed(String),
    
    #[error("I/O error: {0}")]
    IoError(#[from] std::io::Error),
    
    #[error("Process spawn failed: {0}")]
    SpawnFailed(String),
}

// Convert to Dart exception
impl From<PtyError> for flutter_rust_bridge::DartError {
    fn from(err: PtyError) -> Self {
        flutter_rust_bridge::DartError {
            message: err.to_string(),
            code: match err {
                PtyError::SessionNotFound(_) => "SESSION_NOT_FOUND",
                PtyError::PtyCreationFailed(_) => "PTY_CREATION_FAILED",
                PtyError::IoError(_) => "IO_ERROR",
                PtyError::SpawnFailed(_) => "SPAWN_FAILED",
            }.to_string(),
        }
    }
}
```

#### 2.5.2 Error Recovery

- **Transient errors:** Retry with exponential backoff
- **Fatal errors:** Close session and notify user
- **Resource exhaustion:** Implement limits and graceful degradation

## 3. Implementation Details

### 3.1 Package Structure

```
packages/goox_terminal/
├── lib/
│   ├── goox_terminal.dart           # Main export
│   ├── src/
│   │   ├── pty_manager.dart        # PtyManager class
│   │   ├── pty_session.dart        # PtySession class
│   │   ├── models/
│   │   │   ├── pty_config.dart     # Configuration models
│   │   │   ├── pty_size.dart       # Size model
│   │   │   └── pty_signal.dart     # Signal enum
│   │   ├── exceptions/
│   │   │   └── pty_exception.dart  # Exception types
│   │   ├── bridge_generated.dart   # Generated FFI code
│   │   └── bridge_definitions.dart # Generated types
├── rust/
│   └── pty_core/
│       ├── src/
│       │   ├── lib.rs
│       │   ├── session.rs
│       │   ├── pty_wrapper.rs
│       │   ├── io_handler.rs
│       │   ├── error.rs
│       │   └── bridge.rs
│       ├── Cargo.toml
│       └── build.rs
├── example/
│   └── lib/
│       └── main.dart               # Example app
├── test/
│   ├── pty_manager_test.dart
│   ├── pty_session_test.dart
│   └── integration_test.dart
├── pubspec.yaml
└── README.md
```

### 3.2 Build Configuration

#### 3.2.1 Cargo.toml

```toml
[package]
name = "pty_core"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib", "staticlib"]

[dependencies]
flutter_rust_bridge = "2.0"
portable-pty = "0.8"
tokio = { version = "1.35", features = ["full"] }
tokio-stream = "0.1"
lazy_static = "1.4"
thiserror = "1.0"

[target.'cfg(windows)'.dependencies]
windows = { version = "0.52", features = ["Win32_System_Console"] }

[build-dependencies]
flutter_rust_bridge_codegen = "2.0"
```

#### 3.2.2 pubspec.yaml

```yaml
name: goox_terminal
description: PTY terminal support for Flutter via Rust FFI
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  ffi: ^2.1.0
  meta: ^1.10.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mocktail: ^1.0.0

flutter:
  plugin:
    platforms:
      macos:
        ffiPlugin: true
      linux:
        ffiPlugin: true
      windows:
        ffiPlugin: true
```

### 3.3 Testing Strategy

#### 3.3.1 Unit Tests (Dart)

```dart
// Test PtyManager
test('createSession returns valid session ID', () async {
  final config = PtyConfig(shell: '/bin/bash');
  final sessionId = await PtyManager.instance.createSession(config);
  
  expect(sessionId, isNotEmpty);
  expect(PtyManager.instance.isSessionRunning(sessionId), isTrue);
});

// Test PtySession
test('write and read data', () async {
  final session = await createTestSession();
  
  final output = <String>[];
  session.outputStream.listen((data) {
    output.add(utf8.decode(data));
  });
  
  await session.write('echo "test"\n');
  await Future.delayed(Duration(milliseconds: 100));
  
  expect(output.join(), contains('test'));
});
```

#### 3.3.2 Integration Tests

```dart
testWidgets('full terminal workflow', (tester) async {
  // Create session
  final config = PtyConfig(
    shell: '/bin/bash',
    size: PtySize(rows: 24, cols: 80),
  );
  final sessionId = await PtyManager.instance.createSession(config);
  
  // Get session
  final session = PtyManager.instance.getSession(sessionId);
  expect(session, isNotNull);
  
  // Write command
  await session!.write('ls -la\n');
  
  // Read output
  final output = await session.outputStream.first;
  expect(output, isNotEmpty);
  
  // Resize
  await session.resize(30, 100);
  final size = await session.getSize();
  expect(size.rows, equals(30));
  expect(size.cols, equals(100));
  
  // Close
  await session.close();
  expect(PtyManager.instance.isSessionRunning(sessionId), isFalse);
});
```

#### 3.3.3 Property-Based Tests

```dart
// Property: All created sessions can be closed
test('property: all sessions can be closed', () async {
  final configs = generateRandomConfigs(100);
  
  for (final config in configs) {
    final sessionId = await PtyManager.instance.createSession(config);
    await PtyManager.instance.closeSession(sessionId);
    expect(PtyManager.instance.isSessionRunning(sessionId), isFalse);
  }
});

// Property: Write preserves data length
test('property: write preserves data length', () async {
  final session = await createTestSession();
  final testData = generateRandomStrings(100);
  
  for (final data in testData) {
    final bytesWritten = await session.write(data);
    expect(bytesWritten, equals(utf8.encode(data).length));
  }
});
```

### 3.4 Performance Optimization

#### 3.4.1 Buffering Strategy

- **Input buffering:** Batch small writes to reduce FFI overhead
- **Output buffering:** Use ring buffer in Rust to handle bursts
- **Backpressure:** Implement flow control to prevent memory exhaustion

#### 3.4.2 Async I/O

- Use Tokio async runtime in Rust
- Non-blocking I/O operations
- Efficient event loop integration

#### 3.4.3 Memory Management

- Reuse buffers to reduce allocations
- Limit buffer sizes to prevent unbounded growth
- Implement proper cleanup in destructors

## 4. Security Considerations

### 4.1 Input Validation

- Validate all inputs from Dart side
- Sanitize shell commands and arguments
- Prevent command injection attacks

### 4.2 Resource Limits

- Limit number of concurrent sessions (default: 10)
- Limit buffer sizes (default: 1 MB per session)
- Implement timeouts for operations

### 4.3 Privilege Management

- Run child processes with minimal privileges
- Don't escalate privileges unnecessarily
- Respect system security policies

## 5. Deployment and Distribution

### 5.1 Platform Binaries

- Pre-build Rust binaries for common platforms
- Include binaries in pub package
- Fallback to local build if needed

### 5.2 CI/CD Pipeline

```yaml
# .github/workflows/build.yml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      
      - name: Build Rust
        run: |
          cd rust/pty_core
          cargo build --release
      
      - name: Run Dart tests
        run: flutter test
      
      - name: Run integration tests
        run: flutter test integration_test
```

### 5.3 Documentation

- Comprehensive API documentation
- Usage examples
- Platform-specific notes
- Troubleshooting guide

## 6. Future Enhancements

### 6.1 Phase 2 Features

- Terminal emulation (VT100, xterm)
- Session persistence and restoration
- Terminal recording/playback
- Remote PTY support (SSH)

### 6.2 Performance Improvements

- Zero-copy I/O where possible
- SIMD optimizations for data processing
- Custom memory allocators

### 6.3 Developer Experience

- Hot reload support
- Better error messages
- Interactive debugging tools
- Performance profiling tools
