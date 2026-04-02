import 'dart:ffi' as ffi;
import 'tree_sitter_loader.dart';

/// FFI bindings for Tree-sitter C library
class TreeSitterFFI {
  late final ffi.DynamicLibrary _lib;
  
  TreeSitterFFI() {
    _lib = TreeSitterLoader.loadTreeSitter();
  }
  
  /// Create FFI bindings from an existing library
  TreeSitterFFI.fromLibrary(ffi.DynamicLibrary lib) : _lib = lib;
  
  // Core Tree-sitter types
  late final ts_parser_new = _lib.lookupFunction<
      ffi.Pointer<TSParser> Function(),
      ffi.Pointer<TSParser> Function()>('ts_parser_new');
  
  late final ts_parser_delete = _lib.lookupFunction<
      ffi.Void Function(ffi.Pointer<TSParser>),
      void Function(ffi.Pointer<TSParser>)>('ts_parser_delete');
  
  late final ts_parser_set_language = _lib.lookupFunction<
      ffi.Bool Function(ffi.Pointer<TSParser>, ffi.Pointer<TSLanguage>),
      bool Function(ffi.Pointer<TSParser>, ffi.Pointer<TSLanguage>)>('ts_parser_set_language');
  
  late final ts_parser_parse_string = _lib.lookupFunction<
      ffi.Pointer<TSTree> Function(
        ffi.Pointer<TSParser>,
        ffi.Pointer<TSTree>,
        ffi.Pointer<ffi.Char>,
        ffi.Uint32
      ),
      ffi.Pointer<TSTree> Function(
        ffi.Pointer<TSParser>,
        ffi.Pointer<TSTree>,
        ffi.Pointer<ffi.Char>,
        int
      )>('ts_parser_parse_string');
  
  late final ts_tree_delete = _lib.lookupFunction<
      ffi.Void Function(ffi.Pointer<TSTree>),
      void Function(ffi.Pointer<TSTree>)>('ts_tree_delete');
  
  late final ts_tree_root_node = _lib.lookupFunction<
      TSNode Function(ffi.Pointer<TSTree>),
      TSNode Function(ffi.Pointer<TSTree>)>('ts_tree_root_node');
  
  late final ts_tree_edit = _lib.lookupFunction<
      ffi.Void Function(ffi.Pointer<TSTree>, ffi.Pointer<TSInputEdit>),
      void Function(ffi.Pointer<TSTree>, ffi.Pointer<TSInputEdit>)>('ts_tree_edit');
  
  late final ts_node_type = _lib.lookupFunction<
      ffi.Pointer<ffi.Char> Function(TSNode),
      ffi.Pointer<ffi.Char> Function(TSNode)>('ts_node_type');
  
  late final ts_node_start_byte = _lib.lookupFunction<
      ffi.Uint32 Function(TSNode),
      int Function(TSNode)>('ts_node_start_byte');
  
  late final ts_node_end_byte = _lib.lookupFunction<
      ffi.Uint32 Function(TSNode),
      int Function(TSNode)>('ts_node_end_byte');
  
  late final ts_node_child_count = _lib.lookupFunction<
      ffi.Uint32 Function(TSNode),
      int Function(TSNode)>('ts_node_child_count');
  
  late final ts_node_child = _lib.lookupFunction<
      TSNode Function(TSNode, ffi.Uint32),
      TSNode Function(TSNode, int)>('ts_node_child');
  
  late final ts_node_parent = _lib.lookupFunction<
      TSNode Function(TSNode),
      TSNode Function(TSNode)>('ts_node_parent');
  
  late final ts_node_is_null = _lib.lookupFunction<
      ffi.Bool Function(TSNode),
      bool Function(TSNode)>('ts_node_is_null');
  
  // Query API
  late final ts_query_new = _lib.lookupFunction<
      ffi.Pointer<TSQuery> Function(
        ffi.Pointer<TSLanguage>,
        ffi.Pointer<ffi.Char>,
        ffi.Uint32,
        ffi.Pointer<ffi.Uint32>,
        ffi.Pointer<ffi.Int32>
      ),
      ffi.Pointer<TSQuery> Function(
        ffi.Pointer<TSLanguage>,
        ffi.Pointer<ffi.Char>,
        int,
        ffi.Pointer<ffi.Uint32>,
        ffi.Pointer<ffi.Int32>
      )>('ts_query_new');
  
