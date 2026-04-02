import 'package:flutter_test/flutter_test.dart';
import 'package:goox_desktop/src/features/editor/widgets/webview_panel.dart';

void main() {
  group('WebviewPanel', () {
    // Note: Widget tests for WebviewPanel require platform-specific webview
    // implementation and are better suited for integration tests.
    // Here we test the data models and message serialization.

    test('WebviewMessage serialization', () {
      final message = WebviewMessage(
        type: 'test',
        data: {'key': 'value'},
      );

      final json = message.toJson();
      expect(json['type'], 'test');
      expect(json['key'], 'value');

      final deserialized = WebviewMessage.fromJson(json);
      expect(deserialized.type, 'test');
      expect(deserialized.data['key'], 'value');
    });

    test('WebviewMessage fromJson', () {
      final json = {
        'type': 'fileUpdate',
        'content': 'new content',
        'extensionId': 'test-ext',
      };

      final message = WebviewMessage.fromJson(json);
      expect(message.type, 'fileUpdate');
      expect(message.data['content'], 'new content');
      expect(message.data['extensionId'], 'test-ext');
    });

    test('WebviewMessage equality', () {
      final message1 = WebviewMessage(
        type: 'test',
        data: {'key': 'value'},
      );

      final message2 = WebviewMessage(
        type: 'test',
        data: {'key': 'value'},
      );

      final message3 = WebviewMessage(
        type: 'test',
        data: {'key': 'different'},
      );

      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });

    test('WebviewMessage hashCode', () {
      final message1 = WebviewMessage(
        type: 'test',
        data: {'key': 'value'},
      );

      final message2 = WebviewMessage(
        type: 'test',
        data: {'key': 'value'},
      );

      // Hash codes should be consistent for equal objects
      expect(message1 == message2, isTrue);
      // Note: We don't test exact hashCode values as they may vary,
      // but equal objects should have equal hashCodes
      expect(message1.hashCode == message2.hashCode, isTrue);
    });
  });
}
