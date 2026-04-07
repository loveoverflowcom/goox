import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/src/models/terminal_status.dart';

void main() {
  group('TerminalStatus', () {
    group('enum values', () {
      test('has initializing state', () {
        expect(TerminalStatus.initializing, isNotNull);
      });

      test('has running state', () {
        expect(TerminalStatus.running, isNotNull);
      });

      test('has exited state', () {
        expect(TerminalStatus.exited, isNotNull);
      });

      test('has error state', () {
        expect(TerminalStatus.error, isNotNull);
      });

      test('has exactly 4 values', () {
        expect(TerminalStatus.values.length, equals(4));
      });
    });

    group('isActive', () {
      test('returns true only for running status', () {
        expect(TerminalStatus.running.isActive, isTrue);
        expect(TerminalStatus.initializing.isActive, isFalse);
        expect(TerminalStatus.exited.isActive, isFalse);
        expect(TerminalStatus.error.isActive, isFalse);
      });
    });

    group('canSendInput', () {
      test('returns true only for running status', () {
        expect(TerminalStatus.running.canSendInput, isTrue);
        expect(TerminalStatus.initializing.canSendInput, isFalse);
        expect(TerminalStatus.exited.canSendInput, isFalse);
        expect(TerminalStatus.error.canSendInput, isFalse);
      });
    });

    group('status transitions', () {
      test('typical lifecycle: initializing -> running -> exited', () {
        var status = TerminalStatus.initializing;
        expect(status.isActive, isFalse);
        expect(status.canSendInput, isFalse);

        status = TerminalStatus.running;
        expect(status.isActive, isTrue);
        expect(status.canSendInput, isTrue);

        status = TerminalStatus.exited;
        expect(status.isActive, isFalse);
        expect(status.canSendInput, isFalse);
      });

      test('error lifecycle: initializing -> running -> error', () {
        var status = TerminalStatus.initializing;
        expect(status.isActive, isFalse);

        status = TerminalStatus.running;
        expect(status.isActive, isTrue);

        status = TerminalStatus.error;
        expect(status.isActive, isFalse);
        expect(status.canSendInput, isFalse);
      });
    });
  });
}
