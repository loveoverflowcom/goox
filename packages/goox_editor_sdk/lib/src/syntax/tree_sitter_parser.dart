import 'dart:ffi' as ffi;
import 'tree_sitter_bindings.dart';
import 'tree_sitter_ffi.dart';

/// High-level Tree-sitter parser for parsing code and generating syntax trees
class TreeSitterParser {
  final TreeSitterBindings _bindings;
  ffi.Pointer<TSParser>? _parser;
  final Map<String, Grammar> _loadedGrammars = {};
  
  // Cache for parse trees keyed by (code hash, grammar name)
  final Map<String, SyntaxTree> _parseTreeCache = {};
  static const int _maxCacheSize = 50;
  
  TreeSitterParser({TreeSitterBindings? bindings})
      : _bindings = bindings ?? TreeSitterBindings();
  
  /// Load a Tree-sitter grammar by name
  Future<Grammar> loadGrammar(String grammarName) async {
    // Check if already loaded
    if (_loadedGrammars.containsKey(grammarName)) {
      return _loadedGrammars[grammarName]!;
    }
    
    try {
      final language = _bindings.loadLanguage(grammarName);
      final grammar = Grammar(
        name: grammarName,
        language: language,
      );
      
      _loadedGrammars[grammarName] = grammar;
      return grammar;
    } catch (e) {
      throw GrammarLoadException(
        'Failed to load grammar "$grammarName": $e',
      );
    }
  }
  
  /// Parse code into a syntax tree
  SyntaxTree parse(String code, Grammar grammar) {
    _ensureParser();
    
    // Check cache first
    final cacheKey = '${code.hashCode}_${grammar.name}';
    if (_parseTreeCache.containsKey(cacheKey)) {
      return _parseTreeCache[cacheKey]!;
    }
    
    // Set the language for the parser
    final success = _bindings.setLanguage(_parser!, grammar.language);
    if (!success) {
      throw ParseException('Failed to set language for grammar "${grammar.name}"');
    }
    
    // Parse the code
    final tree = _bindings.parseString(_parser!, null, code);
    if (tree == ffi.nullptr) {
      throw ParseException('Failed to parse code');
    }
    
    final rootNode = _bindings.getRootNode(tree);
    
    final syntaxTree = SyntaxTree(
      rootNode: Node._fromTSNode(rootNode, _bindings, code),
      language: grammar.name,
      tree: tree,
      bindings: _bindings,
      sourceCode: code,
    );
    
    // Cache the result
    _cacheParseTree(cacheKey, syntaxTree);
    
    return syntaxTree;
  }
  
  /// Incrementally update syntax tree after edit
  SyntaxTree updateTree(SyntaxTree oldTree, Edit edit, String newCode) {
    _ensureParser();
    
    // Check cache first
    final cacheKey = '${newCode.hashCode}_${oldTree.language}';
    if (_parseTreeCache.containsKey(cacheKey)) {
      return _parseTreeCache[cacheKey]!;
    }
    
    // Apply edit to the old tree
    _bindings.editTree(oldTree._tree, edit._toTreeSitterEdit());
    
    // Re-parse with the edited tree (incremental parsing)
    final newTree = _bindings.parseString(_parser!, oldTree._tree, newCode);
    if (newTree == ffi.nullptr) {
      throw ParseException('Failed to update tree after edit');
    }
    
    final rootNode = _bindings.getRootNode(newTree);
    
    final syntaxTree = SyntaxTree(
      rootNode: Node._fromTSNode(rootNode, _bindings, newCode),
      language: oldTree.language,
      tree: newTree,
      bindings: _bindings,
      sourceCode: newCode,
    );
    
    // Cache the result
    _cacheParseTree(cacheKey, syntaxTree);
    
    return syntaxTree;
  }
  
  /// Cache a parse tree with LRU eviction
  void _cacheParseTree(String key, SyntaxTree tree) {
    if (_parseTreeCache.length >= _maxCacheSize) {
      // Remove oldest entry (simple FIFO for now)
      final firstKey = _parseTreeCache.keys.first;
      _parseTreeCache.remove(firstKey);
    }
    _parseTreeCache[key] = tree;
  }
  
