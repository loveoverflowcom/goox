import 'dart:ffi' as ffi;
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'tree_sitter_ffi.dart';
import 'tree_sitter_loader.dart';

/// High-level wrapper for Tree-sitter FFI bindings
class TreeSitterBindings {
  final TreeSitterFFI _ffi;
  
  TreeSitterBindings() : _ffi = TreeSitterFFI();
  
  TreeSitterBindings.fromFFI(TreeSitterFFI ffi) : _ffi = ffi;
  
  /// Create a new parser instance
  ffi.Pointer<TSParser> createParser() {
    return _ffi.ts_parser_new();
  }
  
  /// Delete a parser instance
  void deleteParser(ffi.Pointer<TSParser> parser) {
    _ffi.ts_parser_delete(parser);
  }
  
  /// Set the language for a parser
  bool setLanguage(ffi.Pointer<TSParser> parser, ffi.Pointer<TSLanguage> language) {
    return _ffi.ts_parser_set_language(parser, language);
  }
  
  /// Parse a string
  ffi.Pointer<TSTree> parseString(
    ffi.Pointer<TSParser> parser,
    ffi.Pointer<TSTree>? oldTree,
    String source,
  ) {
    final sourceBytes = utf8.encode(source);
    final sourcePtr = malloc<ffi.Char>(sourceBytes.length);
    try {
      for (int i = 0; i < sourceBytes.length; i++) {
        sourcePtr[i] = sourceBytes[i];
      }
      return _ffi.ts_parser_parse_string(
        parser,
        oldTree ?? ffi.nullptr,
        sourcePtr,
        source.length,
      );
    } finally {
      malloc.free(sourcePtr);
    }
  }
  
  /// Delete a tree
  void deleteTree(ffi.Pointer<TSTree> tree) {
    _ffi.ts_tree_delete(tree);
  }
  
  /// Get the root node of a tree
  TSNode getRootNode(ffi.Pointer<TSTree> tree) {
    return _ffi.ts_tree_root_node(tree);
  }
  
  /// Edit a tree
  void editTree(ffi.Pointer<TSTree> tree, TreeSitterEdit edit) {
    final editPtr = malloc<TSInputEdit>();
    try {
      editPtr.ref.start_byte = edit.startByte;
      editPtr.ref.old_end_byte = edit.oldEndByte;
      editPtr.ref.new_end_byte = edit.newEndByte;
      editPtr.ref.start_point.row = edit.startPoint.row;
      editPtr.ref.start_point.column = edit.startPoint.column;
      editPtr.ref.old_end_point.row = edit.oldEndPoint.row;
      editPtr.ref.old_end_point.column = edit.oldEndPoint.column;
      editPtr.ref.new_end_point.row = edit.newEndPoint.row;
      editPtr.ref.new_end_point.column = edit.newEndPoint.column;
      
      _ffi.ts_tree_edit(tree, editPtr);
    } finally {
      malloc.free(editPtr);
    }
  }
  
  /// Get node type
  String getNodeType(TSNode node) {
    final typePtr = _ffi.ts_node_type(node);
    return _charPointerToString(typePtr);
  }
  
  /// Get node start byte
  int getNodeStartByte(TSNode node) {
    return _ffi.ts_node_start_byte(node);
  }
  
  /// Get node end byte
  int getNodeEndByte(TSNode node) {
    return _ffi.ts_node_end_byte(node);
  }
  
  /// Get node child count
  int getNodeChildCount(TSNode node) {
    return _ffi.ts_node_child_count(node);
  }
  
  /// Get node child at index
  TSNode getNodeChild(TSNode node, int index) {
    return _ffi.ts_node_child(node, index);
  }
  
  /// Get node parent
  TSNode getNodeParent(TSNode node) {
    return _ffi.ts_node_parent(node);
  }
  
  /// Check if node is null
  bool isNodeNull(TSNode node) {
    return _ffi.ts_node_is_null(node);
  }
  
  /// Create a new query
  QueryResult createQuery(
    ffi.Pointer<TSLanguage> language,
    String querySource,
  ) {
    final sourceBytes = utf8.encode(querySource);
    final sourcePtr = malloc<ffi.Char>(sourceBytes.length);
    final errorOffset = malloc<ffi.Uint32>();
    final errorType = malloc<ffi.Int32>();
    
    try {
      for (int i = 0; i < sourceBytes.length; i++) {
        sourcePtr[i] = sourceBytes[i];
      }
      
      final query = _ffi.ts_query_new(
        language,
        sourcePtr,
        querySource.length,
        errorOffset,
        errorType,
      );
      
      if (query == ffi.nullptr) {
        final error = TSQueryError.fromValue(errorType.value);
        return QueryResult.error(error, errorOffset.value);
      }
      
      return QueryResult.success(query);
    } finally {
      malloc.free(sourcePtr);
      malloc.free(errorOffset);
      malloc.free(errorType);
    }
  }
  
