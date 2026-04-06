# Tasks: PTY Terminal Rust FFI Package

## Phase 1: Project Setup and Foundation

### 1.1 Project Structure Setup
- [ ] Create package directory structure
  - [ ] Create `packages/goox_terminal/` directory
  - [ ] Create `lib/`, `rust/`, `example/`, `test/` directories
  - [ ] Create `pubspec.yaml` with dependencies
  - [ ] Create `README.md` with project overview

### 1.2 Rust Project Setup
- [ ] Initialize Rust project
  - [ ] Create `rust/pty_core/` directory
  - [ ] Create `Cargo.toml` with dependencies
  - [ ] Add `portable-pty`, `tokio`, `flutter_rust_bridge` dependencies
  - [ ] Configure crate type as `cdylib` and `staticlib`
  - [ ] Create basic `lib.rs` with init function

### 1.3 FFI Bridge Setup
- [ ] Setup flutter_rust_bridge
  - [ ] Install `flutter_rust_bridge_codegen`
  - [ ] Create build script for code generation
  - [ ] Generate initial FFI bindings
  - [ ] Verify FFI bridge works with simple test function

### 1.4 CI/CD Setup
- [ ] Create GitHub Actions workflow
  - [ ] Setup matrix build for macOS, Linux, Windows
  - [ ] Configure Rust toolchain installation
  - [ ] Configure Flutter SDK installation
  - [ ] Add build and test steps

## Phase 2: Core PTY Functionality

### 2.1 Rust Core - Session Management
- [ ] Implement `SessionManager` struct
  - [ ] Add `sessions` HashMap with RwLock
  - [ ] Implement `generate_id()` method
  - [ ] Implement `create_session()` method
  - [ ] Implement `close_session()` method
  - [ ] Implement `get_session()` method
  - [ ] Add global `SESSION_MANAGER` instance

### 2.2 Rust Core - PTY Wrapper
- [ ] Implement `PtySession` struct
  - [ ] Add fields for PTY master, child process, channels
  - [ ] Implement `new()` constructor
  - [ ] Implement `start_io_tasks()` for async I/O
  - [ ] Implement `write()` method
  - [ ] Implement `output_stream()` method
  - [ ] Implement `resize()` method
  - [ ] Implement `close()` method with cleanup

### 2.3 Rust Core - Platform Abstraction
- [ ] Setup portable-pty integration
  - [ ] Create PTY using `native_pty_system()`
  - [ ] Configure PTY size
  - [ ] Spawn child process with PTY
  - [ ] Handle platform-specific differences

### 2.4 Rust Core - I/O Handling
- [ ] Implement async I/O tasks
  - [ ] Create Tokio task for reading PTY output
  - [ ] Implement buffering strategy (4KB buffer)
  - [ ] Send output to Dart via channel
  - [ ] Handle EOF and errors gracefully
  - [ ] Implement backpressure handling

### 2.5 Rust Core - Error Handling
- [ ] Define `PtyError` enum
  - [ ] Add `SessionNotFound` variant
  - [ ] Add `PtyCreationFailed` variant
  - [ ] Add `IoError` variant
  - [ ] Add `SpawnFailed` variant
  - [ ] Implement `From<PtyError>` for DartError
  - [ ] Add error context and messages

## Phase 3: Dart API Layer

### 3.1 Models and Configuration
- [x] Create `PtyConfig` class
  - [x] Add shell, args, workingDirectory fields
  - [x] Add environment variables field
  - [x] Add initial size field
  - [x] Add factory constructors for common configs
  - [x] Add validation logic

- [x] Create `PtySize` class
  - [x] Add rows and cols fields
  - [x] Add validation (min/max values)
  - [x] Add equality and hashCode

- [x] Create `PtySignal` enum
  - [x] Add SIGINT, SIGTERM, SIGKILL, SIGHUP, SIGQUIT
  - [x] Add platform-specific mapping

### 3.2 Exception Types
- [x] Create `PtyException` base class
  - [x] Add message, sessionId, cause fields
  - [x] Override toString()

