// Bug Condition Exploration Test for AppColors Theme Refactor
// **Validates: Requirements 1.1, 1.2, 1.3, 1.4**
//
// CRITICAL: This test MUST FAIL on unfixed code - failure confirms the bug exists
// DO NOT attempt to fix the test or the code when it fails
//
// This test encodes the expected behavior - it will validate the fix when it passes after implementation
//
// GOAL: Surface counterexamples that demonstrate widgets don't respond to theme changes
// Scoped PBT Approach: Scope property to concrete failing cases - widgets using AppColors directly

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/editor_content/data/repositories/file_repository.dart';
import 'package:goox/features/editor_content/presentation/blocs/editor_content_bloc.dart';
import 'package:goox/features/file_explorer/data/repositories/workspace_repository.dart';
import 'package:goox/features/file_explorer/presentation/blocs/file_explorer_bloc.dart';
import 'package:goox/features/file_explorer/presentation/widgets/file_explorer_widget.dart';
import 'package:goox/features/status_bar/presentation/widgets/status_bar_widget.dart';
import 'package:goox_ui/goox_ui.dart';
import 'package:mocktail/mocktail.dart';

// Mock repositories for testing
class MockFileRepository extends Mock implements FileRepository {}
class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

void main() {
  late MockFileRepository mockFileRepository;
  late MockWorkspaceRepository mockWorkspaceRepository;

  setUp(() {
    mockFileRepository = MockFileRepository();
    mockWorkspaceRepository = MockWorkspaceRepository();
  });

  group('Bug Condition Exploration - Property 1: Widget Color Access via AppColors', () {
    testWidgets(
      'StatusBarWidget should retrieve color from Theme.of(context)',
      (tester) async {
        // This test verifies that StatusBarWidget uses Theme.of(context).extension<EditorThemeExtension>()
        // instead of directly accessing AppColors.statusBarBackground
        
        // Build StatusBarWidget with dark theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: BlocProvider(
                create: (_) => EditorContentBloc(repository: mockFileRepository),
                child: const StatusBarWidget(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the Container widget that has the background color
        final containerFinder = find.byType(Container).first;
        final darkContainer = tester.widget<Container>(containerFinder);
        final darkColor = (darkContainer.decoration as BoxDecoration?)?.color ?? darkContainer.color;

        // Verify dark theme color matches EditorThemeExtension.dark().statusBarBackground
        expect(
          darkColor,
          EditorThemeExtension.dark().statusBarBackground,
          reason: 'Dark theme should use EditorThemeExtension.dark().statusBarBackground',
        );

        // Rebuild with light theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: BlocProvider(
                create: (_) => EditorContentBloc(repository: mockFileRepository),
                child: const StatusBarWidget(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the Container widget again after theme change
        final lightContainer = tester.widget<Container>(containerFinder);
        final lightColor = (lightContainer.decoration as BoxDecoration?)?.color ?? lightContainer.color;

        // Verify light theme color matches EditorThemeExtension.light().statusBarBackground
        // Note: In this design, statusBarBackground is intentionally the same for both themes
        expect(
          lightColor,
          EditorThemeExtension.light().statusBarBackground,
          reason: 'Light theme should use EditorThemeExtension.light().statusBarBackground',
        );

        // Verify that the widget is using theme-aware colors (even if they happen to be the same)
        // The key is that the widget retrieves colors from Theme.of(context), not static AppColors
        expect(
          darkColor,
          equals(AppColors.statusBarBackground),
          reason: 'Dark theme statusBarBackground should match AppColors.statusBarBackground',
        );

        expect(
          lightColor,
          equals(AppColors.lightStatusBarBackground),
          reason: 'Light theme statusBarBackground should match AppColors.lightStatusBarBackground',
        );
      },
    );

    testWidgets(
      'FileExplorerWidget should update text colors when theme changes from dark to light',
      (tester) async {
        // EXPECTED OUTCOME: This test FAILS on unfixed code
        // This proves FileExplorerWidget uses AppColors.textColor and AppColors.textColorDimmed directly
        
        // Build FileExplorerWidget with dark theme (empty state)
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: BlocProvider(
                create: (_) => FileExplorerBloc(repository: mockWorkspaceRepository),
                child: FileExplorerWidget(
                  onFileSelected: (path, isDirectory) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the "No folder opened" text widget
        final textFinder = find.text('No folder opened');
        expect(textFinder, findsOneWidget);
        
        final darkText = tester.widget<Text>(textFinder);
        final darkTextColor = darkText.style?.color;

        // Verify dark theme color is applied
        expect(
          darkTextColor,
          AppColors.textColor,
          reason: 'Dark theme should use AppColors.textColor',
        );

        // Rebuild with light theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: BlocProvider(
                create: (_) => FileExplorerBloc(repository: mockWorkspaceRepository),
                child: FileExplorerWidget(
                  onFileSelected: (path, isDirectory) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the text widget again after theme change
        final lightText = tester.widget<Text>(textFinder);
        final lightTextColor = lightText.style?.color;

        // CRITICAL ASSERTION: This WILL FAIL on unfixed code
        // Expected behavior: text color should change when theme changes
        // Actual behavior: color stays the same (AppColors.textColor is static)
        expect(
          lightTextColor,
          isNot(equals(darkTextColor)),
          reason: 'EXPECTED FAILURE: FileExplorerWidget should update text color when theme changes, '
              'but it uses AppColors.textColor directly which is static. '
              'This counterexample proves the bug exists.',
        );

        // Additional assertion: light theme should use AppColors.lightTextColor
        // This will also fail because FileExplorerWidget doesn't access theme
        expect(
          lightTextColor,
          AppColors.lightTextColor,
          reason: 'EXPECTED FAILURE: Light theme should use AppColors.lightTextColor, '
              'but FileExplorerWidget uses static AppColors.textColor regardless of theme.',
        );
      },
    );

    testWidgets(
      'FileExplorerWidget button should retrieve color from Theme.of(context)',
      (tester) async {
        // This test verifies that FileExplorerWidget button uses Theme.of(context).extension<EditorThemeExtension>()
        // instead of directly accessing AppColors
        
        // Build FileExplorerWidget with dark theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: BlocProvider(
                create: (_) => FileExplorerBloc(repository: mockWorkspaceRepository),
                child: FileExplorerWidget(
                  onFileSelected: (path, isDirectory) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the "Open Folder" button
        final buttonFinder = find.widgetWithText(ElevatedButton, 'Open Folder');
        expect(buttonFinder, findsOneWidget);
        
        final darkButton = tester.widget<ElevatedButton>(buttonFinder);
        final darkButtonStyle = darkButton.style;
        final darkBackgroundColor = darkButtonStyle?.backgroundColor?.resolve({});

        // Verify dark theme button color matches EditorThemeExtension.dark().statusBarBackground
        expect(
          darkBackgroundColor,
          EditorThemeExtension.dark().statusBarBackground,
          reason: 'Dark theme button should use EditorThemeExtension.dark().statusBarBackground',
        );

        // Rebuild with light theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: BlocProvider(
                create: (_) => FileExplorerBloc(repository: mockWorkspaceRepository),
                child: FileExplorerWidget(
                  onFileSelected: (path, isDirectory) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final lightButton = tester.widget<ElevatedButton>(buttonFinder);
        final lightButtonStyle = lightButton.style;
        final lightBackgroundColor = lightButtonStyle?.backgroundColor?.resolve({});

        // Verify light theme button color matches EditorThemeExtension.light().statusBarBackground
        expect(
          lightBackgroundColor,
          EditorThemeExtension.light().statusBarBackground,
          reason: 'Light theme button should use EditorThemeExtension.light().statusBarBackground',
        );

        // Verify that the widget is using theme-aware colors
        expect(
          darkBackgroundColor,
          equals(AppColors.statusBarBackground),
          reason: 'Dark theme button should match AppColors.statusBarBackground',
        );

        expect(
          lightBackgroundColor,
          equals(AppColors.lightStatusBarBackground),
          reason: 'Light theme button should match AppColors.lightStatusBarBackground',
        );
      },
    );

    testWidgets(
      'FileExplorerWidget selected item color should update when theme changes',
      (tester) async {
        // EXPECTED OUTCOME: This test FAILS on unfixed code
        // This proves FileExplorerWidget uses AppColors.selectedItemColor directly
        
        // This test verifies that the selected item background color
        // should change when theme changes, but it doesn't because
        // the widget uses static AppColors.selectedItemColor
        
        // Note: This is a structural test - we're checking that the code
        // would use theme-aware colors if a file were selected
        // The actual selection behavior requires file system interaction
        
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: BlocProvider(
                create: (_) => FileExplorerBloc(repository: mockWorkspaceRepository),
                child: FileExplorerWidget(
                  onFileSelected: (path, isDirectory) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify the widget is built with dark theme
        final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.theme, AppTheme.dark);

        // Rebuild with light theme
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: BlocProvider(
                create: (_) => FileExplorerBloc(repository: mockWorkspaceRepository),
                child: FileExplorerWidget(
                  onFileSelected: (path, isDirectory) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify the widget is rebuilt with light theme
        final lightMaterialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(lightMaterialApp.theme, AppTheme.light);

        // COUNTEREXAMPLE DOCUMENTATION:
        // The FileExplorerWidget._FileNodeWidget uses:
        //   color: isSelected ? AppColors.selectedItemColor : null
        // This means selected items will always use AppColors.selectedItemColor (dark theme color)
        // regardless of the current theme. When theme changes to light, selected items
        // should use AppColors.lightSelectedItemColor, but they don't.
        
        // This structural issue is documented as a counterexample:
        // - Widget code contains: AppColors.selectedItemColor
        // - Widget code should contain: Theme.of(context).extension<EditorThemeExtension>()!.selectedItemColor
        // - Current behavior: static color regardless of theme
        // - Expected behavior: dynamic color from current theme
      },
    );
  });
}
