import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox_editor_sdk/src/syntax/language_config_parser.dart';
import 'package:path/path.dart' as path;

void main() {
  group('LanguageConfigParser Integration Tests', () {
    late LanguageConfigParser parser;

    setUp(() {
      parser = LanguageConfigParser();
    });

    test('parses real Dart config.toml', () {
      final configPath = path.join(
        Directory.current.path,
        '..',
        '..',
        'new_extensions',
        'dart',
        'languages',
        'dart',
        'config.toml',
      );

      final file = File(configPath);
      if (!file.existsSync()) {
        // Skip if file doesn't exist (e.g., in CI)
        return;
      }

      final content = file.readAsStringSync();
      final config = parser.parse(content);

      expect(config.name, 'Dart');
      expect(config.grammar, 'dart');
      expect(config.pathSuffixes, contains('dart'));
      expect(config.lineComments, isNotEmpty);
      expect(config.brackets, isNotEmpty);
      expect(config.autocloseBefore, isNotEmpty);
    });

    test('parses real Lua config.toml', () {
      final configPath = path.join(
        Directory.current.path,
        '..',
        '..',
        'new_extensions',
        'lua',
        'languages',
        'lua',
        'config.toml',
      );

      final file = File(configPath);
      if (!file.existsSync()) {
        // Skip if file doesn't exist (e.g., in CI)
        return;
      }

      final content = file.readAsStringSync();
      final config = parser.parse(content);

      expect(config.name, 'Lua');
      expect(config.grammar, 'lua');
      expect(config.pathSuffixes, contains('lua'));
      expect(config.lineComments, isNotEmpty);
      expect(config.blockComment, isNotNull);
      expect(config.collapsedPlaceholder, isNotNull);
      expect(config.increaseIndentPattern, isNotNull);
      expect(config.decreaseIndentPattern, isNotNull);
    });

    test('parses real EmmyLuadoc config.toml', () {
      final configPath = path.join(
        Directory.current.path,
        '..',
        '..',
        'new_extensions',
        'lua',
        'languages',
        'emmyluadoc',
        'config.toml',
      );

      final file = File(configPath);
      if (!file.existsSync()) {
        // Skip if file doesn't exist (e.g., in CI)
        return;
      }

      final content = file.readAsStringSync();
      final config = parser.parse(content);

      expect(config.name, 'EmmyLuadoc');
      expect(config.grammar, 'emmyluadoc');
      expect(config.hidden, true);
    });
  });
}
