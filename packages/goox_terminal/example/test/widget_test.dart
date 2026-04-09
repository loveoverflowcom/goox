import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal_example/main.dart';

void main() {
  testWidgets('creates and displays terminal manager app', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const TerminalManagerApp(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Goox Terminal'), findsOneWidget);
    expect(find.text('New terminal'), findsOneWidget);
    expect(find.text('No sessions yet'), findsOneWidget);
  });

  testWidgets('shows empty state when no sessions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TerminalManagerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No sessions yet'), findsOneWidget);
    expect(
      find.text(
        'Create a terminal to spawn a shell process and start sending commands.',
      ),
      findsOneWidget,
    );
    expect(find.text('Create terminal'), findsOneWidget);
  });

  testWidgets('displays session count chip', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TerminalManagerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 open'), findsOneWidget);
  });
}
