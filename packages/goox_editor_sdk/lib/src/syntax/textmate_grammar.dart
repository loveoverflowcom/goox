import 'package:flutter/foundation.dart';

@immutable
class TextMateGrammar {
  const TextMateGrammar({
    required this.scopeName,
    required this.patterns,
    required this.repository,
    this.name,
    this.fileTypes = const [],
  });

  final String scopeName;
  final String? name;
  final List<String> fileTypes;
  final List<TextMatePattern> patterns;
  final Map<String, TextMatePattern> repository;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null && name!.trim().isNotEmpty) 'name': name,
      'scopeName': scopeName,
      if (fileTypes.isNotEmpty) 'fileTypes': fileTypes,
      'patterns': patterns.map((pattern) => pattern.toJson()).toList(),
      if (repository.isNotEmpty)
        'repository': repository.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
    };
  }
}

@immutable
class TextMatePattern {
  const TextMatePattern({
    this.name,
    this.match,
    this.begin,
    this.end,
    this.captures,
    this.beginCaptures,
    this.endCaptures,
    this.patterns,
    this.include,
  });

  final String? name;
  final String? match;
  final String? begin;
  final String? end;
  final Map<String, TextMateCapture>? captures;
  final Map<String, TextMateCapture>? beginCaptures;
  final Map<String, TextMateCapture>? endCaptures;
  final List<TextMatePattern>? patterns;
  final String? include;

  bool get isBeginEnd => begin != null && end != null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null && name!.trim().isNotEmpty) 'name': name,
      if (match != null && match!.trim().isNotEmpty) 'match': match,
      if (begin != null && begin!.trim().isNotEmpty) 'begin': begin,
      if (end != null && end!.trim().isNotEmpty) 'end': end,
      if (captures != null && captures!.isNotEmpty)
        'captures': captures!.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      if (beginCaptures != null && beginCaptures!.isNotEmpty)
        'beginCaptures': beginCaptures!.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      if (endCaptures != null && endCaptures!.isNotEmpty)
        'endCaptures': endCaptures!.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      if (patterns != null && patterns!.isNotEmpty)
        'patterns': patterns!.map((pattern) => pattern.toJson()).toList(),
      if (include != null && include!.trim().isNotEmpty) 'include': include,
    };
  }
}

@immutable
class TextMateCapture {
  const TextMateCapture({required this.name, this.patterns});

  final String name;
  final List<TextMatePattern>? patterns;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      if (patterns != null && patterns!.isNotEmpty)
        'patterns': patterns!.map((pattern) => pattern.toJson()).toList(),
    };
  }
}

@immutable
class TextMateValidationResult {
  const TextMateValidationResult({required this.isValid, required this.errors});

  final bool isValid;
  final List<String> errors;

  const TextMateValidationResult.valid() : isValid = true, errors = const [];

  const TextMateValidationResult.invalid(this.errors) : isValid = false;
}