  /// Clear the parse tree cache
  void clearCache() {
    _parseTreeCache.clear();
  }
  
  /// Query syntax tree with Tree-sitter query
  List<QueryMatch> query(SyntaxTree tree, Query query) {
    final cursor = _bindings.createQueryCursor();
    try {
      _bindings.executeQuery(cursor, query._query, tree.rootNode._node);
      
      final matches = <QueryMatch>[];
      while (true) {
        final match = _bindings.nextMatch(cursor);
        if (match == null) break;
        
        final captures = <String, Node>{};
        for (final capture in match.captures) {
          final captureName = _bindings.getCaptureName(query._query, capture.index);
          captures[captureName] = Node._fromTSNode(
            capture.node,
            _bindings,
            tree.sourceCode,
          );
        }
        
        matches.add(QueryMatch(
          patternIndex: match.patternIndex,
          captures: captures,
        ));
      }
      
      return matches;
    } finally {
      _bindings.deleteQueryCursor(cursor);
    }
  }
  
  void _ensureParser() {
    _parser ??= _bindings.createParser();
  }
  
  /// Clean up resources
  void dispose() {
    if (_parser != null) {
      _bindings.deleteParser(_parser!);
      _parser = null;
    }
    clearCache();
  }
}

/// Represents a loaded Tree-sitter grammar
class Grammar {
  final String name;
  final ffi.Pointer<TSLanguage> language;
  
  Grammar({
    required this.name,
    required this.language,
  });
}

/// Represents a parsed syntax tree
class SyntaxTree {
  final Node rootNode;
  final String language;
  final ffi.Pointer<TSTree> _tree;
  final TreeSitterBindings _bindings;
  final String sourceCode;
  
  SyntaxTree({
    required this.rootNode,
    required this.language,
    required ffi.Pointer<TSTree> tree,
    required TreeSitterBindings bindings,
    required this.sourceCode,
  })  : _tree = tree,
        _bindings = bindings;
  
  /// Get node at specific byte position
  Node? nodeAt(int byteOffset) {
    return rootNode._findNodeAt(byteOffset);
  }
  
  /// Walk tree with visitor pattern
  void walk(TreeVisitor visitor) {
    _walkNode(rootNode, visitor);
  }
  
  void _walkNode(Node node, TreeVisitor visitor) {
    visitor.visit(node);
    for (final child in node.children) {
      _walkNode(child, visitor);
    }
  }
  
  /// Clean up resources
  void dispose() {
    _bindings.deleteTree(_tree);
  }
}

/// Represents a node in the syntax tree
class Node {
  final String type;
  final int startByte;
  final int endByte;
  final List<Node> children;
  final Node? parent;
  final TSNode _node;
  final TreeSitterBindings _bindings;
  final String _sourceCode;
  
  Node._({
    required this.type,
    required this.startByte,
    required this.endByte,
    required this.children,
    this.parent,
    required TSNode node,
    required TreeSitterBindings bindings,
    required String sourceCode,
  })  : _node = node,
        _bindings = bindings,
        _sourceCode = sourceCode;
  
  factory Node._fromTSNode(
    TSNode node,
    TreeSitterBindings bindings,
    String sourceCode, {
    Node? parent,
  }) {
    if (bindings.isNodeNull(node)) {
      throw ParseException('Cannot create Node from null TSNode');
    }
    
    final type = bindings.getNodeType(node);
    final startByte = bindings.getNodeStartByte(node);
    final endByte = bindings.getNodeEndByte(node);
    final childCount = bindings.getNodeChildCount(node);
    
    final nodeObj = Node._(
      type: type,
      startByte: startByte,
      endByte: endByte,
      children: [],
      parent: parent,
      node: node,
      bindings: bindings,
      sourceCode: sourceCode,
    );
    
    // Load children
    final children = <Node>[];
    for (int i = 0; i < childCount; i++) {
      final childNode = bindings.getNodeChild(node, i);
      if (!bindings.isNodeNull(childNode)) {
        children.add(Node._fromTSNode(
          childNode,
          bindings,
          sourceCode,
          parent: nodeObj,
        ));
      }
    }
    
    return Node._(
      type: type,
      startByte: startByte,
      endByte: endByte,
      children: children,
      parent: parent,
      node: node,
      bindings: bindings,
      sourceCode: sourceCode,
    );
  }
  
