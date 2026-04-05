# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Splash Screen Displays on Launch
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test that when the macOS app launches with splash screen assets configured, a splash window with the configured image appears immediately before the main Flutter window
  - The test assertions should verify: splash window is visible, contains correct image based on build configuration, has dimensions 500x300, and appears before main window
  - Run test on UNFIXED code in Debug, Profile, and Release configurations
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found: black screen appears instead of splash screen, splash window not visible, or main window appears first
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Existing Window and Lifecycle Behavior
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-splash-screen behaviors
  - Observe: Main Flutter window uses #1E1E1E background color
  - Observe: Build configuration correctly selects splash_screen_debug.png, splash_screen_profile.png, or splash_screen_release.png
  - Observe: App terminates when last window closes (applicationShouldTerminateAfterLastWindowClosed returns true)
  - Observe: Main window initialization sequence and timing
  - Write property-based tests capturing observed behavior patterns: for all app behaviors NOT involving initial splash display, behavior remains unchanged
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 3. Fix for macOS splash screen not displaying during app launch

  - [x] 3.1 Implement the fix in AppDelegate.swift
    - Move splash screen initialization to an earlier point in the app lifecycle (before main window creation)
    - Ensure splash window is created and displayed before the main Flutter window appears
    - Add explicit window ordering to ensure splash window appears in front during launch
    - Implement proper splash dismissal logic after Flutter engine initialization
    - Remove redundant splash screen calls and simplify to a single properly-timed call
    - Coordinate splash screen display with main window creation timing
    - _Bug_Condition: isBugCondition(input) where input.platform == "macOS" AND input.launchPhase IN ["applicationWillFinishLaunching", "applicationDidFinishLaunching"] AND splashScreenConfigured(input.assets) AND NOT splashWindowVisible()_
    - _Expected_Behavior: splashWindowVisible(result) AND splashWindowContainsCorrectImage(result, input.buildConfiguration) AND splashWindowDimensions(result) == (500, 300)_
    - _Preservation: Main window background color (#1E1E1E), build configuration handling, app termination behavior, and window initialization sequence must remain unchanged_
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4_

  - [x] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Splash Screen Displays on Launch
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - Verify splash window appears with correct image, dimensions, and timing across Debug, Profile, and Release builds
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Existing Window and Lifecycle Behavior
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm main window background color, build configuration handling, app termination, and window initialization all still work correctly

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
