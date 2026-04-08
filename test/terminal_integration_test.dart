import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/goox_terminal.dart';

/// Integration test for terminal functionality
///
/// This test verifies:
/// - Terminal panel can be created
/// - Terminal sessions can be created
/// - Terminal theme can be applied
/// - Multiple terminals can be managed
void main() {
  group('Terminal Integration Tests', () {
    test('TerminalSessionManager can create and manage sessions', () async {
      final sessionManager = TerminalSessionManager.instance;
      
      // Verify initial state
      expect(sessionManager.sessionCount, 0);
      expect(sessionManager.canCreateSession, true);
      
      // Create a session
      final controller = await sessionManager.createSession();
      
      // Verify session was created
      expect(sessionManager.sessionCount, 1);
      expect(sessionManager.activeSession, controller);
      expect(controller.status, TerminalStatus.running);
      
      // Create another session
      final controller2 = await sessionManager.createSession();
      
      // Verify second session
      expect(sessionManager.sessionCount, 2);
      expect(sessionManager.activeSession, controller2);
      
      // Switch to first session
      sessionManager.activeSessionId = controller.id;
      expect(sessionManager.activeSession, controller);
      
      // Close first session
      await sessionManager.closeSession(controller.id);
      expect(sessionManager.sessionCount, 1);
      
      // Close all sessions
      await sessionManager.closeAllSessions();
      expect(sessionManager.sessionCount, 0);
    });

    test('Terminal themes can be created and converted', () {
      // Test dark theme
      final darkTheme = TerminalTheme.dark();
      expect(darkTheme.background, isNotNull);
      expect(darkTheme.foreground, isNotNull);
      
      final darkXtermTheme = darkTheme.toXTermTheme();
      expect(darkXtermTheme, isNotNull);
      
      // Test light theme
      final lightTheme = TerminalTheme.light();
      expect(lightTheme.background, isNotNull);
      expect(lightTheme.foreground, isNotNull);
      
      final lightXtermTheme = lightTheme.toXTermTheme();
      expect(lightXtermTheme, isNotNull);
    });

    testWidgets('TerminalPanel can be rendered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalPanel(
              initialHeight: 300,
              theme: TerminalTheme.dark(),
            ),
          ),
        ),
      );
      
      // Wait for widget to build
      await tester.pump();
      
      // Verify terminal panel is rendered
      expect(find.byType(TerminalPanel), findsOneWidget);
    });

    test('Session limit is enforced', () async {
      final sessionManager = TerminalSessionManager.instance;
      
      // Clean up any existing sessions
      await sessionManager.closeAllSessions();
      
      // Create maximum number of sessions (10)
      final controllers = <TerminalController>[];
      for (int i = 0; i < 10; i++) {
        final controller = await sessionManager.createSession();
        controllers.add(controller);
      }
      
      expect(sessionManager.sessionCount, 10);
      expect(sessionManager.canCreateSession, false);
      
      // Clean up
      await sessionManager.closeAllSessions();
    });
  });
}
