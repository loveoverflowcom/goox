import 'package:flutter_test/flutter_test.dart';
import 'package:goox_terminal/src/controllers/terminal_controller.dart';
import 'package:goox_terminal/src/models/pty_signal.dart';
import 'package:goox_terminal/src/models/pty_size.dart';
import 'package:goox_terminal/src/models/shell_config.dart';
import 'package:goox_terminal/src/models/terminal_status.dart';

void main() {
  group('TerminalController.kill()', () {
    late TerminalController controller;

    setUp(() {
      controller = TerminalController(
        id: 'test-terminal',
        shellConfig: ShellConfig.bash(),
        initialSize: PtySize.defaultSize,
      );
    });

    test('should throw StateError when terminal is not running', () {
      // Controller is in initializing state, not running
      expect(
        () => controller.kill(),
        throwsA(isA<StateError>()),
      );
    });

    test('should throw StateError with descriptive message when not running',
        () async {
      // Controller is in initializing state
      try {
        await controller.kill();
        fail('Expected StateError to be thrown');
      } catch (e) {
        expect(e, isA<StateError>());
        expect(
          e.toString(),
          contains('Cannot kill terminal: terminal is not running'),
        );
        expect(e.toString(), contains('initializing'));
      }
    });

    test('should accept SIGTERM signal (default)', () {
      // Even though terminal is not running, the method should accept the signal
      // and throw StateError about status, not about invalid signal
      expect(
        () => controller.kill(PtySignal.sigterm),
        throwsA(
          isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot kill terminal: terminal is not running'),
          ),
        ),
      );
    });

    test('should accept SIGKILL signal', () {
      expect(
        () => controller.kill(PtySignal.sigkill),
        throwsA(
          isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot kill terminal: terminal is not running'),
          ),
        ),
      );
    });

    test('should accept SIGINT signal', () {
      expect(
        () => controller.kill(PtySignal.sigint),
        throwsA(
          isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot kill terminal: terminal is not running'),
          ),
        ),
      );
    });

    test('should accept SIGHUP signal', () {
      expect(
        () => controller.kill(PtySignal.sighup),
        throwsA(
          isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot kill terminal: terminal is not running'),
          ),
        ),
      );
    });

    test('should accept SIGQUIT signal', () {
      expect(
        () => controller.kill(PtySignal.sigquit),
        throwsA(
          isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot kill terminal: terminal is not running'),
          ),
        ),
      );
    });

    test('should use SIGTERM as default signal', () {
      // Calling kill() without arguments should use SIGTERM
      // We verify this by checking it doesn't throw an argument error
      expect(
        () => controller.kill(),
        throwsA(
          isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot kill terminal: terminal is not running'),
          ),
        ),
      );
    });

    test('should be implemented (not throw UnimplementedError)', () {
      // Verify that kill() is implemented
      expect(
        () => controller.kill(),
        throwsA(isNot(isA<UnimplementedError>())),
      );
    });

    test('should throw StateError when status is exited', () async {
      // Dispose the controller to set status to exited
      await controller.dispose();
      expect(controller.status, equals(TerminalStatus.exited));

      // Now try to kill it
      expect(
        () => controller.kill(),
        throwsA(
          isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot kill terminal: terminal is not running'),
          ),
        ),
      );
    });
  });
}
