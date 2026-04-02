import 'dart:convert';

import 'textmate_grammar.dart';
import 'textmate_parser.dart';

class TextMatePrinter {
  const TextMatePrinter();

  String print(TextMateGrammar grammar, {int indent = 2}) {
    return JsonEncoder.withIndent(' ' * indent).convert(grammar.toJson());
  }

  bool validateRoundTrip(TextMateGrammar grammar) {
    try {
      final json = print(grammar);
      final reparsed = const TextMateParser().parse(json);
      return jsonEncode(reparsed.toJson()) == jsonEncode(grammar.toJson());
    } catch (_) {
      return false;
    }
  }
}
