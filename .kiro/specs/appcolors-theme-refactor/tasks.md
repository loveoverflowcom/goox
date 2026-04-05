# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Widget Color Access via AppColors
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate widgets không respond to theme changes
  - **Scoped PBT Approach**: Scope property to concrete failing cases - widgets using AppColors directly (StatusBarWidget, FileExplorerWidget)
  - Test that widgets using `AppColors.xxx` directly do NOT update colors when theme changes
  - Test implementation details from Bug Condition in design: `isBugCondition(codeLocation)` where `codeLocation.containsReference("AppColors.")` AND `codeLocation.isInWidgetFile`
  - The test assertions should match Expected Behavior Properties: widgets SHALL retrieve colors from `Theme.of(context).colorScheme` or custom ThemeExtension
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves widgets don't respond to theme changes)
  - Document counterexamples found: specific widgets và color properties that don't update on theme switch
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Visual Appearance and Non-Widget Code
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-buggy inputs (theme definition files, non-widget code)
  - Observe actual color values displayed in dark mode and light mode on unfixed code
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Test that AppColors usage in theme definition files (`app_theme.dart`) remains unchanged
  - Test that visual appearance (actual color values displayed) is identical before and after fix
  - Test that widget layouts, spacing, structure remain unchanged
  - Property-based testing generates many test cases for stronger guarantees across different theme states
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 3. Fix for AppColors theme refactor

  - [x] 3.1 Create EditorThemeExtension
    - Create new file `packages/goox_ui/lib/src/theme/editor_theme_extension.dart`
    - Define EditorThemeExtension class extending ThemeExtension<EditorThemeExtension>
    - Add properties: activityBarBackground, sidebarBackground, editorBackground, tabBarBackground, statusBarBackground, textColor, textColorDimmed, hoverColor, borderColor, selectedItemColor, modifiedIndicator
    - Implement copyWith() method
    - Implement lerp() method for theme transitions
    - Create EditorThemeExtension.dark() factory mapping AppColors dark theme values
    - Create EditorThemeExtension.light() factory mapping AppColors light theme values
    - _Bug_Condition: isBugCondition(codeLocation) where codeLocation.isInWidgetFile AND codeLocation.containsReference("AppColors.") AND NOT codeLocation.usesThemeOfContext_
    - _Expected_Behavior: Widget code SHALL retrieve colors from Theme.of(context).colorScheme or custom ThemeExtension_
    - _Preservation: Visual appearance (same color values), theme definition AppColors usage, non-widget code unchanged_
    - _Requirements: 2.1, 2.3, 3.1, 3.2_

  - [x] 3.2 Add EditorThemeExtension to AppTheme
    - Update `packages/goox_ui/lib/src/theme/app_theme.dart`
    - Import EditorThemeExtension
    - Add `extensions: [EditorThemeExtension.dark()]` to AppTheme.dark
    - Add `extensions: [EditorThemeExtension.light()]` to AppTheme.light
    - Keep existing AppColors usage in theme definition unchanged
    - _Bug_Condition: isBugCondition(codeLocation) where widgets cannot access editor-specific colors from theme_
    - _Expected_Behavior: Widgets SHALL access editor-specific colors via Theme.of(context).extension<EditorThemeExtension>()_
    - _Preservation: Theme definition structure and AppColors usage unchanged_
    - _Requirements: 2.1, 2.3, 3.4_

  - [x] 3.3 Refactor StatusBarWidget
    - Update `lib/features/status_bar/presentation/widgets/status_bar_widget.dart`
    - Replace `color: AppColors.statusBarBackground` with `color: Theme.of(context).extension<EditorThemeExtension>()!.statusBarBackground`
    - Replace `color: Colors.white` in text style with `color: Theme.of(context).colorScheme.onPrimary`
    - _Bug_Condition: isBugCondition(statusBarWidget) where widget uses AppColors.statusBarBackground directly_
    - _Expected_Behavior: StatusBarWidget SHALL retrieve colors from Theme.of(context)_
    - _Preservation: Visual appearance (same color values displayed) unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3_

  - [x] 3.4 Refactor FileExplorerWidget
    - Update `lib/features/file_explorer/presentation/widgets/file_explorer_widget.dart`
    - Replace `color: AppColors.errorColor` with `color: Theme.of(context).colorScheme.error`
    - Replace `color: AppColors.textColorDimmed` with `color: Theme.of(context).extension<EditorThemeExtension>()!.textColorDimmed`
    - Replace `color: AppColors.textColor` with `color: Theme.of(context).extension<EditorThemeExtension>()!.textColor`
    - Replace `backgroundColor: AppColors.statusBarBackground` with `backgroundColor: Theme.of(context).extension<EditorThemeExtension>()!.statusBarBackground`
    - Replace `hoverColor: AppColors.hoverColor` with `hoverColor: Theme.of(context).extension<EditorThemeExtension>()!.hoverColor`
    - Replace `color: isSelected ? AppColors.selectedItemColor : null` with `color: isSelected ? Theme.of(context).extension<EditorThemeExtension>()!.selectedItemColor : null`
    - Replace icon `color: AppColors.textColor` with `color: Theme.of(context).extension<EditorThemeExtension>()!.textColor`
    - _Bug_Condition: isBugCondition(fileExplorerWidget) where widget uses AppColors directly for multiple color properties_
    - _Expected_Behavior: FileExplorerWidget SHALL retrieve all colors from Theme.of(context)_
    - _Preservation: Visual appearance, layout, hover effects unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3_

  - [x] 3.5 Refactor TerminalPanelWidget
    - Update `lib/features/terminal/presentation/widgets/terminal_panel_widget.dart`
    - Replace all AppColors references with Theme.of(context) access
    - Use Theme.of(context).colorScheme for standard Material colors
    - Use Theme.of(context).extension<EditorThemeExtension>() for editor-specific colors
    - _Bug_Condition: isBugCondition(terminalPanelWidget) where widget uses AppColors directly_
    - _Expected_Behavior: TerminalPanelWidget SHALL retrieve colors from Theme.of(context)_
    - _Preservation: Visual appearance unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3_

  - [x] 3.6 Refactor EditorLayoutViews
    - Update `lib/features/editor_layout/presentation/widgets/editor_layout_views.dart`
    - Replace all AppColors references with Theme.of(context) access
    - Use Theme.of(context).colorScheme for standard Material colors
    - Use Theme.of(context).extension<EditorThemeExtension>() for editor-specific colors
    - _Bug_Condition: isBugCondition(editorLayoutViews) where widget uses AppColors directly_
    - _Expected_Behavior: EditorLayoutViews SHALL retrieve colors from Theme.of(context)_
    - _Preservation: Visual appearance and layout unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3_

  - [x] 3.7 Refactor TextEditorWidget
    - Update `lib/features/editor_content/presentation/widgets/text_editor_widget.dart`
    - Replace all AppColors references with Theme.of(context) access
    - Use Theme.of(context).colorScheme for standard Material colors
    - Use Theme.of(context).extension<EditorThemeExtension>() for editor-specific colors
    - _Bug_Condition: isBugCondition(textEditorWidget) where widget uses AppColors directly_
    - _Expected_Behavior: TextEditorWidget SHALL retrieve colors from Theme.of(context)_
    - _Preservation: Visual appearance unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3_

  - [x] 3.8 Refactor GooxNavigationRail
    - Update `packages/goox_ui/lib/src/widgets/goox_navigation_rail.dart`
    - Replace all AppColors references with Theme.of(context) access
    - Use Theme.of(context).colorScheme for standard Material colors
    - Use Theme.of(context).extension<EditorThemeExtension>() for editor-specific colors
    - _Bug_Condition: isBugCondition(gooxNavigationRail) where widget uses AppColors directly_
    - _Expected_Behavior: GooxNavigationRail SHALL retrieve colors from Theme.of(context)_
    - _Preservation: Visual appearance unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3_

  - [x] 3.9 Verify ThemeSelectorWidget unchanged
    - Review `lib/features/theme/presentation/widgets/theme_selector_widget.dart`
    - Confirm widget already uses Theme.of(context).colorScheme correctly
    - No changes needed - this is expected behavior
    - _Preservation: ThemeSelectorWidget already correct, no changes_
    - _Requirements: 3.3, 3.4_

  - [x] 3.10 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Widget Color Access via Theme
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms widgets now respond to theme changes
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms widgets now use Theme.of(context))
    - Verify widgets update colors when theme switches
    - Verify no direct AppColors references in widget color access
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 3.11 Verify preservation tests still pass
    - **Property 2: Preservation** - Visual Appearance and Non-Widget Code
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Verify visual appearance identical (same color values displayed)
    - Verify theme definition AppColors usage unchanged
    - Verify widget layouts unchanged
    - Confirm all tests still pass after fix (no regressions)

- [x] 4. Checkpoint - Ensure all tests pass
  - Run all unit tests for EditorThemeExtension
  - Run all widget tests verifying Theme.of(context) usage
  - Run all preservation tests verifying visual appearance unchanged
  - Run integration tests for theme switching
  - Ensure all tests pass, ask the user if questions arise
