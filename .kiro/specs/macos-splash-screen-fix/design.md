# macOS Splash Screen Fix - Bugfix Design

## Overview

The macOS app displays a black screen during launch instead of the configured splash screen. Despite having the `native_splash_screen_macos` plugin properly configured with splash screen assets in `Assets.xcassets`, the splash window is not appearing. The issue stems from the timing and lifecycle of the splash screen initialization in `AppDelegate.swift` - the splash screen is being shown too late in the application lifecycle, after the main Flutter window has already been created and displayed. The fix requires moving the splash screen initialization to an earlier point in the app lifecycle and ensuring proper coordination between the splash window and the main Flutter window.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug - when the macOS app launches and the splash screen should display but doesn't
- **Property (P)**: The desired behavior when the app launches - a splash window with the configured image should appear immediately before the main window
- **Preservation**: Existing window background color, build configuration handling, and app termination behavior that must remain unchanged
- **NativeSplashScreen**: The plugin class from `native_splash_screen_macos` that manages splash window display
- **SimpleSplashConfig**: Configuration provider in `AppDelegate.swift` that specifies splash window dimensions, image, and animation settings
- **applicationWillFinishLaunching**: Early app lifecycle method called before the app is fully initialized
- **applicationDidFinishLaunching**: Later app lifecycle method called after the app finishes launching and the main window is created
- **mainFlutterWindow**: The primary NSWindow instance that displays the Flutter UI

## Bug Details

### Bug Condition

The bug manifests when the macOS app is launched and the system should display a splash screen but instead shows a black window. The `NativeSplashScreen.show()` method is being called in `AppDelegate.swift`, but the splash window is either not being created, not being displayed, or being immediately hidden by the main Flutter window.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type AppLaunchEvent
  OUTPUT: boolean
  
  RETURN input.platform == "macOS"
         AND input.launchPhase IN ["applicationWillFinishLaunching", "applicationDidFinishLaunching"]
         AND splashScreenConfigured(input.assets)
         AND NOT splashWindowVisible()
