# PTY Service Integration Testing Guide

## Overview

The PTY (Pseudo-Terminal) service integration tests verify real shell process spawning and I/O operations. Due to the nature of the `flutter_pty` package, these tests cannot run in standard unit test mode.

## Why Tests Are Skipped

The `flutter_pty` package uses FFI (Foreign Function Interface) to interact with native platform code:
- **Linux/macOS**: Uses POSIX PTY APIs (`posix_openpt`, `grantpt`, `unlockpt`)
- **Windows**: Uses Windows Pseudo Console API (`CreatePseudoConsole`)

These native libraries cannot be loaded in the Dart VM test environment (`flutter test`), which is why the integration tests are skipped.

## Test Coverage

The integration test file (`pty_service_integration_test.dart`) documents the expected behavior for:

### 1. createPTY()
- ✓ Spawns real shell process
- ✓ Creates PTY with correct working directory

### 2. write()
- ✓ Sends input to shell
- ✓ Handles multiple write operations

### 3. stdout stream
- ✓ Receives output from shell
- ✓ Streams output continuously

### 4. terminate()
- ✓ Kills shell process
- ✓ Force terminate kills immediately

### 5. Graceful termination
- ✓ Waits up to 2 seconds for graceful termination
- ✓ Force kills after timeout if process does not exit gracefully

## Manual Testing Procedures

### Test 1: Spawn Real Shell Process

**Steps:**
1. Run the app: `flutter run`
2. Create a new terminal instance
3. Verify a shell prompt appears
4. Check that output is displayed

**Expected Result:**
- Terminal shows shell prompt (e.g., `$`, `>`, `PS>`)
- Process is running with valid PID

---

### Test 2: Working Directory

**Steps:**
1. Create a terminal
2. Type `pwd` (Unix) or `cd` (Windows) and press Enter
3. Observe the output

**Expected Result:**
- Output shows the correct working directory (project root)

---

### Test 3: Send Input to Shell

**Steps:**
1. Create a terminal
2. Type: `echo HELLO_PTY_TEST`
3. Press Enter

**Expected Result:**
- Output displays: `HELLO_PTY_TEST`

---

### Test 4: Multiple Write Operations

**Steps:**
1. Create a terminal
2. Execute these commands in sequence:
   ```bash
   echo TEST_ONE
   echo TEST_TWO
   echo TEST_THREE
   ```

**Expected Result:**
- All three outputs appear in order
- No commands are lost or mixed

---

### Test 5: Continuous Output Stream

**Unix/Linux/macOS:**
```bash
for i in {1..5}; do echo "Line $i"; done
```

**Windows:**
```powershell
for ($i=1; $i -le 5; $i++) { Write-Host "Line $i" }
```

**Expected Result:**
- All 5 lines appear in sequence
- Output streams continuously without blocking

---

### Test 6: Terminate Process

**Steps:**
1. Create a terminal
2. Click the close button (X) on the terminal tab
3. Check system process list

**Expected Result:**
- Terminal closes without errors
- Shell process is no longer running

---

### Test 7: Force Terminate

**Steps:**
1. Create a terminal
2. Start a long-running command:
   - Unix: `sleep 60`
   - Windows: `Start-Sleep -Seconds 60`
3. Immediately close the terminal

**Expected Result:**
- Terminal closes quickly (< 1 second)
- Process is force-killed

---

### Test 8: Graceful Termination

**Steps:**
1. Create a terminal
2. Run a quick command: `echo test`
3. Close the terminal

**Expected Result:**
- Terminal closes gracefully
- Completion time < 2 seconds

---

### Test 9: Timeout and Force Kill (Unix only)

**Steps:**
1. Create a terminal
2. Run: `trap "" TERM; sleep 10 &`
   (Creates a process that ignores SIGTERM)
3. Close the terminal

**Expected Result:**
- Terminal waits ~2 seconds for graceful exit
- Then force-kills the process
- Total time: 2-3 seconds

---

## Platform-Specific Behavior

### Linux
- Default shell: `bash`
- Fallback: `sh`
- Termination: SIGTERM → wait 2s → SIGKILL

### macOS
- Default shell: `zsh`
- Fallback: `bash` → `sh`
- Termination: SIGTERM → wait 2s → SIGKILL

### Windows
- Default shell: `pwsh` (PowerShell Core)
- Fallback: `powershell` → `cmd`
- Termination: Immediate force kill (no SIGTERM equivalent)

## Future Enhancements

### Option 1: Flutter Integration Tests

Create tests using the `integration_test` package that run on actual devices/emulators:

```dart
// integration_test/pty_service_test.dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('PTY service creates real shell', (tester) async {
    // Test with real native code
  });
}
```

Run with: `flutter test integration_test/pty_service_test.dart`

### Option 2: Platform-Specific Tests

Create separate test suites for each platform that run in CI/CD:

```yaml
# .github/workflows/test.yml
- name: Run PTY integration tests (Linux)
  run: flutter test integration_test/pty_service_test.dart
  if: runner.os == 'Linux'
```

## Troubleshooting

### Issue: Tests fail with "Failed to load dynamic library"

**Cause:** Running in unit test mode where native libraries aren't available.

**Solution:** Tests are correctly skipped. Verify functionality through manual testing or integration tests.

### Issue: Shell not found

**Cause:** Shell executable not in system PATH.

**Solution:** 
- Linux/macOS: Install bash/zsh
- Windows: Install PowerShell Core or use built-in PowerShell

### Issue: PTY creation fails

**Cause:** Insufficient permissions or unsupported platform.

**Solution:**
- Check file permissions
- Verify platform is supported (Linux, macOS, Windows 10+)
- Check flutter_pty package compatibility

## References

- [flutter_pty package](https://pub.dev/packages/flutter_pty)
- [xterm package](https://pub.dev/packages/xterm)
- [PTY Wikipedia](https://en.wikipedia.org/wiki/Pseudoterminal)
- [Windows Pseudo Console](https://docs.microsoft.com/en-us/windows/console/creating-a-pseudoconsole-session)
