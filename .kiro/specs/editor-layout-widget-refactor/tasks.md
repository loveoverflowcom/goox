# Implementation Plan: Editor Layout Widget Refactor

## Overview

Refactor `editor_layout_views.dart` by extracting components into separate widgets organized with Dart's `part`/`part of` mechanism. This improves render performance by reducing unnecessary rebuilds and enhances maintainability through clear separation of concerns.

## Tasks

- [x] 1. Create part files structure and setup
  - Create `editor_layout_views_sidebar.dart` with `part of` directive
  - Create `editor_layout_views_resize_handle.dart` with `part of` directive
  - Create `editor_layout_views_editor_area.dart` with `part of` directive
  - Create `editor_layout_views_tab_contents.dart` with `part of` directive
  - Add `part` directives to main `editor_layout_views.dart` file
  - _Requirements: 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_

- [x] 2. Extract and implement _ResizeHandleWidget
  - [x] 2.1 Create _ResizeHandleWidget class in resize_handle part file
    - Implement const constructor accepting `currentWidth` and `theme` parameters
    - Move resize handle logic from `_buildResizeHandle` method
    - Implement horizontal drag gesture handling with ResizeSidebarEvent dispatch
    - Add MouseRegion with resize cursor
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 5.2_

  - [ ]* 2.2 Write widget tests for _ResizeHandleWidget
    - Test drag gesture handling and event dispatch
    - Test cursor change on hover
    - Test visual rendering with different themes
    - _Requirements: 2.1, 2.2, 2.3_

- [x] 3. Extract and implement tab content widgets
  - [x] 3.1 Create _ExplorerTabContent widget
    - Implement const constructor accepting `contentWidth` and `theme`
    - Move Explorer tab builder logic from GooxDestinationTab
    - Include FileExplorerWidget with onFileSelected callback
    - Add "EXPLORER" header with proper styling
    - _Requirements: 4.1, 4.6, 4.7, 4.8, 5.2_

  - [x] 3.2 Create _SearchTabContent widget
    - Implement const constructor accepting `contentWidth` and `theme`
    - Move Search tab builder logic (placeholder content)
    - _Requirements: 4.2, 4.6, 4.7, 4.8_

  - [x] 3.3 Create _SourceControlTabContent widget
    - Implement const constructor accepting `contentWidth` and `theme`
    - Move Source Control tab builder logic (placeholder content)
    - _Requirements: 4.3, 4.6, 4.7, 4.8_

  - [x] 3.4 Create _ExtensionsTabContent widget
    - Implement const constructor accepting `contentWidth` and `theme`
    - Move Extensions tab builder logic (placeholder content)
    - _Requirements: 4.4, 4.6, 4.7, 4.8_

  - [x] 3.5 Create _SettingsTabContent widget
    - Implement const constructor accepting `contentWidth` and `theme`
    - Move Settings tab builder logic with ThemeSelectorWidget
    - Add "SETTINGS" header with proper styling
    - _Requirements: 4.5, 4.6, 4.7, 4.8_

  - [ ]* 3.6 Write widget tests for tab content widgets
    - Test each tab content widget renders correctly
    - Test theme parameter usage
    - Test content width constraints
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 4. Extract and implement _SidebarWidget
  - [x] 4.1 Create _SidebarWidget class in sidebar part file
    - Implement const constructor accepting `width` and `theme` parameters
    - Move sidebar logic from `_buildSidebar` method
    - Calculate contentWidth (width - activityBarWidth)
    - Implement GooxNavigationRail with all destination tabs
    - Wire up tab content widgets as builders
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 5.2_

  - [ ]* 4.2 Write widget tests for _SidebarWidget
    - Test sidebar renders with correct width
    - Test GooxNavigationRail contains all destinations
    - Test tab content widgets are used as builders
    - Test theme parameter usage
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 5. Extract and implement _EditorAreaWidget
  - [x] 5.1 Create _EditorAreaWidget class in editor_area part file
    - Implement const constructor accepting `theme` parameter
    - Move editor area logic from `_buildEditorArea` method
    - Compose TabBarWidget and TextEditorWidget in Column
    - Apply editor background color from theme
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 5.2_

  - [ ]* 5.2 Write widget tests for _EditorAreaWidget
    - Test editor area renders TabBarWidget and TextEditorWidget
    - Test background color from theme
    - Test const constructor optimization
    - _Requirements: 3.1, 3.2, 3.3_

