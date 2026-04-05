# AppColors Theme Refactor Bugfix Design

## Overview

Widgets trong ứng dụng Goox editor hiện đang sử dụng `AppColors` trực tiếp thay vì truy cập colors thông qua `Theme.of(context)`. Điều này vi phạm best practice của Flutter về theme management và ngăn cản việc thay đổi theme động hoạt động đúng cách. Fix này sẽ refactor tất cả widget usages để sử dụng `Theme.of(context).colorScheme` hoặc custom theme extensions, trong khi vẫn giữ nguyên visual appearance và cho phép `AppColors` được sử dụng trong theme definition files.

## Glossary

- **Bug_Condition (C)**: Widget code truy cập colors thông qua `AppColors.xxx` trực tiếp thay vì `Theme.of(context)`
- **Property (P)**: Widget code phải truy cập colors thông qua `Theme.of(context).colorScheme` hoặc custom theme extension
- **Preservation**: Visual appearance (actual color values), layout, và non-widget AppColors usage phải không thay đổi
- **Theme.of(context)**: Flutter API để truy cập current theme data từ widget context
- **ColorScheme**: Flutter's Material Design color system chứa semantic color roles
- **ThemeExtension**: Flutter mechanism để extend theme với custom properties
- **AppColors**: Static color constants class hiện tại trong `packages/goox_ui/lib/src/colors/app_colors.dart`
- **AppTheme**: Theme definition class trong `packages/goox_ui/lib/src/theme/app_theme.dart`

## Bug Details

### Bug Condition

Bug xảy ra khi widget code truy cập colors trực tiếp từ `AppColors` class thay vì thông qua theme system. Điều này làm cho widgets không respond to theme changes và vi phạm Flutter best practices.

**Formal Specification:**
```
FUNCTION isBugCondition(codeLocation)
  INPUT: codeLocation of type WidgetCodeLocation
  OUTPUT: boolean
  
  RETURN codeLocation.isInWidgetFile
         AND codeLocation.containsReference("AppColors.")
         AND NOT codeLocation.isInThemeDefinitionFile
         AND NOT codeLocation.usesThemeOfContext
END FUNCTION
```

### Examples

- **Status Bar Widget**: `color: AppColors.statusBarBackground` - widget sử dụng static color thay vì `Theme.of(context).colorScheme.primary`
- **File Explorer Widget**: `color: AppColors.textColor` - icon color hardcoded thay vì `Theme.of(context).colorScheme.onSurface`
- **File Explorer Widget**: `hoverColor: AppColors.hoverColor` - hover effect không respect theme
- **File Explorer Widget**: `color: isSelected ? AppColors.selectedItemColor : null` - selection color không theme-aware
- **Theme Selector Widget**: Đã sử dụng `Theme.of(context).colorScheme` correctly - đây là expected behavior
- **Tab Bar Widget**: Đã sử dụng `colorScheme.surface`, `colorScheme.onSurface` - đây là expected behavior

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Visual appearance phải giống hệt như hiện tại (same color values được hiển thị)
- Dark mode phải hiển thị exact same dark colors như trước
- Light mode phải hiển thị exact same light colors như trước
- Widget layout, spacing, structure phải không thay đổi
- AppColors usage trong theme definition files (`app_theme.dart`) phải được giữ nguyên
- Non-widget code có thể tiếp tục sử dụng AppColors nếu appropriate

**Scope:**
Tất cả code locations mà KHÔNG phải là widget color access (theme definitions, constants, non-UI logic) phải hoàn toàn không bị ảnh hưởng bởi fix này. Bao gồm:
- Theme definition trong `AppTheme.dark` và `AppTheme.light`
- AppColors class definition itself
- Any utility functions hoặc non-widget code sử dụng AppColors

## Hypothesized Root Cause

Dựa trên bug description và code analysis, các nguyên nhân chính là:

1. **Legacy Code Pattern**: Widgets được viết trước khi theme system được implement đầy đủ
   - AppColors được tạo như static constants trước
   - Widgets reference trực tiếp AppColors vì nó đơn giản hơn
   - Theme system được add sau nhưng existing widgets không được refactor

2. **Incomplete Theme Mapping**: ColorScheme không map đầy đủ tất cả AppColors
   - Flutter's ColorScheme có limited semantic colors (primary, surface, onSurface, etc.)
   - AppColors có nhiều specific colors (activityBarBackground, sidebarBackground, editorBackground, etc.)
   - Cần custom ThemeExtension để map các editor-specific colors

