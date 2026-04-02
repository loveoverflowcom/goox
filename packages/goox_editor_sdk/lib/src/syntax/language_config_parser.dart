import 'package:toml/toml.dart';

/// Parser for language configuration files (config.toml)
///
/// Parses TOML configuration files that define language-specific editor
/// behavior such as brackets, comments, and indentation rules.
class LanguageConfigParser {
  /// Parse a config.toml file content
  ///
  /// Throws [FormatException] if the TOML is invalid or missing required fields.
  LanguageConfig parse(String tomlContent) {
    final document = TomlDocument.parse(tomlContent);
    final data = document.toMap();

    // Extract required fields
    final name = data['name'] as String?;
    if (name == null) {
      throw FormatException('Missing required field: name');
    }

    final grammar = data['grammar'] as String?;
    if (grammar == null) {
      throw FormatException('Missing required field: grammar');
    }

    // Extract optional fields with defaults
    final pathSuffixes = _parseStringList(data['path_suffixes']) ?? [];
    final lineComments = _parseStringList(data['line_comments']) ?? [];
    final blockComment = _parseStringList(data['block_comment']);
    final autocloseBefore = data['autoclose_before'] as String? ?? '';
    final collapsedPlaceholder = data['collapsed_placeholder'] as String?;
    final increaseIndentPattern = data['increase_indent_pattern'] as String?;
    final decreaseIndentPattern = data['decrease_indent_pattern'] as String?;
    final hidden = data['hidden'] as bool? ?? false;

    // Parse brackets array
    final brackets = _parseBrackets(data['brackets']);

    return LanguageConfig(
      name: name,
      grammar: grammar,
      pathSuffixes: pathSuffixes,
      lineComments: lineComments,
      blockComment: blockComment,
      autocloseBefore: autocloseBefore,
      brackets: brackets,
      collapsedPlaceholder: collapsedPlaceholder,
      increaseIndentPattern: increaseIndentPattern,
      decreaseIndentPattern: decreaseIndentPattern,
      hidden: hidden,
    );
  }

  /// Validate configuration without fully parsing
  ///
  /// Returns null if valid, or an error message if invalid.
  /// 
  /// If [availableGrammars] is provided, validates that the referenced
  /// grammar name exists in the list.
  String? validate(String tomlContent, {List<String>? availableGrammars}) {
    try {
      final config = parse(tomlContent);
      
      // Validate grammar name if list provided
      if (availableGrammars != null && 
          !availableGrammars.contains(config.grammar)) {
        return 'Referenced grammar "${config.grammar}" does not exist';
      }
      
      return null;
    } on FormatException catch (e) {
      return e.message;
    } catch (e) {
      return 'Invalid TOML format: $e';
    }
  }

  List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  List<BracketPair> _parseBrackets(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    final brackets = <BracketPair>[];
    for (final item in value) {
      if (item is! Map) continue;

      final start = item['start'] as String?;
      final end = item['end'] as String?;
      if (start == null || end == null) continue;

      final close = item['close'] as bool? ?? true;
      final newline = item['newline'] as bool? ?? false;
      final notIn = _parseStringList(item['not_in']);

      brackets.add(BracketPair(
        start: start,
        end: end,
        close: close,
        newline: newline,
        notIn: notIn,
      ));
    }

    return brackets;
  }
}

/// Language configuration defining editor behavior for a specific language
class LanguageConfig {
  /// Display name of the language
  final String name;

  /// Tree-sitter grammar name
  final String grammar;

  /// File extensions associated with this language
  final List<String> pathSuffixes;

  /// Line comment prefixes (e.g., ["// ", "/// "])
  final List<String> lineComments;

  /// Block comment delimiters [start, end] (e.g., ["/*", "*/"])
  final List<String>? blockComment;

  /// Characters before which auto-closing brackets should trigger
  final String autocloseBefore;

  /// Bracket pairs for auto-closing and matching
  final List<BracketPair> brackets;

  /// Placeholder text for collapsed code blocks
  final String? collapsedPlaceholder;

  /// Regex pattern for lines that should increase indentation
  final String? increaseIndentPattern;

  /// Regex pattern for lines that should decrease indentation
  final String? decreaseIndentPattern;

  /// Whether this language should be hidden from language selection
  final bool hidden;

  const LanguageConfig({
    required this.name,
    required this.grammar,
    required this.pathSuffixes,
    required this.lineComments,
    this.blockComment,
    required this.autocloseBefore,
    required this.brackets,
    this.collapsedPlaceholder,
    this.increaseIndentPattern,
    this.decreaseIndentPattern,
    this.hidden = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageConfig &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          grammar == other.grammar &&
          _listEquals(pathSuffixes, other.pathSuffixes) &&
          _listEquals(lineComments, other.lineComments) &&
          _listEquals(blockComment, other.blockComment) &&
          autocloseBefore == other.autocloseBefore &&
          _listEquals(brackets, other.brackets) &&
          collapsedPlaceholder == other.collapsedPlaceholder &&
          increaseIndentPattern == other.increaseIndentPattern &&
          decreaseIndentPattern == other.decreaseIndentPattern &&
          hidden == other.hidden;

  @override
  int get hashCode =>
      name.hashCode ^
      grammar.hashCode ^
      pathSuffixes.hashCode ^
      lineComments.hashCode ^
      (blockComment?.hashCode ?? 0) ^
      autocloseBefore.hashCode ^
      brackets.hashCode ^
      (collapsedPlaceholder?.hashCode ?? 0) ^
      (increaseIndentPattern?.hashCode ?? 0) ^
      (decreaseIndentPattern?.hashCode ?? 0) ^
      hidden.hashCode;

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A pair of bracket characters for auto-closing and matching
class BracketPair {
  /// Opening bracket character(s)
  final String start;

  /// Closing bracket character(s)
  final String end;

  /// Whether to auto-close this bracket pair
  final bool close;

  /// Whether to insert a newline between brackets
  final bool newline;

  /// Contexts where this bracket should not auto-close (e.g., ["string", "comment"])
  final List<String>? notIn;

  const BracketPair({
    required this.start,
    required this.end,
    required this.close,
    required this.newline,
    this.notIn,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BracketPair &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          close == other.close &&
          newline == other.newline &&
          _listEquals(notIn, other.notIn);

  @override
  int get hashCode =>
      start.hashCode ^
      end.hashCode ^
      close.hashCode ^
      newline.hashCode ^
      (notIn?.hashCode ?? 0);

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