- [x] 6. Checkpoint - Ensure all widgets compile and basic tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Refactor _EditorLayoutView to use extracted widgets
  - [x] 7.1 Optimize theme access in _EditorLayoutView
    - Retrieve EditorThemeExtension once at top of build method
    - Pass theme to _SidebarWidget, _ResizeHandleWidget, and _EditorAreaWidget
    - Remove redundant Theme.of(context) calls
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 7.2 Update _EditorLayoutView build method to use new widgets
    - Replace `_buildSidebar()` call with `_SidebarWidget(width: ..., theme: ...)`
    - Replace `_buildResizeHandle()` call with `_ResizeHandleWidget(currentWidth: ..., theme: ...)`
    - Replace `_buildEditorArea()` call with `_EditorAreaWidget(theme: ...)`
    - Verify BlocBuilder<EditorLayoutBloc> wraps layout correctly
    - _Requirements: 1.2, 2.2, 3.4, 8.1, 8.2_

  - [x] 7.3 Remove old build methods
    - Delete `_buildSidebar` method
    - Delete `_buildResizeHandle` method
    - Delete `_buildEditorArea` method
    - _Requirements: 1.1, 2.1, 3.1_

- [x] 8. Verify all existing functionality preserved
  - [x] 8.1 Test keyboard shortcuts functionality
    - Verify Ctrl+B toggles sidebar
    - Verify Ctrl+` toggles terminal
    - Verify Ctrl+W closes active tab
    - Verify Ctrl+Tab switches to next tab
    - Verify Ctrl+Shift+Tab switches to previous tab
    - _Requirements: 7.1_

  - [x] 8.2 Test interactive functionality
    - Verify sidebar resize by dragging handle works
    - Verify file selection from Explorer opens file
    - Verify tab switching loads correct content
    - Verify modified state syncs between editor and tabs
    - _Requirements: 7.2, 7.3, 7.4, 7.5, 7.6_

  - [ ]* 8.3 Write integration tests for complete layout
    - Test EditorLayoutView with all BLoC providers
    - Test keyboard shortcuts dispatch correct events
    - Test sidebar toggle and resize interactions
    - Test file selection flow end-to-end
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

- [x] 9. Performance verification and optimization
  - [x] 9.1 Verify rebuild isolation
    - Test that sidebar width change only rebuilds _SidebarWidget
    - Test that tab content change only rebuilds active tab widget
    - Test that theme access is optimized (single lookup per build)
    - _Requirements: 8.1, 8.2, 8.3_

  - [x] 9.2 Apply const constructors where possible
    - Verify all extracted widgets use const constructors
    - Add const keywords to widget instantiations where possible
    - _Requirements: 1.5, 2.4, 3.3, 8.4_

  - [ ]* 9.3 Write performance tests
    - Test rebuild count when sidebar resizes
    - Test rebuild count when tab switches
    - Verify no unnecessary rebuilds of _EditorAreaWidget
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [x] 10. Final checkpoint and visual verification
  - Ensure all tests pass, ask the user if questions arise.
  - Verify visual appearance matches original exactly
  - Verify no console errors or warnings
  - _Requirements: 7.7, 7.8_

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- All imports must remain in main `editor_layout_views.dart` file only
- Part files should only contain widget class definitions
- Use const constructors wherever possible for performance
- Theme should be passed as parameter to avoid repeated context lookups
- Maintain 100% functional compatibility with existing behavior