END FUNCTION
```

### Examples

- User launches the app from Finder → sees black screen for 1-2 seconds → main UI appears (splash screen never shown)
- User launches the app in Debug mode → black screen appears → main UI loads (splash_screen_debug.png never displayed)
- User launches the app in Release mode → black screen appears → main UI loads (splash_screen_release.png never displayed)
- Developer runs `flutter run -d macos` → black screen during initialization → Flutter UI renders (expected splash window with 500x300 dimensions never appears)

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Main Flutter window must continue to use the dark background color (#1E1E1E) as configured in both `AppDelegate.swift` and `MainFlutterWindow.swift`
- Build configuration-based image selection (Debug/Profile/Release) must continue to work with the appropriate `splash_screen_*.png` files
- App termination behavior when the last window closes must remain unchanged (`applicationShouldTerminateAfterLastWindowClosed` returns true)

**Scope:**
All behaviors that do NOT involve the initial splash screen display should be completely unaffected by this fix. This includes:
- Main window initialization and background color
- Flutter engine startup and rendering
- Window close and app termination handling
- Build configuration handling for different environments

## Hypothesized Root Cause

Based on the bug description and code analysis, the most likely issues are:

1. **Timing Issue - Splash Called Too Late**: The splash screen is being shown in `applicationWillFinishLaunching` or `applicationDidFinishLaunching`, but by this time the main Flutter window may have already been created and displayed, causing the splash to be hidden behind it or never shown at all.

2. **Window Ordering Issue**: Even if the splash window is created, it may not be properly ordered in front of the main window, causing it to be hidden immediately.

3. **Missing Window Level Configuration**: The splash window may need explicit window level settings to ensure it appears above other windows during launch.

4. **Plugin Lifecycle Mismatch**: The `native_splash_screen_macos` plugin may expect to be initialized before the Flutter engine starts, but the current implementation initializes it after the app delegate lifecycle has already progressed too far.

5. **Main Window Early Creation**: The `MainFlutterWindow` is created and displayed before the splash screen has a chance to show, causing the black background of the main window to be visible instead of the splash.

## Correctness Properties

Property 1: Bug Condition - Splash Screen Displays on Launch

_For any_ app launch event where the macOS app is starting and splash screen assets are configured, the fixed AppDelegate SHALL display the splash window with the configured image (from Assets.xcassets based on build configuration) immediately before the main Flutter window appears, with dimensions 500x300 and proper window ordering.

**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Preservation - Existing Window and Lifecycle Behavior

_For any_ app behavior that does NOT involve the initial splash screen display (main window background color, build configuration handling, app termination), the fixed code SHALL produce exactly the same behavior as the original code, preserving the #1E1E1E background color, build-specific image selection, and termination-on-close behavior.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `macos/Runner/AppDelegate.swift`

**Function**: `AppDelegate` class lifecycle methods

**Specific Changes**:
1. **Move Splash Initialization Earlier**: Initialize the splash screen configuration before `applicationWillFinishLaunching` is called, possibly in the class initializer or by using a different lifecycle hook.

2. **Ensure Splash Shows Before Main Window**: Coordinate the splash screen display with the main window creation to ensure the splash appears first and remains visible until the Flutter engine is ready.

3. **Add Window Ordering**: Explicitly set the splash window level to ensure it appears in front during launch (e.g., using `.floating` or `.modalPanel` window level).

4. **Add Splash Dismissal Logic**: Implement proper logic to dismiss the splash screen after the Flutter engine has finished initializing and the main UI is ready to display.

5. **Remove Redundant Splash Calls**: The current code calls `NativeSplashScreen.show()` in both `applicationWillFinishLaunching` and `applicationDidFinishLaunching` with a flag check - this should be simplified to a single, properly-timed call.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Build and run the macOS app in different configurations (Debug, Profile, Release) and observe the launch behavior. Document what appears on screen during the first 2-3 seconds of launch. Run these observations on the UNFIXED code to confirm the black screen issue and understand timing.

**Test Cases**:
1. **Debug Launch Test**: Launch app in Debug mode and observe if splash_screen_debug.png appears (will fail on unfixed code - black screen shown)
2. **Release Launch Test**: Launch app in Release mode and observe if splash_screen_release.png appears (will fail on unfixed code - black screen shown)
3. **Window Ordering Test**: Add logging to track when splash window and main window are created/shown (will reveal timing issue on unfixed code)
4. **Asset Loading Test**: Verify that splash screen images exist in Assets.xcassets and can be loaded (may pass - assets are present)

**Expected Counterexamples**:
- Black screen appears during launch instead of splash screen image
- Possible causes: splash window created too late, main window appears first, window ordering incorrect, splash window not properly displayed

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := launchApp_fixed(input)
  ASSERT splashWindowVisible(result)
  ASSERT splashWindowContainsCorrectImage(result, input.buildConfiguration)
  ASSERT splashWindowDimensions(result) == (500, 300)
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT appBehavior_original(input) = appBehavior_fixed(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for main window display, app termination, and build configuration handling, then write property-based tests capturing that behavior.

**Test Cases**:
1. **Main Window Background Preservation**: Observe that main window has #1E1E1E background on unfixed code, verify this continues after fix
2. **Build Configuration Preservation**: Observe that Debug/Profile/Release builds use correct images on unfixed code, verify this continues after fix
3. **App Termination Preservation**: Observe that app exits when last window closes on unfixed code, verify this continues after fix
4. **Window Initialization Preservation**: Observe main window initialization sequence on unfixed code, verify this continues after fix

### Unit Tests

- Test that splash screen configuration is properly initialized with correct dimensions (500x300)
- Test that correct image filename is selected based on build configuration (Debug/Profile/Release)
- Test that splash window is created before main window during launch
- Test that main window background color remains #1E1E1E after fix

### Property-Based Tests

- Generate random launch sequences and verify splash screen always appears before main UI
- Generate random build configurations and verify correct splash image is always selected
- Test that window background colors remain consistent across many launch scenarios

### Integration Tests

- Test full app launch flow: splash appears → Flutter initializes → splash dismisses → main UI shows
- Test launching in different build modes (Debug, Profile, Release) and verify correct splash images
- Test that visual splash window with logo appears immediately when app icon is clicked
- Test that transition from splash to main UI is smooth without flashing or black screens
