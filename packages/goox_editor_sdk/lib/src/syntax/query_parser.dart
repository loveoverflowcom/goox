import 'dart:ffi' as ffi;
import 'tree_sitter_parser.dart' as tsp;
import 'tree_sitter_bindings.dart';
import 'tree_sitter_ffi.dart';

/// Parser for Tree-sitter query files (.scm)
/// 
/// Supports parsing and executing queries from:
/// - highlights.scm: Syntax highlighting patterns
/// - brackets.scm: Bracket matching patterns
/// - indents.scm: Indentation patterns
/// - outline.scm: Code outline patterns
/// - injections.scm: Language injection patterns
class QueryParser {
  TreeSitterBindings? _bindings;
  
  QueryParser({TreeSitterBindings? bindings}) : _bindings = bindings;
  
  TreeSitterBindings get bindings {
    _bindings ??= TreeSitterBindings();
    return _bindings!;
  }
  
  /// Parse a .scm query file into a Query object
  /// 
  /// Throws [QueryParseException] if the query syntax is invalid
  ParsedQuery parse(String scmContent, tsp.Grammar grammar) {
    final result = validate(scmContent, grammar);
    
    if (!result.isValid) {
      throw QueryParseException(
        result.error!,
        line: result.errorLine,
        column: result.errorColumn,
      );
    }
    
    final tsQuery = tsp.Query.fromSource(scmContent, grammar, bindings);
    return ParsedQuery(
      query: tsQuery,
      source: scmContent,
      bindings: bindings,
    );
  }
  
  /// Validate query syntax without creating a Query object
  /// 
  /// Returns a [ValidationResult] indicating whether the query is valid
  /// and providing error details if invalid
  ValidationResult validate(String scmContent, tsp.Grammar grammar) {
    try {
      final result = bindings.createQuery(grammar.language, scmContent);
      
      if (result.isError) {
        // Calculate line and column from error offset
        final errorOffset = result.errorOffset ?? 0;
        final lines = scmContent.substring(0, errorOffset).split('\n');
        final line = lines.length;
        final column = lines.last.length + 1;
        
        return ValidationResult(
          isValid: false,
          error: _formatQueryError(result.error),
          errorLine: line,
          errorColumn: column,
          errorOffset: errorOffset,
        );
      }
      
      // Clean up the query since we're just validating
      bindings.deleteQuery(result.query!);
      
      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: 'Unexpected error during validation: $e',
      );
    }
  }
  
  /// Execute a query against a syntax tree
  /// 
  /// Returns a list of [QueryMatch] objects containing captured nodes
  List<tsp.QueryMatch> execute(ParsedQuery query, tsp.SyntaxTree tree) {
    return query.execute(tree);
  }
  
  /// Format TSQueryError into a readable error message
  String _formatQueryError(TSQueryError? error) {
    if (error == null) return 'Unknown query error';
    
    switch (error) {
      case TSQueryError.syntax:
        return 'Query syntax error';
      case TSQueryError.nodeType:
        return 'Invalid node type in query';
      case TSQueryError.field:
        return 'Invalid field name in query';
      case TSQueryError.capture:
        return 'Invalid capture name in query';
      case TSQueryError.structure:
        return 'Invalid query structure';
      case TSQueryError.language:
        return 'Query language mismatch';
      case TSQueryError.none:
        return 'No error';
    }
  }
}

/// Wrapper for a parsed Tree-sitter query
/// 
/// This class wraps the low-level Query from tree_sitter_parser.dart
/// and provides additional functionality for query execution
class ParsedQuery {
  final tsp.Query query;
  final String source;
  final TreeSitterBindings _bindings;
  
  ParsedQuery({
    required this.query,
    required this.source,
    required TreeSitterBindings bindings,
  }) : _bindings = bindings;
  
  /// Execute this query against a syntax tree
  List<tsp.QueryMatch> execute(tsp.SyntaxTree tree) {
    final cursor = _bindings.createQueryCursor();
    try {
      // Access the internal query pointer through the extension
      final queryPtr = _getQueryPointer(query);
      final rootNode = _getRootNode(tree);
      
      _bindings.executeQuery(cursor, queryPtr, rootNode);
      
      final matches = <tsp.QueryMatch>[];
      while (true) {
        final bindingsMatch = _bindings.nextMatch(cursor);
        if (bindingsMatch == null) break;
        
        final captures = <String, tsp.Node>{};
        for (final capture in bindingsMatch.captures) {
          final captureName = _bindings.getCaptureName(queryPtr, capture.index);
          captures[captureName] = _createNode(
            capture.node,
            _bindings,
            tree.sourceCode,
          );
        }
        
        matches.add(tsp.QueryMatch(
          patternIndex: bindingsMatch.patternIndex,
          captures: captures,
        ));
      }
      
      return matches;
    } finally {
      _bindings.deleteQueryCursor(cursor);
    }
  }
  
  /// Get the number of patterns in this query
  int get patternCount => _bindings.getPatternCount(_getQueryPointer(query));
  
  /// Clean up resources
  void dispose() {
    query.dispose();
  }
  
  // Helper methods to access internal properties
  ffi.Pointer<TSQuery> _getQueryPointer(tsp.Query q) {
    // Access through reflection-like approach
    // This is a workaround since we can't directly access private fields
    return (q as dynamic)._query as ffi.Pointer<TSQuery>;
  }
  
  TSNode _getRootNode(tsp.SyntaxTree tree) {
    return (tree.rootNode as dynamic)._node as TSNode;
  }
  
  tsp.Node _createNode(TSNode node, TreeSitterBindings bindings, String sourceCode) {
    // Use the factory constructor from Node
    return (tsp.Node as dynamic)._fromTSNode(node, bindings, sourceCode) as tsp.Node;
  }
}

/// Result of query validation
class ValidationResult {
  final bool isValid;
  final String? error;
  final int? errorLine;
  final int? errorColumn;
  final int? errorOffset;
  
  ValidationResult({
    required this.isValid,
    this.error,
    this.errorLine,
    this.errorColumn,
    this.errorOffset,
  });
  
  @override
  String toString() {
    if (isValid) {
      return 'ValidationResult(valid)';
    }
    return 'ValidationResult(invalid: $error at line $errorLine, column $errorColumn)';
  }
}

/// Exception thrown when query parsing fails
class QueryParseException implements Exception {
  final String message;
  final int? line;
  final int? column;
  
  QueryParseException(this.message, {this.line, this.column});
  
  @override
  String toString() {
    if (line != null && column != null) {
      return 'QueryParseException: $message at line $line, column $column';
    }
    return 'QueryParseException: $message';
  }
}