- [x] Create specific exception types
  - [x] `SessionNotFoundException`
  - [x] `SessionCreationException`
  - [x] `PtyIOException`
  - [x] Add factory constructors from Rust errors

### 3.3 PtyManager Class
- [ ] Implement `PtyManager` singleton
  - [ ] Add private constructor
  - [ ] Add static instance field
  - [ ] Implement `createSession()` method
  - [ ] Implement `closeSession()` method
  - [ ] Implement `getSession()` method
  - [ ] Implement `listSessions()` method
  - [ ] Implement `isSessionRunning()` method
  - [ ] Add session cache/registry

### 3.4 PtySession Class
- [ ] Implement `PtySession` class
  - [ ] Add id, config fields
  - [ ] Implement `write()` method
  - [ ] Implement `writeBytes()` method
  - [ ] Implement `outputStream` getter
  - [ ] Implement `resize()` method
  - [ ] Implement `getSize()` method
  - [ ] Implement `sendSignal()` method
  - [ ] Add `pid` and `exitCode` getters
  - [ ] Implement `waitForExit()` method
  - [ ] Implement `close()` method
  - [ ] Add proper resource cleanup

### 3.5 Stream Handling
- [ ] Setup output stream
  - [ ] Convert Rust stream to Dart Stream
  - [ ] Make stream broadcast
  - [ ] Handle stream errors
  - [ ] Auto-close stream on session end
  - [ ] Add stream transformation utilities

## Phase 4: Testing

### 4.1 Unit Tests (Dart)
- [ ] Test PtyManager
  - [ ] Test createSession with valid config
  - [ ] Test createSession with invalid config
  - [ ] Test closeSession
  - [ ] Test getSession
  - [ ] Test listSessions
  - [ ] Test isSessionRunning

- [ ] Test PtySession
  - [ ] Test write method
  - [ ] Test writeBytes method
  - [ ] Test outputStream
  - [ ] Test resize
  - [ ] Test getSize
  - [ ] Test sendSignal
  - [ ] Test close

- [ ] Test Models
  - [ ] Test PtyConfig validation
  - [ ] Test PtySize validation
  - [ ] Test exception types

### 4.2 Integration Tests
- [ ] Test full workflow
  - [ ] Create session → write → read → close
  - [ ] Test multiple concurrent sessions
  - [ ] Test session lifecycle
  - [ ] Test error scenarios
  - [ ] Test resource cleanup

- [ ] Test platform-specific behavior
  - [ ] Test on macOS
  - [ ] Test on Linux
  - [ ] Test on Windows
  - [ ] Verify signal handling per platform

### 4.3 Property-Based Tests
- [ ] Implement correctness properties
  - [ ] Property 1: Session creation returns valid ID
  - [ ] Property 2: Session usable after creation
  - [ ] Property 3: Session cleanup is complete
  - [ ] Property 4: Close is idempotent
  - [ ] Property 5: Write preserves data integrity
  - [ ] Property 6: Output stream delivers all data
  - [ ] Property 7: Resize updates terminal size
  - [ ] Property 8: Low latency I/O operations
  - [ ] Property 9: Error handling doesn't crash

### 4.4 Performance Tests
- [ ] Benchmark I/O latency
  - [ ] Measure write latency
  - [ ] Measure read latency
  - [ ] Measure round-trip latency
  - [ ] Verify < 10ms requirement

- [ ] Benchmark throughput
  - [ ] Test high-volume output
  - [ ] Verify > 10 MB/s requirement
  - [ ] Test with multiple sessions

- [ ] Benchmark resource usage
  - [ ] Measure memory per session
  - [ ] Measure CPU usage
  - [ ] Test for memory leaks

## Phase 5: Documentation and Examples

### 5.1 API Documentation
- [ ] Document PtyManager
  - [ ] Add class-level documentation
  - [ ] Document all public methods
  - [ ] Add usage examples
  - [ ] Document exceptions

- [ ] Document PtySession
  - [ ] Add class-level documentation
  - [ ] Document all public methods
  - [ ] Add usage examples
  - [ ] Document lifecycle

