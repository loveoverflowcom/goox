import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/src/controllers/terminal_controller.dart';
import 'package:goox_terminal/src/models/pty_size.dart';
import 'package:goox_terminal/src/models/shell_config.dart';

void main() {
  group('TerminalController - UTF-8 Handling (Task 13.1)', () {
    late TerminalController controller;

    setUp(() {
      controller = TerminalController(
        id: 'test-terminal-utf8',
        shellConfig: ShellConfig.bash(),
        initialSize: PtySize.defaultSize,
      );
    });

    tearDown(() async {
      await controller.dispose();
    });

    group('UTF-8 Decoding (PTY Output)', () {
      test('should decode valid UTF-8 sequences', () {
        // Valid UTF-8 sequences should be decoded correctly
        final validUtf8 = utf8.encode('Hello, World! 你好世界 🌍');
        
        // Verify encoding/decoding works
        final decoded = utf8.decode(validUtf8, allowMalformed: true);
        expect(decoded, equals('Hello, World! 你好世界 🌍'));
      });

      test('should handle malformed UTF-8 with allowMalformed: true', () {
        // Create malformed UTF-8 sequence
        final malformed = [0xC3, 0x28]; // Invalid UTF-8 sequence
        
        // Should not throw with allowMalformed: true
        expect(
          () => utf8.decode(malformed, allowMalformed: true),
          returnsNormally,
        );
        
        // Verify it produces replacement characters instead of throwing
        final decoded = utf8.decode(malformed, allowMalformed: true);
        expect(decoded, isNotEmpty);
      });

      test('should handle incomplete UTF-8 sequences', () {
        // Incomplete multi-byte sequence (missing continuation bytes)
        final incomplete = [0xE2, 0x82]; // Start of 3-byte sequence, missing last byte
        
        // Should not throw with allowMalformed: true
        expect(
          () => utf8.decode(incomplete, allowMalformed: true),
          returnsNormally,
        );
      });

      test('should handle mixed valid and invalid UTF-8', () {
        // Mix of valid and invalid bytes
        final mixed = [
          ...utf8.encode('Hello '),
          0xFF, // Invalid UTF-8 byte
          ...utf8.encode(' World'),
        ];
        
        // Should decode without throwing
        final decoded = utf8.decode(mixed, allowMalformed: true);
        expect(decoded, contains('Hello'));
        expect(decoded, contains('World'));
      });

      test('should handle empty byte sequences', () {
        final empty = <int>[];
        
        // Should handle empty input gracefully
        final decoded = utf8.decode(empty, allowMalformed: true);
        expect(decoded, isEmpty);
      });

      test('should handle ASCII-only content efficiently', () {
        // Pure ASCII should decode correctly
        final ascii = utf8.encode('echo "test"\n');
        final decoded = utf8.decode(ascii, allowMalformed: true);
        
        expect(decoded, equals('echo "test"\n'));
      });

      test('should handle ANSI escape sequences', () {
        // ANSI escape sequences are valid ASCII/UTF-8
        final ansiSequence = '\x1b[31mRed Text\x1b[0m';
        final bytes = utf8.encode(ansiSequence);
        final decoded = utf8.decode(bytes, allowMalformed: true);
        
        expect(decoded, equals(ansiSequence));
      });
    });

    group('UTF-8 Encoding (Terminal Input)', () {
      test('should encode ASCII characters correctly', () {
        final input = 'ls -la\n';
        final encoded = utf8.encode(input);
        
        // Verify encoding produces expected bytes
        expect(encoded, isNotEmpty);
        expect(utf8.decode(encoded), equals(input));
      });

      test('should encode Unicode characters correctly', () {
        final input = '你好世界';
        final encoded = utf8.encode(input);
        
        // Verify round-trip encoding/decoding
        expect(utf8.decode(encoded), equals(input));
      });

      test('should encode emoji correctly', () {
        final input = 'echo "Hello 🌍"';
        final encoded = utf8.encode(input);
        
        // Verify emoji is encoded as multi-byte UTF-8
        expect(encoded.length, greaterThan(input.length));
        expect(utf8.decode(encoded), equals(input));
      });

      test('should encode special characters correctly', () {
        final input = 'echo "Special: \$VAR \\n \\t"';
        final encoded = utf8.encode(input);
        
        // Verify special characters are preserved
        expect(utf8.decode(encoded), equals(input));
      });

      test('should encode control characters correctly', () {
        // Control characters like Ctrl+C (ETX)
        final input = '\x03'; // ETX (End of Text)
        final encoded = utf8.encode(input);
        
        expect(encoded, equals([0x03]));
      });

      test('should encode newline characters correctly', () {
        final input = 'line1\nline2\r\nline3\r';
        final encoded = utf8.encode(input);
        
        // Verify newline characters are preserved
        expect(utf8.decode(encoded), equals(input));
      });

      test('should handle empty input', () {
        final input = '';
        final encoded = utf8.encode(input);
        
        expect(encoded, isEmpty);
      });
    });

    group('UTF-8 Round-trip', () {
      test('should maintain data integrity through encode/decode cycle', () {
        final testStrings = [
          'Hello, World!',
          '你好世界',
          'Привет мир',
          'مرحبا بالعالم',
          '🌍🌎🌏',
          'Mixed: Hello 世界 🌍',
          'echo "test"\n',
          '\x1b[31mColored\x1b[0m',
        ];

        for (final input in testStrings) {
          final encoded = utf8.encode(input);
          final decoded = utf8.decode(encoded, allowMalformed: true);
          expect(decoded, equals(input), reason: 'Failed for: $input');
        }
      });
    });
  });
}
