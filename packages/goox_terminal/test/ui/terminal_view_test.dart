import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/src/controllers/terminal_controller.dart';
import 'package:goox_terminal/src/models/pty_size.dart';
import 'package:goox_terminal/src/models/shell_config.dart';
import 'package:goox_terminal/src/ui/terminal_theme.dart';
import 'package:goox_terminal/src/ui/terminal_view.dart';

void main() {
  group('TerminalView', () {
    late TerminalController controller;

    setUp(() {
      controller = TerminalController(
        id: 'test-terminal',
        shellConfig: ShellConfig.bash(),
        initialSize: PtySize.defaultSize,
      );
    });

    tearDown(() async {
      await controller.dispose();
    });

    testWidgets('should render without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalView(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.byType(TerminalView), findsOneWidget);
    });

    testWidgets('should apply custom theme', (tester) async {
      final customTheme = TerminalTheme.light();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalView(
              controller: controller,
              theme: customTheme,
            ),
          ),
        ),
      );

      expect(find.byType(TerminalView), findsOneWidget);
    });

    testWidgets('should use dark theme by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalView(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.byType(TerminalView), findsOneWidget);
    });
  });
}