  /// Delete a query
  void deleteQuery(ffi.Pointer<TSQuery> query) {
    _ffi.ts_query_delete(query);
  }
  
  /// Create a query cursor
  ffi.Pointer<TSQueryCursor> createQueryCursor() {
    return _ffi.ts_query_cursor_new();
  }
  
  /// Delete a query cursor
  void deleteQueryCursor(ffi.Pointer<TSQueryCursor> cursor) {
    _ffi.ts_query_cursor_delete(cursor);
  }
  
  /// Execute a query
  void executeQuery(
    ffi.Pointer<TSQueryCursor> cursor,
    ffi.Pointer<TSQuery> query,
    TSNode node,
  ) {
    _ffi.ts_query_cursor_exec(cursor, query, node);
  }
  
  /// Get next query match
  QueryMatch? nextMatch(ffi.Pointer<TSQueryCursor> cursor) {
    final matchPtr = malloc<TSQueryMatch>();
    try {
      final hasMatch = _ffi.ts_query_cursor_next_match(cursor, matchPtr);
      if (!hasMatch) {
        return null;
      }
      
      final match = matchPtr.ref;
      final captures = <QueryCapture>[];
      
      for (int i = 0; i < match.capture_count; i++) {
        final capturePtr = match.captures + i;
        captures.add(QueryCapture(
          node: capturePtr.ref.node,
          index: capturePtr.ref.index,
        ));
      }
      
      return QueryMatch(
        id: match.id,
        patternIndex: match.pattern_index,
        captures: captures,
      );
    } finally {
      malloc.free(matchPtr);
    }
  }
  
  /// Get capture name for ID
  String getCaptureName(ffi.Pointer<TSQuery> query, int captureId) {
    final lengthPtr = malloc<ffi.Uint32>();
    try {
      final namePtr = _ffi.ts_query_capture_name_for_id(query, captureId, lengthPtr);
      return _charPointerToString(namePtr, lengthPtr.value);
    } finally {
      malloc.free(lengthPtr);
    }
  }
  
  /// Get pattern count
  int getPatternCount(ffi.Pointer<TSQuery> query) {
    return _ffi.ts_query_pattern_count(query);
  }
  
  /// Load a language grammar
  ffi.Pointer<TSLanguage> loadLanguage(String languageName) {
    final lib = TreeSitterLoader.loadLanguage(languageName);
    final symbolName = 'tree_sitter_$languageName';
    
    try {
      final languageFunc = lib.lookupFunction<
        ffi.Pointer<TSLanguage> Function(),
        ffi.Pointer<TSLanguage> Function()
      >(symbolName);
      
      return languageFunc();
    } catch (e) {
      throw Exception('Failed to load language $languageName: $e');
    }
  }
  
  /// Convert a C char pointer to Dart string
  String _charPointerToString(ffi.Pointer<ffi.Char> ptr, [int? length]) {
    if (ptr == ffi.nullptr) {
      return '';
    }
    
    if (length != null) {
      final bytes = <int>[];
      for (int i = 0; i < length; i++) {
        bytes.add(ptr[i]);
      }
      return utf8.decode(bytes);
    }
    
    // Read until null terminator
    final bytes = <int>[];
    int i = 0;
    while (ptr[i] != 0) {
      bytes.add(ptr[i]);
      i++;
    }
    return utf8.decode(bytes);
  }
}

/// Result of creating a query
class QueryResult {
  final ffi.Pointer<TSQuery>? query;
  final TSQueryError? error;
  final int? errorOffset;
  
  QueryResult.success(this.query) : error = null, errorOffset = null;
  QueryResult.error(this.error, this.errorOffset) : query = null;
  
  bool get isSuccess => query != null;
  bool get isError => error != null;
}

/// Represents a Tree-sitter edit
class TreeSitterEdit {
  final int startByte;
  final int oldEndByte;
  final int newEndByte;
  final TreeSitterPoint startPoint;
  final TreeSitterPoint oldEndPoint;
  final TreeSitterPoint newEndPoint;
  
  TreeSitterEdit({
    required this.startByte,
    required this.oldEndByte,
    required this.newEndByte,
    required this.startPoint,
    required this.oldEndPoint,
    required this.newEndPoint,
  });
}

/// Represents a point in the source code
class TreeSitterPoint {
  final int row;
  final int column;
  
  TreeSitterPoint({required this.row, required this.column});
}

/// Represents a query match
class QueryMatch {
  final int id;
  final int patternIndex;
  final List<QueryCapture> captures;
  
  QueryMatch({
    required this.id,
    required this.patternIndex,
    required this.captures,
  });
}

/// Represents a query capture
class QueryCapture {
  final TSNode node;
  final int index;
  
  QueryCapture({required this.node, required this.index});
}
