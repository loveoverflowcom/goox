import 'package:flutter_test/flutter_test.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';

void main() {
  group('WasmClient', () {
    late WasmClient client;

    setUp(() {
      client = WasmClient();
    });

    test('creates WasmClient instance', () {
      expect(client, isNotNull);
      expect(client, isA<WasmClient>());
    });

    test('WasmEdit has correct properties', () {
      final edit = WasmEdit(
        startByte: 0,
        oldEndByte: 5,
        newEndByte: 10,
      );

      expect(edit.startByte, equals(0));
      expect(edit.oldEndByte, equals(5));
      expect(edit.newEndByte, equals(10));
    });

    test('WasmEventType enum has all event types', () {
      expect(WasmEventType.values, hasLength(4));
      expect(WasmEventType.values, contains(WasmEventType.fileOpened));
      expect(WasmEventType.values, contains(WasmEventType.fileSaved));
      expect(WasmEventType.values, contains(WasmEventType.fileEdited));
      expect(WasmEventType.values, contains(WasmEventType.fileClosed));
    });

    // Note: Integration tests with actual WASM modules would require
    // a test WASM binary and proper initialization of the Rust bridge.
    // These tests verify the API structure and types.
  });
}
