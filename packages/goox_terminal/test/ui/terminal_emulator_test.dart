import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/terminal/data/models/ansi_style.dart';
import 'package:goox/features/terminal/data/models/terminal_instance.dart';
import 'package:goox/features/terminal/data/models/terminal_output.dart';
import 'package:goox/features/terminal/presentation/blocs/terminal_bloc.dart';
import '../../lib/src/ui/terminal_emulator.dart';
import 'package:goox_ui/goox_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

// Mock classes
class MockTerminalBloc extends MockBloc<TerminalEvent, TerminalState>
    implements TerminalBloc {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(
      const TerminalInputEvent(terminalId: '', input: ''),
    );
  });

  group('TerminalEmulator', () {
    late MockTerminalBloc mockBloc;
    late TerminalInstance testTerminal;

    setUp(() {
      mockBloc = MockTerminalBloc();
      testTerminal = TerminalInstance(
        id: 'terminal-1',
        title: 'bash',
        workingDirectory: '/test',
        output: TerminalOutput(
          lines: [
            TerminalLine.plain('Line 1'),
            TerminalLine.plain('Line 2'),
            TerminalLine.plain('Line 3'),
          ],
        ),
        status: TerminalInstanceStatus.running,
        createdAt: DateTime.now(),
      );
    });

    Widget createTestWidget({required TerminalInstance terminal}) {
      return MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: [EditorThemeExtension.dark()],
        ),
        home: Scaffold(
          body: BlocProvider<TerminalBloc>.value(
            value: mockBloc,
            child: TerminalEmulator(terminal: terminal),
          ),
        ),
      );
    }

    testWidgets('renders terminal lines', (tester) async {
      await tester.pumpWidget(createTestWidget(terminal: testTerminal));

      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
      expect(find.text('Line 3'), findsOneWidget);
    });

    testWidgets('applies ANSI styles correctly', (tester) async {
      final styledTerminal = TerminalInstance(
        id: 'terminal-styled',
        title: 'bash',
        workingDirectory: '/test',
        output: TerminalOutput(
          lines: [
            const TerminalLine(
              text: 'Styled text',
              styles: [
                ANSIStyle(
                  startIndex: 0,
                  endIndex: 6,
                  foregroundColor: Colors.red,
                  bold: true,
                ),
              ],
            ),
          ],
        ),
        status: TerminalInstanceStatus.running,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(terminal: styledTerminal));

      // Find the Text.rich widget
      final richText = tester.widget<Text>(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.textSpan != null,
        ),
      );

      expect(richText.textSpan, isNotNull);
    });

    testWidgets('auto-scrolls to bottom on new output', (tester) async {
      await tester.pumpWidget(createTestWidget(terminal: testTerminal));
      await tester.pumpAndSettle();

      // Find the ListView
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Create a terminal with more lines
      final updatedTerminal = testTerminal.copyWith(
        output: TerminalOutput(
          lines: [
            ...testTerminal.output.lines,
            TerminalLine.plain('Line 4'),
            TerminalLine.plain('Line 5'),
          ],
        ),
      );

      // Update the widget with new output
      await tester.pumpWidget(createTestWidget(terminal: updatedTerminal));
      await tester.pumpAndSettle();

      // Verify new lines are rendered
      expect(find.text('Line 4'), findsOneWidget);
      expect(find.text('Line 5'), findsOneWidget);
    });

    testWidgets('handles Enter key', (tester) async {
      await tester.pumpWidget(createTestWidget(terminal: testTerminal));
      await tester.pumpAndSettle();

      // Focus the terminal
      await tester.tap(find.byType(TerminalEmulator));
      await tester.pumpAndSettle();

      // Simulate Enter key press
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Verify TerminalInputEvent was dispatched with newline
      verify(
        () => mockBloc.add(
          const TerminalInputEvent(
            terminalId: 'terminal-1',
            input: '\n',
          ),
        ),
      ).called(1);
    });

    testWidgets('handles Backspace key', (tester) async {
      await tester.pumpWidget(createTestWidget(terminal: testTerminal));
      await tester.pumpAndSettle();

      // Focus the terminal
      await tester.tap(find.byType(TerminalEmulator));
      await tester.pumpAndSettle();

      // Simulate Backspace key press
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      // Verify TerminalInputEvent was dispatched with DEL character
      verify(
        () => mockBloc.add(
          const TerminalInputEvent(
            terminalId: 'terminal-1',
            input: '\x7f',
          ),
        ),
      ).called(1);
    });

    testWidgets('handles Ctrl+C', (tester) async {
      await tester.pumpWidget(createTestWidget(terminal: testTerminal));
      await tester.pumpAndSettle();

      // Focus the terminal
      await tester.tap(find.byType(TerminalEmulator));
      await tester.pumpAndSettle();

      // Simulate Ctrl+C key press
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Verify TerminalInputEvent was dispatched with SIGINT
      verify(
        () => mockBloc.add(
          const TerminalInputEvent(
            terminalId: 'terminal-1',
            input: '\x03',
          ),
        ),
      ).called(1);
    });

    testWidgets('handles Ctrl+D', (tester) async {
      await tester.pumpWidget(createTestWidget(terminal: testTerminal));
      await tester.pumpAndSettle();

      // Focus the terminal
      await tester.tap(find.byType(TerminalEmulator));
      await tester.pumpAndSettle();

      // Simulate Ctrl+D key press
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Verify TerminalInputEvent was dispatched with EOF
      verify(
        () => mockBloc.add(
          const TerminalInputEvent(
            terminalId: 'terminal-1',
            input: '\x04',
          ),
        ),
      ).called(1);
    });

    testWidgets('focuses on tap', (tester) async {
      await tester.pumpWidget(createTestWidget(terminal: testTerminal));
      await tester.pumpAndSettle();

      // Find the Focus widget inside TerminalEmulator
      final focusWidget = tester.widget<Focus>(
        find.descendant(
          of: find.byType(TerminalEmulator),
          matching: find.byType(Focus),
        ),
      );
      expect(focusWidget.focusNode, isNotNull);

      // Tap on the terminal
      await tester.tap(find.byType(TerminalEmulator));
      await tester.pumpAndSettle();

      // Verify focus is requested (widget should be focused)
      expect(focusWidget.focusNode!.hasFocus, isTrue);
    });

    testWidgets('handles regular character input', (tester) async {
      await tester.pumpWidget(createTestWidget(terminal: testTerminal));
      await tester.pumpAndSettle();

      // Focus the terminal
      await tester.tap(find.byType(TerminalEmulator));
      await tester.pumpAndSettle();

      // Simulate typing 'a'
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
      await tester.pumpAndSettle();

      // Verify TerminalInputEvent was dispatched with the character
      verify(
        () => mockBloc.add(
          const TerminalInputEvent(
            terminalId: 'terminal-1',
            input: 'a',
          ),
        ),
      ).called(1);
    });

    testWidgets('renders plain text without styles', (tester) async {
      await tester.pumpWidget(createTestWidget(terminal: testTerminal));

      // Find plain text widgets
      final textWidgets = tester.widgetList<Text>(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.textSpan == null,
        ),
      );

      expect(textWidgets.length, greaterThan(0));
    });

    testWidgets('applies monospace font', (tester) async {
      await tester.pumpWidget(createTestWidget(terminal: testTerminal));

      // Find any text widget
      final textWidget = tester.widget<Text>(find.text('Line 1'));

      // Verify monospace font is applied (with fallback chain)
      expect(
        textWidget.style?.fontFamily,
        'Fira Code, JetBrains Mono, Cascadia Code, Consolas, SF Mono, monospace',
      );
    });

    testWidgets('applies correct font size and line height', (tester) async {
      await tester.pumpWidget(createTestWidget(terminal: testTerminal));

      // Find any text widget
      final textWidget = tester.widget<Text>(find.text('Line 1'));

      // Verify font size is 13px
      expect(textWidget.style?.fontSize, 13);

      // Verify line height is 1.35 (optimal for readability)
      expect(textWidget.style?.height, 1.35);
    });

    group('Error Handling and Restart', () {
      testWidgets('shows restart button for exited terminal', (tester) async {
        final exitedTerminal = testTerminal.copyWith(
          status: TerminalInstanceStatus.exited,
          exitCode: 0,
        );

        await tester.pumpWidget(createTestWidget(terminal: exitedTerminal));
        await tester.pumpAndSettle();

        // Verify restart button is shown
        expect(find.text('Restart Terminal'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('shows restart button for error terminal', (tester) async {
        final errorTerminal = testTerminal.copyWith(
          status: TerminalInstanceStatus.error,
        );

        await tester.pumpWidget(createTestWidget(terminal: errorTerminal));
        await tester.pumpAndSettle();

        // Verify restart button is shown
        expect(find.text('Restart Terminal'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('does not show restart button for running terminal',
          (tester) async {
        await tester.pumpWidget(createTestWidget(terminal: testTerminal));
        await tester.pumpAndSettle();

        // Verify restart button is not shown
        expect(find.text('Restart Terminal'), findsNothing);
        expect(find.byIcon(Icons.refresh), findsNothing);
      });

      testWidgets('restart button dispatches RestartTerminalEvent',
          (tester) async {
        registerFallbackValue(const RestartTerminalEvent(''));

        final exitedTerminal = testTerminal.copyWith(
          status: TerminalInstanceStatus.exited,
          exitCode: 1,
        );

        await tester.pumpWidget(createTestWidget(terminal: exitedTerminal));
        await tester.pumpAndSettle();

        // Tap the restart button
        await tester.tap(find.text('Restart Terminal'));
        await tester.pumpAndSettle();

        // Verify RestartTerminalEvent was dispatched
        verify(
          () => mockBloc.add(const RestartTerminalEvent('terminal-1')),
        ).called(1);
      });

      testWidgets('disables keyboard input for dead terminal', (tester) async {
        final exitedTerminal = testTerminal.copyWith(
          status: TerminalInstanceStatus.exited,
        );

        await tester.pumpWidget(createTestWidget(terminal: exitedTerminal));
        await tester.pumpAndSettle();

        // Try to tap the terminal (should not focus)
        await tester.tap(find.byType(TerminalEmulator));
        await tester.pumpAndSettle();

        // Try to send input
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
        await tester.pumpAndSettle();

        // Verify no input event was dispatched
        verifyNever(
          () => mockBloc.add(any(that: isA<TerminalInputEvent>())),
        );
      });

      testWidgets('disables keyboard input for error terminal', (tester) async {
        final errorTerminal = testTerminal.copyWith(
          status: TerminalInstanceStatus.error,
        );

        await tester.pumpWidget(createTestWidget(terminal: errorTerminal));
        await tester.pumpAndSettle();

        // Try to tap the terminal (should not focus)
        await tester.tap(find.byType(TerminalEmulator));
        await tester.pumpAndSettle();

        // Try to send input
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
        await tester.pumpAndSettle();

        // Verify no input event was dispatched
        verifyNever(
          () => mockBloc.add(any(that: isA<TerminalInputEvent>())),
        );
      });
    });
  });
}
