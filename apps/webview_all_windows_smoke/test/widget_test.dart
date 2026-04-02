import 'package:flutter_test/flutter_test.dart';

import 'package:webview_all_windows_smoke/app.dart';

void main() {
  test('exports the desktop smoke app widget', () {
    expect(
      const WebViewAllWindowsSmokeApp(startAutomatically: false),
      isA<WebViewAllWindowsSmokeApp>(),
    );
  });
}