- [ ] Document Models
  - [ ] Document PtyConfig
  - [ ] Document PtySize
  - [ ] Document PtySignal
  - [ ] Add examples for each

### 5.2 Example Application
- [ ] Create basic terminal example
  - [ ] Create Flutter UI with terminal widget
  - [ ] Integrate PtyManager
  - [ ] Display output in real-time
  - [ ] Handle user input
  - [ ] Add resize handling
  - [ ] Add session management UI

- [ ] Create advanced examples
  - [ ] Multiple tabs example
  - [ ] Custom shell example
  - [ ] Signal handling example
  - [ ] Error handling example

### 5.3 README and Guides
- [ ] Write comprehensive README
  - [ ] Add project overview
  - [ ] Add installation instructions
  - [ ] Add quick start guide
  - [ ] Add API overview
  - [ ] Add platform notes
  - [ ] Add troubleshooting section

- [ ] Create usage guides
  - [ ] Basic usage guide
  - [ ] Advanced features guide
  - [ ] Platform-specific guide
  - [ ] Performance tuning guide

## Phase 6: Polish and Release

### 6.1 Code Quality
- [ ] Run dart analyze and fix all issues
- [ ] Run cargo clippy and fix all warnings
- [ ] Format code (dart format, cargo fmt)
- [ ] Add missing documentation
- [ ] Review and refactor complex code

### 6.2 Performance Optimization
- [ ] Profile and optimize hot paths
- [ ] Optimize buffer sizes
- [ ] Reduce FFI overhead
- [ ] Optimize memory allocations
- [ ] Add caching where appropriate

### 6.3 Security Review
- [ ] Review input validation
- [ ] Review resource limits
- [ ] Review privilege management
- [ ] Test for common vulnerabilities
- [ ] Add security documentation

### 6.4 Platform Testing
- [ ] Test on macOS (Intel and Apple Silicon)
- [ ] Test on Linux (Ubuntu, Fedora, Arch)
- [ ] Test on Windows (10, 11)
- [ ] Fix platform-specific issues
- [ ] Document platform limitations

### 6.5 Release Preparation
- [ ] Create CHANGELOG.md
- [ ] Update version numbers
- [ ] Create release notes
- [ ] Prepare pub.dev package
- [ ] Create GitHub release
- [ ] Publish to pub.dev

## Phase 7: Future Enhancements (Optional)

### 7.1 Terminal Emulation
- [ ] Research VT100/xterm protocols
- [ ] Implement basic terminal emulation
- [ ] Add ANSI color support
- [ ] Add cursor control
- [ ] Add screen buffer management

### 7.2 Session Persistence
- [ ] Design persistence format
- [ ] Implement session serialization
- [ ] Implement session restoration
- [ ] Add migration support
- [ ] Test persistence across restarts

### 7.3 Remote PTY Support
- [ ] Design SSH integration
- [ ] Implement SSH client
- [ ] Add authentication support
- [ ] Test with remote servers
- [ ] Document remote usage

### 7.4 Advanced Features
- [ ] Terminal recording/playback
- [ ] Session sharing
- [ ] Custom terminal protocols
- [ ] Performance monitoring
- [ ] Advanced debugging tools

## Notes

### Priority Levels
- **P0 (Critical):** Must have for v1.0
- **P1 (High):** Should have for v1.0
- **P2 (Medium):** Nice to have for v1.0
- **P3 (Low):** Future versions

### Task Dependencies
- Phase 1 must complete before Phase 2
- Phase 2 must complete before Phase 3
- Phase 3 must complete before Phase 4
- Phases 5-6 can overlap with Phase 4
- Phase 7 is independent (future work)

### Estimated Timeline
- Phase 1: 1 week
- Phase 2: 2-3 weeks
- Phase 3: 2 weeks
- Phase 4: 2 weeks
- Phase 5: 1 week
- Phase 6: 1 week
- **Total: 9-10 weeks for v1.0**

### Success Criteria
- ✅ All P0 and P1 tasks completed
- ✅ All tests passing
- ✅ Documentation complete
- ✅ Performance requirements met
- ✅ Works on all target platforms
- ✅ Ready for pub.dev release