3. **Inconsistent Usage Pattern**: Một số widgets đã sử dụng Theme.of(context) correctly (TabBarWidget, ThemeSelectorWidget) nhưng others vẫn dùng AppColors
   - Cho thấy không có clear guideline hoặc enforcement
   - Code review không catch được pattern này

4. **Missing Theme Extension**: Không có custom ThemeExtension để expose editor-specific colors
   - Widgets cần colors như `activityBarBackground`, `sidebarBackground` không có trong standard ColorScheme
   - Phải tạo custom extension để bridge AppColors và Theme system

## Correctness Properties

Property 1: Bug Condition - Widget Color Access via Theme

_For any_ widget code location where colors are accessed (isBugCondition returns true), the refactored code SHALL retrieve colors from `Theme.of(context).colorScheme` for standard Material colors or from a custom ThemeExtension for editor-specific colors, ensuring theme-aware color access.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4**

Property 2: Preservation - Visual Appearance and Non-Widget Code

_For any_ code location that is NOT a widget color access (isBugCondition returns false), the refactored code SHALL produce exactly the same behavior as the original code, preserving visual appearance (same color values displayed), theme definition usage of AppColors, and all non-widget code patterns.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

Giả sử root cause analysis đúng, chúng ta cần:

**File 1**: `packages/goox_ui/lib/src/theme/editor_theme_extension.dart` (NEW FILE)

**Purpose**: Create custom ThemeExtension để map editor-specific colors

**Specific Changes**:
1. **Create EditorThemeExtension class**: Extend ThemeExtension<EditorThemeExtension>
   - Define properties cho editor-specific colors: `activityBarBackground`, `sidebarBackground`, `editorBackground`, `tabBarBackground`, `statusBarBackground`, `textColor`, `textColorDimmed`, `hoverColor`, `borderColor`, `selectedItemColor`, `modifiedIndicator`
   - Implement `copyWith()` method
   - Implement `lerp()` method for theme transitions
   
2. **Create factory constructors**: `EditorThemeExtension.dark()` và `EditorThemeExtension.light()`
   - Map AppColors dark theme values to dark extension
   - Map AppColors light theme values to light extension

**File 2**: `packages/goox_ui/lib/src/theme/app_theme.dart`

**Purpose**: Add EditorThemeExtension to ThemeData

**Specific Changes**:
1. **Import EditorThemeExtension**: Add import statement
2. **Add extension to dark theme**: `extensions: [EditorThemeExtension.dark()]`
3. **Add extension to light theme**: `extensions: [EditorThemeExtension.light()]`
4. **Keep AppColors usage**: Không thay đổi existing AppColors references trong theme definition

**File 3**: `lib/features/status_bar/presentation/widgets/status_bar_widget.dart`

**Purpose**: Refactor to use Theme.of(context)

**Specific Changes**:
1. **Replace `color: AppColors.statusBarBackground`**: 
   - With `color: Theme.of(context).extension<EditorThemeExtension>()!.statusBarBackground`
2. **Replace `color: Colors.white` in text style**:
   - With `color: Theme.of(context).colorScheme.onPrimary`

**File 4**: `lib/features/file_explorer/presentation/widgets/file_explorer_widget.dart`

**Purpose**: Refactor to use Theme.of(context)

**Specific Changes**:
1. **Replace `color: AppColors.errorColor`**: With `color: Theme.of(context).colorScheme.error`
2. **Replace `color: AppColors.textColorDimmed`**: With `color: Theme.of(context).extension<EditorThemeExtension>()!.textColorDimmed`
3. **Replace `color: AppColors.textColor`**: With `color: Theme.of(context).extension<EditorThemeExtension>()!.textColor`
4. **Replace `backgroundColor: AppColors.statusBarBackground`**: With `backgroundColor: Theme.of(context).extension<EditorThemeExtension>()!.statusBarBackground`
5. **Replace `hoverColor: AppColors.hoverColor`**: With `hoverColor: Theme.of(context).extension<EditorThemeExtension>()!.hoverColor`
6. **Replace `color: isSelected ? AppColors.selectedItemColor : null`**: With `color: isSelected ? Theme.of(context).extension<EditorThemeExtension>()!.selectedItemColor : null`
7. **Replace icon `color: AppColors.textColor`**: With `color: Theme.of(context).extension<EditorThemeExtension>()!.textColor`

**File 5**: `lib/features/terminal/presentation/widgets/terminal_panel_widget.dart`

**Purpose**: Refactor to use Theme.of(context)

**Specific Changes**: (Similar pattern - replace AppColors references with Theme.of(context) access)

**File 6**: `lib/features/theme/presentation/widgets/theme_selector_widget.dart`

**Purpose**: Verify already using Theme.of(context) correctly

**Specific Changes**: No changes needed - already correct

