import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_ui_shared/goox_ui_shared.dart';

void main() {
  testWidgets('renders shared status bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GooxStatusBar(revision: 3, line: 7, column: 12)),
      ),
    );

    expect(find.text('rev:3'), findsOneWidget);
    expect(find.text('Ln 7, Col 12'), findsOneWidget);
  });
}
