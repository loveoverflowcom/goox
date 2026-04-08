import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/src/controllers/terminal_session_manager.dart';
import '../../lib/src/models/pty_size.dart';
import '../../lib/src/models/shell_config.dart';
import '../../lib/src/ui/terminal_tab_bar.dart';
import '../../lib/src/ui/terminal_theme.dart';

void main() {
  group('TerminalTabBar', () {
    late TerminalSessionManager sessionManager;

    setUp(() {
      sessionManager = TerminalSessionManager.instance;
    });

    tearDown(() async {
      // Clean up all sessions after each test
      await sessionManager.closeAllSessions();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: TerminalTabBar(
            sessionManager: sessionManager,
            theme: TerminalTheme.dark(),
          ),
        ),
      );
    }

    testWidgets('renders empty state when no terminals', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify "No terminals" message is displayed
      expect(find.text('No terminals'), findsOneWidget);

      // But create button should still be present
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders create button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify create button is rendered
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('has correct height', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the main container
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TerminalTabBar),
          matching: find.byType(Container).first,
        ),
      );

      // Verify height
      expect(container.constraints?.maxHeight, 35);
    });

    testWidgets('displays tooltip on create button', (tester) async {
      await tester.pumpWidget(createTestWidget());

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

    // Note: Tests that require actual terminal creation are skipped
    // because they would require mocking PTY processes which is complex
    // and beyond the scope of widget testing. Integration tests should
    // cover the full terminal creation flow.
  });
}