  /// Get the text content of this node
  String get text {
    if (startByte >= _sourceCode.length) return '';
    final end = endByte > _sourceCode.length ? _sourceCode.length : endByte;
    return _sourceCode.substring(startByte, end);
  }
  
  /// Find node at specific byte offset
  Node? _findNodeAt(int byteOffset) {
    if (byteOffset < startByte || byteOffset >= endByte) {
      return null;
    }
    
    // Check children first (more specific)
    for (final child in children) {
      final found = child._findNodeAt(byteOffset);
      if (found != null) return found;
    }
    
    // This node contains the offset
    return this;
  }
  
  @override
  String toString() {
    return 'Node(type: $type, start: $startByte, end: $endByte, children: ${children.length})';
  }
}

/// Represents an edit operation on the syntax tree
class Edit {
  final int startByte;
  final int oldEndByte;
  final int newEndByte;
  final Point startPoint;
  final Point oldEndPoint;
  final Point newEndPoint;
  
  Edit({
    required this.startByte,
    required this.oldEndByte,
    required this.newEndByte,
    required this.startPoint,
    required this.oldEndPoint,
    required this.newEndPoint,
  });
  
  TreeSitterEdit _toTreeSitterEdit() {
    return TreeSitterEdit(
      startByte: startByte,
      oldEndByte: oldEndByte,
      newEndByte: newEndByte,
      startPoint: TreeSitterPoint(row: startPoint.row, column: startPoint.column),
      oldEndPoint: TreeSitterPoint(row: oldEndPoint.row, column: oldEndPoint.column),
      newEndPoint: TreeSitterPoint(row: newEndPoint.row, column: newEndPoint.column),
    );
  }
}

/// Represents a point (row, column) in the source code
class Point {
  final int row;
  final int column;
  
  Point({required this.row, required this.column});
  
  @override
  String toString() => 'Point(row: $row, column: $column)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Point && other.row == row && other.column == column;
  }
  
  @override
  int get hashCode => Object.hash(row, column);
}

/// Represents a Tree-sitter query
class Query {
  final ffi.Pointer<TSQuery> _query;
  final TreeSitterBindings _bindings;
  
  Query._({
    required ffi.Pointer<TSQuery> query,
    required TreeSitterBindings bindings,
  })  : _query = query,
        _bindings = bindings;
  
  /// Create a query from .scm source
  factory Query.fromSource(
    String scmSource,
    Grammar grammar,
    TreeSitterBindings bindings,
  ) {
    final result = bindings.createQuery(grammar.language, scmSource);
    
    if (result.isError) {
      throw QueryException(
        'Failed to create query: ${result.error} at offset ${result.errorOffset}',
      );
    }
    
    return Query._(
      query: result.query!,
      bindings: bindings,
    );
  }
  
  /// Get the number of patterns in this query
  int get patternCount => _bindings.getPatternCount(_query);
  
  /// Clean up resources
  void dispose() {
    _bindings.deleteQuery(_query);
  }
}

/// Represents a match from executing a query
class QueryMatch {
  final int patternIndex;
  final Map<String, Node> captures;
  
  QueryMatch({
    required this.patternIndex,
    required this.captures,
  });
  
  @override
  String toString() {
    return 'QueryMatch(pattern: $patternIndex, captures: ${captures.keys.join(", ")})';
  }
}

/// Visitor pattern for walking the syntax tree
abstract class TreeVisitor {
  void visit(Node node);
}

/// Exception thrown when grammar loading fails
class GrammarLoadException implements Exception {
  final String message;
  GrammarLoadException(this.message);
  
  @override
  String toString() => 'GrammarLoadException: $message';
}

/// Exception thrown when parsing fails
class ParseException implements Exception {
  final String message;
  ParseException(this.message);
  
  @override
  String toString() => 'ParseException: $message';
}

/// Exception thrown when query creation or execution fails
class QueryException implements Exception {
  final String message;
  QueryException(this.message);
  
  @override
  String toString() => 'QueryException: $message';
}
