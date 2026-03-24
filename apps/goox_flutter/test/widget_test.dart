import 'package:flutter_test/flutter_test.dart';

import 'package:goox_flutter/src/app/app.dart';

void main() {
  testWidgets('renders architecture demo shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Goox Editor Architecture Demo'), findsOneWidget);
    expect(find.text('Flutter shell'), findsOneWidget);
    expect(find.text('Rust core'), findsOneWidget);
  });
}
