# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Terminal View Resize Without PTY Sync
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test that when terminal view resizes, PTY dimensions do NOT automatically update (Bug Condition from design)
  - Create TerminalController with initialSize (e.g., 80x24)
  - Simulate terminal view resize event (e.g., to 120x30)
  - Assert PTY dimensions remain at old size (80x24) - this demonstrates the bug
  - The test assertions should match the Expected Behavior Properties from design (PTY should auto-resize)
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found: "Terminal view resized to 120x30 but PTY remains at 80x24"
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 1.3, 2.1, 2.3_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Non-Resize Operations Behavior
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-buggy inputs (operations that don't involve resize)
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Property-based testing generates many test cases for stronger guarantees
  - Test cases to observe and preserve:
    - Input/output data flow: terminal input → PTY, PTY output → terminal display
    - Status tracking: initializing → running → exited transitions
    - Title parsing: OSC escape sequences update terminal title
    - Error handling: errors trigger status update to "error"
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 3. Fix for terminal resize synchronization

  - [x] 3.1 Add onResize callback in initialize() method
    - After setting up `_terminal.onOutput` callback, add `_terminal.onResize` callback
    - Callback should call `_pty!.resize(height, width)` when terminal view resizes
    - Note parameter order: xterm onResize gives (width, height), but pty.resize takes (rows, cols)
    - Update `_size` property to reflect new dimensions
    - Add null check and status check before calling pty.resize
    - _Bug_Condition: isBugCondition(event) where event.type == "terminal_view_resized" AND terminal.viewWidth != pty.columns_
    - _Expected_Behavior: PTY SHALL be automatically resized to match terminal view dimensions_
    - _Preservation: Input/output flow, status tracking, title parsing, error handling SHALL remain unchanged_
    - _Requirements: 1.1, 1.3, 2.1, 2.3, 3.1, 3.2, 3.3, 3.4_

  - [x] 3.2 Add onResize callback in restart() method
    - Similar to initialize(), add `_terminal.onResize` callback after setting up terminal.onOutput
    - Ensure callback is registered after every restart to maintain auto-resize functionality
    - _Bug_Condition: After restart, terminal view resize should trigger PTY resize_
    - _Expected_Behavior: PTY SHALL be automatically resized after restart_
    - _Preservation: Restart behavior SHALL remain unchanged except for resize handling_
    - _Requirements: 2.3, 3.1, 3.2_

  - [x] 3.3 Add initial size synchronization
    - After creating PTY in initialize(), sync PTY size with terminal view size
    - Check if `_terminal.viewWidth > 0 && _terminal.viewHeight > 0`
    - Call `_pty!.resize(_terminal.viewHeight, _terminal.viewWidth)` to sync
    - Update `_size` property to reflect actual dimensions
    - This ensures PTY and terminal view are synchronized from the start
    - _Bug_Condition: Initial PTY size may not match terminal view size_
    - _Expected_Behavior: PTY SHALL be initialized with terminal view dimensions_
    - _Preservation: Initialization flow SHALL remain unchanged except for size sync_
    - _Requirements: 1.1, 2.1, 3.1_

  - [x] 3.4 Clear onResize callback in dispose()
    - Add `_terminal.onResize = null;` in dispose() method
    - Place after canceling output subscription
    - Ensures proper cleanup of callback references
    - _Preservation: Dispose cleanup SHALL remain unchanged except for callback cleanup_
    - _Requirements: 3.1, 3.2_

  - [x] 3.5 Update resize() method documentation
    - Clarify that resize() is for manual/programmatic resize
    - Note that automatic resize is handled by onResize callback
    - Document the relationship between manual and automatic resize
    - _Preservation: resize() method behavior SHALL remain unchanged_
    - _Requirements: 2.4_

  - [x] 3.6 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Automatic PTY Resize on Terminal View Change
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - Verify that when terminal view resizes, PTY dimensions automatically update
    - _Requirements: 2.1, 2.3, 2.4_

  - [x] 3.7 Verify preservation tests still pass
    - **Property 2: Preservation** - Non-Resize Operations Behavior
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions)
    - Verify input/output flow, status tracking, title parsing, error handling unchanged
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 4. Checkpoint - Ensure all tests pass
  - Run all unit tests for TerminalController
  - Run all property-based tests (bug condition + preservation)
  - Run integration tests if available
  - Verify no regressions in existing functionality
  - Ask user if any questions or issues arise
