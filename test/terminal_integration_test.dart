import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/goox_terminal.dart';

/// Integration test for terminal functionality
///
/// This test verifies:
/// - Terminal widget can be created and rendered
/// - Terminal controller can be accessed
/// - Terminal can write and paste text
void main() {
  group('Terminal Integration Tests', () {
    testWidgets('GooxTerminal can be rendered', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GooxTerminal(),
          ),
        ),
      );

      // Wait for widget to build
      await tester.pump();

      // Verify terminal widget is rendered
      expect(find.byType(GooxTerminal), findsOneWidget);
    });

    testWidgets('GooxTerminal with custom configuration', (tester) async {
      GooxTerminalController? controller;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GooxTerminal(
              maxLines: 5000,
              autofocus: false,
              backgroundOpacity: 0.5,
              onTerminalReady: (ctrl) {
                controller = ctrl;
              },
            ),
          ),
        ),
      );

      // Wait for terminal to be ready
      await tester.pumpAndSettle();

      // Verify controller is available
      expect(controller, isNotNull);
    });

    testWidgets('Terminal controller can write text', (tester) async {
      GooxTerminalController? controller;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GooxTerminal(
              onTerminalReady: (ctrl) {
                controller = ctrl;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Write text to terminal
      controller?.write('Hello Terminal\n');
      await tester.pump();

      // Verify no errors occurred
      expect(controller, isNotNull);
    });

    testWidgets('Terminal controller can paste text', (tester) async {
      GooxTerminalController? controller;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GooxTerminal(
              onTerminalReady: (ctrl) {
                controller = ctrl;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Paste text to terminal
      controller?.paste('Pasted text');
      await tester.pump();

      // Verify no errors occurred
      expect(controller, isNotNull);
    });

    testWidgets('Terminal controller can clear selection', (tester) async {
      GooxTerminalController? controller;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GooxTerminal(
              onTerminalReady: (ctrl) {
                controller = ctrl;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clear selection
      controller?.clearSelection();
      await tester.pump();

      // Verify no errors occurred
      expect(controller, isNotNull);
    });
  });
}