  late final ts_query_delete = _lib.lookupFunction<
      ffi.Void Function(ffi.Pointer<TSQuery>),
      void Function(ffi.Pointer<TSQuery>)>('ts_query_delete');
  
  late final ts_query_cursor_new = _lib.lookupFunction<
      ffi.Pointer<TSQueryCursor> Function(),
      ffi.Pointer<TSQueryCursor> Function()>('ts_query_cursor_new');
  
  late final ts_query_cursor_delete = _lib.lookupFunction<
      ffi.Void Function(ffi.Pointer<TSQueryCursor>),
      void Function(ffi.Pointer<TSQueryCursor>)>('ts_query_cursor_delete');
  
  late final ts_query_cursor_exec = _lib.lookupFunction<
      ffi.Void Function(ffi.Pointer<TSQueryCursor>, ffi.Pointer<TSQuery>, TSNode),
      void Function(ffi.Pointer<TSQueryCursor>, ffi.Pointer<TSQuery>, TSNode)>('ts_query_cursor_exec');
  
  late final ts_query_cursor_next_match = _lib.lookupFunction<
      ffi.Bool Function(ffi.Pointer<TSQueryCursor>, ffi.Pointer<TSQueryMatch>),
      bool Function(ffi.Pointer<TSQueryCursor>, ffi.Pointer<TSQueryMatch>)>('ts_query_cursor_next_match');
  
  late final ts_query_capture_name_for_id = _lib.lookupFunction<
      ffi.Pointer<ffi.Char> Function(ffi.Pointer<TSQuery>, ffi.Uint32, ffi.Pointer<ffi.Uint32>),
      ffi.Pointer<ffi.Char> Function(ffi.Pointer<TSQuery>, int, ffi.Pointer<ffi.Uint32>)>('ts_query_capture_name_for_id');
  
  late final ts_query_pattern_count = _lib.lookupFunction<
      ffi.Uint32 Function(ffi.Pointer<TSQuery>),
      int Function(ffi.Pointer<TSQuery>)>('ts_query_pattern_count');
}

// Opaque types
final class TSParser extends ffi.Opaque {}
final class TSTree extends ffi.Opaque {}
final class TSLanguage extends ffi.Opaque {}
final class TSQuery extends ffi.Opaque {}
final class TSQueryCursor extends ffi.Opaque {}

// TSNode struct (passed by value)
final class TSNode extends ffi.Struct {
  @ffi.Array(4)
  external ffi.Array<ffi.Uint32> context;
  
  external ffi.Pointer<ffi.Void> id;
  external ffi.Pointer<TSTree> tree;
}

// TSInputEdit struct
final class TSInputEdit extends ffi.Struct {
  @ffi.Uint32()
  external int start_byte;
  
  @ffi.Uint32()
  external int old_end_byte;
  
  @ffi.Uint32()
  external int new_end_byte;
  
  external TSPoint start_point;
  external TSPoint old_end_point;
  external TSPoint new_end_point;
}

// TSPoint struct
final class TSPoint extends ffi.Struct {
  @ffi.Uint32()
  external int row;
  
  @ffi.Uint32()
  external int column;
}

// TSQueryMatch struct
final class TSQueryMatch extends ffi.Struct {
  @ffi.Uint32()
  external int id;
  
  @ffi.Uint16()
  external int pattern_index;
  
  @ffi.Uint16()
  external int capture_count;
  
  external ffi.Pointer<TSQueryCapture> captures;
}

// TSQueryCapture struct
final class TSQueryCapture extends ffi.Struct {
  external TSNode node;
  
  @ffi.Uint32()
  external int index;
}

// TSQueryError enum
enum TSQueryError {
  none(0),
  syntax(1),
  nodeType(2),
  field(3),
  capture(4),
  structure(5),
  language(6);
  
  final int value;
  const TSQueryError(this.value);
  
  static TSQueryError fromValue(int value) {
    return TSQueryError.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TSQueryError.none,
    );
  }
}
