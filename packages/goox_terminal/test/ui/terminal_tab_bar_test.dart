import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/terminal/data/models/terminal_instance.dart';
import 'package:goox/features/terminal/data/models/terminal_output.dart';
import 'package:goox/features/terminal/presentation/blocs/terminal_bloc.dart';
import '../../lib/src/ui/terminal_tab.dart';
import 'package:goox/features/terminal/presentation/widgets/terminal_tab_bar.dart';
import 'package:goox_ui/goox_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

// Mock classes
class MockTerminalBloc extends MockBloc<TerminalEvent, TerminalState>
    implements TerminalBloc {}

void main() {

  group('TerminalTabBar', () {
    late MockTerminalBloc mockBloc;
    late List<TerminalInstance> testTerminals;

    setUp(() {
      mockBloc = MockTerminalBloc();
      testTerminals = [
        TerminalInstance(
          id: 'terminal-1',
          title: 'bash',
          workingDirectory: '/test1',
          output: const TerminalOutput(lines: []),
          status: TerminalInstanceStatus.running,
          createdAt: DateTime.now(),
        ),
        TerminalInstance(
          id: 'terminal-2',
          title: 'zsh',
          workingDirectory: '/test2',
          output: const TerminalOutput(lines: []),
          status: TerminalInstanceStatus.running,
          createdAt: DateTime.now(),
        ),
        TerminalInstance(
          id: 'terminal-3',
          title: 'powershell',
          workingDirectory: '/test3',
          output: const TerminalOutput(lines: []),
          status: TerminalInstanceStatus.running,
          createdAt: DateTime.now(),
        ),
      ];
    });

    Widget createTestWidget({
      required List<TerminalInstance> terminals,
      required String? activeTerminalId,
      required bool canCreateTerminal,
    }) {
      return MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: [EditorThemeExtension.dark()],
        ),
        home: Scaffold(
          body: BlocProvider<TerminalBloc>.value(
            value: mockBloc,
            child: TerminalTabBar(
              terminals: terminals,
              activeTerminalId: activeTerminalId,
              canCreateTerminal: canCreateTerminal,
            ),
          ),
        ),
      );
    }

    testWidgets('renders all terminal tabs', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminals: testTerminals,
          activeTerminalId: 'terminal-1',
          canCreateTerminal: true,
        ),
      );

      // Verify all terminal tabs are rendered
      expect(find.byType(TerminalTab), findsNWidgets(3));
      expect(find.text('bash'), findsOneWidget);
      expect(find.text('zsh'), findsOneWidget);
      expect(find.text('powershell'), findsOneWidget);
    });

    testWidgets('renders create button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminals: testTerminals,
          activeTerminalId: 'terminal-1',
          canCreateTerminal: true,
        ),
      );

      // Verify create button is rendered
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('disables create button at max terminals', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminals: testTerminals,
          activeTerminalId: 'terminal-1',
          canCreateTerminal: false,
        ),
      );

      // Find the IconButton
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.add),
          matching: find.byType(IconButton),
        ),
      );

      // Verify button is disabled
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('enables create button when below max terminals',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminals: testTerminals,
          activeTerminalId: 'terminal-1',
          canCreateTerminal: true,
        ),
      );

      // Find the IconButton
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.add),
          matching: find.byType(IconButton),
        ),
      );

      // Verify button is enabled
      expect(iconButton.onPressed, isNotNull);
    });

    testWidgets('dispatches CreateTerminalEvent on "+" click', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminals: testTerminals,
          activeTerminalId: 'terminal-1',
          canCreateTerminal: true,
        ),
      );

      // Tap on the create button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify CreateTerminalEvent was dispatched
      verify(() => mockBloc.add(const CreateTerminalEvent())).called(1);
    });

    testWidgets('does not dispatch event when create button is disabled',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminals: testTerminals,
          activeTerminalId: 'terminal-1',
          canCreateTerminal: false,
        ),
      );

      // Try to tap on the disabled create button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify CreateTerminalEvent was NOT dispatched
      verifyNever(() => mockBloc.add(const CreateTerminalEvent()));
    });

    testWidgets('has correct height', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminals: testTerminals,
          activeTerminalId: 'terminal-1',
          canCreateTerminal: true,
        ),
      );

      // Find the main container
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TerminalTabBar),
          matching: find.byType(Container).first,
        ),
      );

      // Verify height constraints
      expect(container.constraints?.maxHeight, 35);
    });

    testWidgets('displays tooltip on create button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminals: testTerminals,
          activeTerminalId: 'terminal-1',
          canCreateTerminal: true,
        ),
      );

      // Find the Tooltip widget
      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.byIcon(Icons.add),
          matching: find.byType(Tooltip),
        ),
      );

      // Verify tooltip message
      expect(tooltip.message, 'New Terminal (Ctrl+Shift+`)');
    });

    testWidgets('renders empty list when no terminals', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminals: [],
          activeTerminalId: null,
          canCreateTerminal: true,
        ),
      );

      // Verify no terminal tabs are rendered
      expect(find.byType(TerminalTab), findsNothing);

      // But create button should still be present
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('uses horizontal scrolling for tabs', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminals: testTerminals,
          activeTerminalId: 'terminal-1',
          canCreateTerminal: true,
        ),
      );

      // Find the ListView
      final listView = tester.widget<ListView>(
        find.descendant(
          of: find.byType(TerminalTabBar),
          matching: find.byType(ListView),
        ),
      );

      // Verify horizontal scrolling
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('passes correct isActive state to tabs', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          terminals: testTerminals,
          activeTerminalId: 'terminal-2',
          canCreateTerminal: true,
        ),
      );

      // Find all TerminalTab widgets
      final terminalTabs = tester.widgetList<TerminalTab>(
        find.byType(TerminalTab),
      );

      // Verify isActive state
      expect(terminalTabs.elementAt(0).isActive, false); // terminal-1
      expect(terminalTabs.elementAt(1).isActive, true); // terminal-2 (active)
      expect(terminalTabs.elementAt(2).isActive, false); // terminal-3
    });
  });
}
