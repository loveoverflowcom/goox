import 'dart:convert';

import 'textmate_grammar.dart';

class TextMateParser {
  const TextMateParser();

  TextMateGrammar parse(String jsonContent) {
    final validation = validate(jsonContent);
    if (!validation.isValid) {
      throw FormatException(validation.errors.join('\n'));
    }

    final decoded = jsonDecode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('TextMate grammar must be a JSON object.');
    }

    return _grammarFromMap(decoded);
  }

  TextMateValidationResult validate(String jsonContent) {
    final errors = <String>[];

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonContent);
    } on FormatException catch (error) {
      return TextMateValidationResult.invalid([error.message]);
    } catch (error) {
      return TextMateValidationResult.invalid(['Invalid JSON: $error']);
    }

    if (decoded is! Map<String, dynamic>) {
      errors.add('TextMate grammar must be a JSON object.');
      return TextMateValidationResult.invalid(errors);
    }

    final scopeName = _asTrimmedString(decoded['scopeName']);
    if (scopeName == null) {
      errors.add('Missing required "scopeName" field.');
    }

    final patterns = decoded['patterns'];
    if (patterns != null && patterns is! List) {
      errors.add('"patterns" must be a JSON array when present.');
    }

    final repository = decoded['repository'];
    if (repository != null && repository is! Map) {
      errors.add('"repository" must be a JSON object when present.');
    }

    return errors.isEmpty
        ? const TextMateValidationResult.valid()
        : TextMateValidationResult.invalid(errors);
  }

  TextMateGrammar _grammarFromMap(Map<String, dynamic> json) {
    final scopeName = _asTrimmedString(json['scopeName']);
    if (scopeName == null) {
      throw const FormatException('Missing required "scopeName" field.');
    }

    final patterns = _parsePatternList(json['patterns']);
    final repository = _parsePatternMap(json['repository']);
    final fileTypes = _parseStringList(json['fileTypes'] ?? json['filetypes']);

    return TextMateGrammar(
      scopeName: scopeName,
      name: _asTrimmedString(json['name']),
      fileTypes: fileTypes,
      patterns: patterns,
      repository: repository,
    );
  }

  List<TextMatePattern> _parsePatternList(dynamic raw) {
    if (raw == null) {
      return const [];
    }

    if (raw is! List) {
      throw const FormatException('"patterns" must be an array.');
    }

    return raw
        .whereType<Map>()
        .map((entry) => _parsePattern(_asObject(entry)))
        .toList(growable: false);
  }

  Map<String, TextMatePattern> _parsePatternMap(dynamic raw) {
    if (raw == null) {
      return const {};
    }

    if (raw is! Map) {
      throw const FormatException('"repository" must be an object.');
    }

    final result = <String, TextMatePattern>{};
    raw.forEach((key, value) {
      if (key is! String || value is! Map) {
        return;
      }
      result[key] = _parsePattern(_asObject(value));
    });
    return result;
  }

  TextMatePattern _parsePattern(Map<String, dynamic> json) {
    return TextMatePattern(
      name: _asTrimmedString(json['name']),
      match: _asTrimmedString(json['match']),
      begin: _asTrimmedString(json['begin']),
      end: _asTrimmedString(json['end']),
      include: _asTrimmedString(json['include']),
      captures: _parseCaptureMap(json['captures']),
      beginCaptures: _parseCaptureMap(json['beginCaptures']),
      endCaptures: _parseCaptureMap(json['endCaptures']),
      patterns: json['patterns'] is List
          ? _parsePatternList(json['patterns'])
          : null,
    );
  }

  Map<String, TextMateCapture>? _parseCaptureMap(dynamic raw) {
    if (raw == null) {
      return null;
    }

    if (raw is! Map) {
      return null;
    }

    final result = <String, TextMateCapture>{};
    raw.forEach((key, value) {
      if (key is! String || value is! Map) {
        return;
      }

      final captureMap = _asObject(value);
      final name = _asTrimmedString(captureMap['name']);
      if (name == null) {
        return;
      }

      result[key] = TextMateCapture(
        name: name,
        patterns: captureMap['patterns'] is List
            ? _parsePatternList(captureMap['patterns'])
            : null,
      );
    });

    return result;
  }

  List<String> _parseStringList(dynamic raw) {
    if (raw == null) {
      return const [];
    }

    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  String? _asTrimmedString(dynamic value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> _asObject(Map value) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
}
