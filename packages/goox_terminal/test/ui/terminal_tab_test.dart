import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/terminal/data/models/terminal_instance.dart';
import 'package:goox/features/terminal/data/models/terminal_output.dart';
import 'package:goox/features/terminal/presentation/blocs/terminal_bloc.dart';
import '../../lib/src/ui/terminal_tab.dart';
import 'package:goox_ui/goox_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

// Mock classes
class MockTerminalBloc extends MockBloc<TerminalEvent, TerminalState>
    implements TerminalBloc {}

void main() {

  group('TerminalTab', () {
    late MockTerminalBloc mockBloc;
    late TerminalInstance testTerminal;

    setUp(() {
      mockBloc = MockTerminalBloc();
      testTerminal = TerminalInstance(
        id: 'terminal-1',
        title: 'bash',
        workingDirectory: '/test',
        output: const TerminalOutput(lines: []),
        status: TerminalInstanceStatus.running,
        createdAt: DateTime.now(),
      );
    });

    Widget createTestWidget({
      required TerminalInstance terminal,
      required bool isActive,
    }) {
      return MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: [EditorThemeExtension.dark()],
        ),
        home: Scaffold(
          body: BlocProvider<TerminalBloc>.value(
            value: mockBloc,
            child: TerminalTab(
              terminal: terminal,
              isActive: isActive,
            ),
          ),
        ),
      );
    }

    testWidgets('renders terminal title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminal: testTerminal,
          isActive: false,
        ),
      );

      expect(find.text('bash'), findsOneWidget);
    });

    testWidgets('shows active styling when active', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminal: testTerminal,
          isActive: true,
        ),
      );

      // Find the container with the tab styling
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TerminalTab),
          matching: find.byType(Container).first,
        ),
      );

      // Verify active background color is applied
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.activeTabBackground);
    });

    testWidgets('shows inactive styling when not active', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminal: testTerminal,
          isActive: false,
        ),
      );

      // Find the container with the tab styling
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TerminalTab),
          matching: find.byType(Container).first,
        ),
      );

      // Verify inactive background color is applied
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.inactiveTabBackground);
    });

    testWidgets('shows close button on hover', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminal: testTerminal,
          isActive: false,
        ),
      );

      // Initially, close button should not be visible
      expect(find.byIcon(Icons.close), findsNothing);

      // Hover over the tab
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(TerminalTab)));
      await tester.pumpAndSettle();

      // Close button should now be visible
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('hides close button when not hovered', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminal: testTerminal,
          isActive: false,
        ),
      );

      // Hover over the tab
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(TerminalTab)));
      await tester.pumpAndSettle();

      // Close button should be visible
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Move mouse away from the tab
      await gesture.moveTo(const Offset(-100, -100));
      await tester.pumpAndSettle();

      // Close button should be hidden
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('dispatches SwitchTerminalEvent on click', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminal: testTerminal,
          isActive: false,
        ),
      );

      // Tap on the tab
      await tester.tap(find.byType(TerminalTab));
      await tester.pumpAndSettle();

      // Verify SwitchTerminalEvent was dispatched
      verify(() => mockBloc.add(const SwitchTerminalEvent('terminal-1')))
          .called(1);
    });

    testWidgets('dispatches CloseTerminalEvent on close button click',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminal: testTerminal,
          isActive: false,
        ),
      );

      // Hover over the tab to show close button
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(TerminalTab)));
      await tester.pumpAndSettle();

      // Tap on the close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify CloseTerminalEvent was dispatched
      verify(() => mockBloc.add(const CloseTerminalEvent('terminal-1')))
          .called(1);
    });

    testWidgets('truncates long titles', (tester) async {
      final longTitleTerminal = TerminalInstance(
        id: 'terminal-long',
        title: 'This is a very long terminal title that should be truncated',
        workingDirectory: '/test',
        output: const TerminalOutput(lines: []),
        status: TerminalInstanceStatus.running,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          terminal: longTitleTerminal,
          isActive: false,
        ),
      );

      // Find the Text widget displaying the title
      final textWidget = tester.widget<Text>(
        find.text(
            'This is a very long terminal title that should be truncated'),
      );

      // Verify ellipsis overflow is set
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('respects min and max width constraints', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminal: testTerminal,
          isActive: false,
        ),
      );

      // Find the container with constraints
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TerminalTab),
          matching: find.byType(Container).first,
        ),
      );

      // Verify constraints
      expect(container.constraints?.minWidth, 120);
      expect(container.constraints?.maxWidth, 200);
    });
  });
}
