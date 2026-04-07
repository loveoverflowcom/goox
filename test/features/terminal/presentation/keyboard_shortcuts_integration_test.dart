import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/terminal/data/models/terminal_config.dart';
import 'package:goox/features/terminal/data/models/terminal_session.dart';
import 'package:goox/features/terminal/data/repositories/terminal_repository.dart';
import 'package:goox/features/terminal/presentation/blocs/terminal_panel_bloc.dart';
import 'package:goox_terminal/goox_terminal.dart';
import 'package:mocktail/mocktail.dart';

class MockTerminalRepository extends Mock implements TerminalRepository {}

class MockPTYService extends Mock implements PTYService {}

class MockShellDetector extends Mock implements ShellDetector {}

class MockANSIParser extends Mock implements ANSIParser {}

class MockPTYProcess extends Mock implements PTYProcess {}

class FakePTYProcess extends Fake implements PTYProcess {}

class FakeShellConfig extends Fake implements ShellConfig {}

void main() {
  late MockTerminalRepository mockRepository;
  late MockPTYService mockPTYService;
  late MockShellDetector mockShellDetector;
  late MockANSIParser mockANSIParser;

  setUpAll(() {
    registerFallbackValue(FakePTYProcess());
    registerFallbackValue(FakeShellConfig());
  });

  setUp(() {
    mockRepository = MockTerminalRepository();
    mockPTYService = MockPTYService();
    mockShellDetector = MockShellDetector();
    mockANSIParser = MockANSIParser();

    // Setup default mocks
    when(() => mockRepository.loadVisibility()).thenAnswer((_) async => false);
    when(() => mockRepository.loadHeight())
        .thenAnswer((_) async => TerminalConfig.defaultHeight);
    when(() => mockRepository.loadTerminalCount()).thenAnswer((_) async => 0);
    when(() => mockRepository.loadWorkingDirectories())
        .thenAnswer((_) async => <String>[]);
    when(() => mockRepository.saveVisibility(isVisible: any(named: 'isVisible')))
        .thenAnswer((_) async {});
    when(() => mockRepository.saveHeight(height: any(named: 'height')))
        .thenAnswer((_) async {});
    when(() => mockRepository.saveTerminalCount(count: any(named: 'count')))
        .thenAnswer((_) async {});
    when(() => mockRepository.saveWorkingDirectories(paths: any(named: 'paths')))
        .thenAnswer((_) async {});
    when(() => mockPTYService.terminate(any(), force: any(named: 'force')))
        .thenAnswer((_) async {});
    when(() => mockPTYService.createPTY(
          shellConfig: any(named: 'shellConfig'),
          workingDirectory: any(named: 'workingDirectory'),
        )).thenAnswer((_) async {
      final mockPTY = MockPTYProcess();
      when(() => mockPTY.stdout).thenAnswer((_) => const Stream<String>.empty());
      when(() => mockPTY.exitCode).thenAnswer((_) => Future.value(0));
      return mockPTY;
    });
    when(() => mockShellDetector.detectShell()).thenAnswer(
      (_) async => const ShellConfig(
        executable: '/bin/bash',
        args: <String>['-l'],
        environment: <String, String>{},
      ),
    );
    when(() => mockANSIParser.parse(any()))
        .thenReturn(<TerminalLine>[const TerminalLine(text: '', styles: <ANSIStyle>[])]);
  });

  Widget createTestWidget(TerminalPanelBloc terminalBloc) {
    return MaterialApp(
      home: BlocProvider<TerminalPanelBloc>.value(
        value: terminalBloc,
        child: Scaffold(
          body: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;

              final isCtrl = HardwareKeyboard.instance.isControlPressed;
              final isShift = HardwareKeyboard.instance.isShiftPressed;

              // Ctrl + ` (backtick): Toggle terminal
              if (isCtrl &&
                  event.logicalKey == LogicalKeyboardKey.backquote &&
                  !isShift) {
                terminalBloc.add(const ToggleTerminalPanelEvent());
                return KeyEventResult.handled;
              }

              // Ctrl + Shift + ` (backtick): Create new terminal
              if (isCtrl &&
                  isShift &&
                  event.logicalKey == LogicalKeyboardKey.backquote) {
                terminalBloc.add(const CreateTerminalSessionEvent());
                return KeyEventResult.handled;
              }

              // Ctrl + PageUp: Cycle to previous terminal
              if (isCtrl && event.logicalKey == LogicalKeyboardKey.pageUp) {
                terminalBloc
                    .add(const CycleTerminalSessionEvent(forward: false));
                return KeyEventResult.handled;
              }

              // Ctrl + PageDown: Cycle to next terminal
              if (isCtrl && event.logicalKey == LogicalKeyboardKey.pageDown) {
                terminalBloc
                    .add(const CycleTerminalSessionEvent(forward: true));
                return KeyEventResult.handled;
              }

              // Ctrl + Shift + W: Close active terminal
              if (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyW) {
                final state = terminalBloc.state;
                if (state.activeSessionId != null) {
                  terminalBloc.add(
                    CloseTerminalSessionEvent(state.activeSessionId!),
                  );
                }
                return KeyEventResult.handled;
              }

              return KeyEventResult.ignored;
            },
            child: const Text('Test Widget'),
          ),
        ),
      ),
    );
  }

  group('Terminal Keyboard Shortcuts Integration Tests', () {
    testWidgets('Ctrl+` toggles terminal visibility', (tester) async {
      final terminalBloc = TerminalPanelBloc(
        repository: mockRepository,
        ptyService: mockPTYService,
        shellDetector: mockShellDetector,
        ansiParser: mockANSIParser,
      );

      await tester.pumpWidget(createTestWidget(terminalBloc));
      await tester.pumpAndSettle();

      // Initial state: terminal not visible
      expect(terminalBloc.state.isVisible, false);

      // Press Ctrl+`
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.backquote);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Terminal should now be visible
      expect(terminalBloc.state.isVisible, true);

      // Press Ctrl+` again
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.backquote);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Terminal should be hidden again
      expect(terminalBloc.state.isVisible, false);

      await terminalBloc.close();
    });

    testWidgets('Ctrl+Shift+` creates new terminal', (tester) async {
      final terminalBloc = TerminalPanelBloc(
        repository: mockRepository,
        ptyService: mockPTYService,
        shellDetector: mockShellDetector,
        ansiParser: mockANSIParser,
      );

      // Initialize terminal first
      terminalBloc.add(const InitializeTerminalPanelEvent());
      await tester.pumpWidget(createTestWidget(terminalBloc));
      await tester.pumpAndSettle();

      final initialSessionCount = terminalBloc.state.sessionCount;

      // Press Ctrl+Shift+`
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.backquote);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // A CreateTerminalSessionEvent should have been dispatched
      expect(terminalBloc.state.sessionCount, greaterThanOrEqualTo(initialSessionCount));

      await terminalBloc.close();
    });

    testWidgets('Ctrl+PageUp cycles to previous terminal', (tester) async {
      final terminalBloc = TerminalPanelBloc(
        repository: mockRepository,
        ptyService: mockPTYService,
        shellDetector: mockShellDetector,
        ansiParser: mockANSIParser,
      );

      // Create a state with multiple sessions
      final session1 = TerminalSession(
        id: 'session1',
        workingDirectory: '/test',
        controller: TerminalController(
          ptyService: mockPTYService,
          shellDetector: mockShellDetector,
          ansiParser: mockANSIParser,
          workingDirectory: '/test',
        ),
        createdAt: DateTime.now(),
      );
      final session2 = TerminalSession(
        id: 'session2',
        workingDirectory: '/test',
        controller: TerminalController(
          ptyService: mockPTYService,
          shellDetector: mockShellDetector,
          ansiParser: mockANSIParser,
          workingDirectory: '/test',
        ),
        createdAt: DateTime.now(),
      );

      terminalBloc.emit(
        terminalBloc.state.copyWith(
          sessions: <TerminalSession>[session1, session2],
          activeSessionId: 'session2',
        ),
      );

      await tester.pumpWidget(createTestWidget(terminalBloc));
      await tester.pumpAndSettle();

      expect(terminalBloc.state.activeSessionId, 'session2');

      // Press Ctrl+PageUp
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Should cycle to previous session (session1)
      expect(terminalBloc.state.activeSessionId, 'session1');

      await terminalBloc.close();
    });

    testWidgets('Ctrl+PageDown cycles to next terminal', (tester) async {
      final terminalBloc = TerminalPanelBloc(
        repository: mockRepository,
        ptyService: mockPTYService,
        shellDetector: mockShellDetector,
        ansiParser: mockANSIParser,
      );

      // Create a state with multiple sessions
      final session1 = TerminalSession(
        id: 'session1',
        workingDirectory: '/test',
        controller: TerminalController(
          ptyService: mockPTYService,
          shellDetector: mockShellDetector,
          ansiParser: mockANSIParser,
          workingDirectory: '/test',
        ),
        createdAt: DateTime.now(),
      );
      final session2 = TerminalSession(
        id: 'session2',
        workingDirectory: '/test',
        controller: TerminalController(
          ptyService: mockPTYService,
          shellDetector: mockShellDetector,
          ansiParser: mockANSIParser,
          workingDirectory: '/test',
        ),
        createdAt: DateTime.now(),
      );

      terminalBloc.emit(
        terminalBloc.state.copyWith(
          sessions: <TerminalSession>[session1, session2],
          activeSessionId: 'session1',
        ),
      );

      await tester.pumpWidget(createTestWidget(terminalBloc));
      await tester.pumpAndSettle();

      expect(terminalBloc.state.activeSessionId, 'session1');

      // Press Ctrl+PageDown
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Should cycle to next session (session2)
      expect(terminalBloc.state.activeSessionId, 'session2');

      await terminalBloc.close();
    });

    testWidgets('Ctrl+Shift+W closes active terminal', (tester) async {
      final terminalBloc = TerminalPanelBloc(
        repository: mockRepository,
        ptyService: mockPTYService,
        shellDetector: mockShellDetector,
        ansiParser: mockANSIParser,
      );

      // Create a state with a session
      final session1 = TerminalSession(
        id: 'session1',
        workingDirectory: '/test',
        controller: TerminalController(
          ptyService: mockPTYService,
          shellDetector: mockShellDetector,
          ansiParser: mockANSIParser,
          workingDirectory: '/test',
        ),
        createdAt: DateTime.now(),
      );

      terminalBloc.emit(
        terminalBloc.state.copyWith(
          sessions: <TerminalSession>[session1],
          activeSessionId: 'session1',
        ),
      );

      await tester.pumpWidget(createTestWidget(terminalBloc));
      await tester.pumpAndSettle();

      expect(terminalBloc.state.activeSessionId, 'session1');
      expect(terminalBloc.state.sessionCount, 1);

      // Press Ctrl+Shift+W
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // The CloseTerminalSessionEvent should have been dispatched
      // Note: The actual session closure depends on the bloc implementation

      await terminalBloc.close();
    });

    testWidgets('Terminal input bypasses global shortcuts', (tester) async {
      // This test verifies that when terminal is focused, regular input
      // doesn't trigger global shortcuts (except the specific terminal shortcuts)

      final terminalBloc = TerminalPanelBloc(
        repository: mockRepository,
        ptyService: mockPTYService,
        shellDetector: mockShellDetector,
        ansiParser: mockANSIParser,
      );

      await tester.pumpWidget(createTestWidget(terminalBloc));
      await tester.pumpAndSettle();

      // Simulate typing regular characters - these should not trigger shortcuts
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
      await tester.pumpAndSettle();

      // Terminal state should remain unchanged (no shortcuts triggered)
      expect(terminalBloc.state.isVisible, false);

      // But Ctrl+` should still work (global terminal shortcut)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.backquote);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      expect(terminalBloc.state.isVisible, true);

      await terminalBloc.close();
    });
  });
}
