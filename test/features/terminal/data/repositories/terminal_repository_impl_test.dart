import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/terminal/data/repositories/terminal_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late TerminalRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = TerminalRepositoryImpl();
  });

  group('TerminalRepositoryImpl', () {
    test('saveHeight and loadHeight persist correctly', () async {
      await repository.saveHeight(height: 450.0);
      final height = await repository.loadHeight();
      expect(height, 450.0);
    });

    test('loadHeight returns default value when empty', () async {
      final height = await repository.loadHeight();
      expect(height, 300.0);
    });

    test('saveTerminalCount and loadTerminalCount persist correctly', () async {
      await repository.saveTerminalCount(count: 3);
      final count = await repository.loadTerminalCount();
      expect(count, 3);
    });

    test('loadTerminalCount returns default value when empty', () async {
      final count = await repository.loadTerminalCount();
      expect(count, 1);
    });

    test('saveWorkingDirectories and loadWorkingDirectories persist correctly', () async {
      final dirs = ['/tmp', '/var/log'];
      await repository.saveWorkingDirectories(paths: dirs);
      final loadedDirs = await repository.loadWorkingDirectories();
      expect(loadedDirs, dirs);
    });

    test('loadWorkingDirectories returns default empty list', () async {
      final loadedDirs = await repository.loadWorkingDirectories();
      expect(loadedDirs, <String>[]);
    });
  });
}