**File 7**: `lib/features/editor_layout/presentation/widgets/editor_layout_views.dart`

**Purpose**: Refactor to use Theme.of(context)

**Specific Changes**: (Similar pattern - replace AppColors references with Theme.of(context) access)

**File 8**: `lib/features/editor_content/presentation/widgets/text_editor_widget.dart`

**Purpose**: Refactor to use Theme.of(context)

**Specific Changes**: (Similar pattern - replace AppColors references with Theme.of(context) access)

**File 9**: `packages/goox_ui/lib/src/widgets/goox_navigation_rail.dart`

**Purpose**: Refactor to use Theme.of(context)

**Specific Changes**: (Similar pattern - replace AppColors references with Theme.of(context) access)

## Testing Strategy

### Validation Approach

Testing strategy theo two-phase approach: đầu tiên, surface counterexamples demonstrating bug trên unfixed code (widgets không respond to theme changes), sau đó verify fix works correctly và preserves visual appearance.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples demonstrating bug TRƯỚC KHI implement fix. Confirm hoặc refute root cause analysis. Nếu refute, cần re-hypothesize.

**Test Plan**: Viết tests simulate theme changes và verify widgets có update colors hay không. Run tests trên UNFIXED code để observe failures và understand root cause.

**Test Cases**:
1. **Status Bar Theme Change Test**: Switch theme từ dark to light, verify status bar background color changes (will fail on unfixed code - color stays same)
2. **File Explorer Theme Change Test**: Switch theme, verify text colors và hover colors change (will fail on unfixed code)
3. **Widget Rebuild Test**: Force widget rebuild với different theme, verify colors update (will fail on unfixed code)
4. **Theme Extension Access Test**: Try to access EditorThemeExtension from context (will fail on unfixed code - extension doesn't exist)

**Expected Counterexamples**:
- Widgets không update colors khi theme changes
- AppColors static values được sử dụng regardless of current theme
- Possible causes: direct AppColors reference, missing ThemeExtension, không có theme-aware color access

### Fix Checking

**Goal**: Verify rằng for all widget code locations where bug condition holds, fixed code retrieves colors from Theme.of(context).

**Pseudocode:**
```
FOR ALL codeLocation WHERE isBugCondition(codeLocation) DO
  refactoredCode := applyThemeRefactor(codeLocation)
  ASSERT refactoredCode.usesThemeOfContext
  ASSERT NOT refactoredCode.containsDirectAppColorsReference
END FOR
```

### Preservation Checking

**Goal**: Verify rằng for all inputs where bug condition does NOT hold, fixed code produces same result as original code.

**Pseudocode:**
```
FOR ALL codeLocation WHERE NOT isBugCondition(codeLocation) DO
  ASSERT originalCode(codeLocation) = refactoredCode(codeLocation)
END FOR
```

**Testing Approach**: Property-based testing recommended for preservation checking vì:
- Generates many test cases automatically across different theme states
- Catches edge cases như theme transitions, null themes, etc.
- Provides strong guarantees rằng visual appearance unchanged for all scenarios

**Test Plan**: Observe behavior trên UNFIXED code first cho visual appearance, sau đó write property-based tests capturing exact color values displayed.

**Test Cases**:
1. **Dark Mode Visual Preservation**: Observe dark mode colors trên unfixed code, verify fixed code displays exact same colors
2. **Light Mode Visual Preservation**: Observe light mode colors trên unfixed code, verify fixed code displays exact same colors
3. **Theme Definition Preservation**: Verify AppTheme.dark và AppTheme.light vẫn sử dụng AppColors như trước
4. **Layout Preservation**: Verify widget layouts, spacing, structure không thay đổi

### Unit Tests

- Test EditorThemeExtension.dark() returns correct color values matching AppColors dark theme
- Test EditorThemeExtension.light() returns correct color values matching AppColors light theme
- Test EditorThemeExtension.lerp() correctly interpolates between themes
- Test each refactored widget retrieves colors from Theme.of(context)
- Test widgets với null theme extension (should not crash)

### Property-Based Tests

- Generate random theme switches và verify all widgets update colors correctly
- Generate random widget states và verify colors always come from current theme
- Test theme transitions với lerp values từ 0.0 to 1.0, verify smooth color transitions
- Generate random BuildContext scenarios và verify Theme.of(context) always returns valid theme

### Integration Tests

- Test full app flow switching từ dark to light theme, verify all widgets update
- Test app startup với different initial themes, verify correct colors displayed
- Test system theme changes (AppThemeMode.system), verify app responds correctly
- Test visual regression - capture screenshots trước và sau fix, verify identical appearance
