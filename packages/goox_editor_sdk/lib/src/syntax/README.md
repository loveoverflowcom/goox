# Tree-sitter FFI Bindings

This directory contains FFI bindings for the Tree-sitter parsing library and high-level parser API.

## Files

- **tree_sitter_ffi.dart**: Low-level FFI bindings to Tree-sitter C API
- **tree_sitter_loader.dart**: Platform-specific library loading logic
- **tree_sitter_bindings.dart**: High-level Dart wrapper for Tree-sitter operations
- **tree_sitter_parser.dart**: High-level Tree-sitter parser with automatic memory management

## Prerequisites

To use these bindings, you need to have Tree-sitter libraries installed on your system:

### macOS
```bash
brew install tree-sitter
```

### Linux (Ubuntu/Debian)
```bash
sudo apt-get install libtree-sitter-dev
```

### Windows
Download pre-built binaries from the Tree-sitter releases page and place them in your PATH.

## Language Grammars

To use Tree-sitter for syntax highlighting, you also need language-specific grammar libraries:

### macOS
```bash
brew install tree-sitter-<language>
# Example: brew install tree-sitter-dart
```

### Building from source
```bash
git clone https://github.com/UserNobody14/tree-sitter-dart
cd tree-sitter-dart
npm install
npm run build
# Copy the resulting .so/.dylib/.dll to your library path
```

## Usage Example

### High-Level API (Recommended)

```dart
import 'package:goox_editor_sdk/goox_editor_sdk.dart';

void main() async {
  final parser = TreeSitterParser();
  
  try {
    // Load a language grammar
    final grammar = await parser.loadGrammar('dart');
    
    // Parse some code
    final code = 'void main() { print("Hello"); }';
    final tree = parser.parse(code, grammar);
    
    try {
      // Access the syntax tree
      print('Root node: ${tree.rootNode}');
      print('Root node type: ${tree.rootNode.type}');
      
      // Find node at specific position
      final node = tree.nodeAt(10);
      if (node != null) {
        print('Node at position 10: ${node.type}');
        print('Node text: ${node.text}');
      }
      
      // Create and execute a query
      final querySource = '(function_signature name: (identifier) @function)';
      final query = Query.fromSource(querySource, grammar, parser._bindings);
      
      try {
        final matches = parser.query(tree, query);
        for (final match in matches) {
          print('Match: $match');
          for (final entry in match.captures.entries) {
            print('  ${entry.key}: ${entry.value.text}');
          }
        }
      } finally {
        query.dispose();
      }
      
      // Incremental update example
      final edit = Edit(
        startByte: 5,
        oldEndByte: 9,
        newEndByte: 13,
        startPoint: Point(row: 0, column: 5),
        oldEndPoint: Point(row: 0, column: 9),
        newEndPoint: Point(row: 0, column: 13),
      );
      
      final newCode = 'void main2() { print("Hello"); }';
      final newTree = parser.updateTree(tree, edit, newCode);
      print('Updated tree root: ${newTree.rootNode}');
      
      newTree.dispose();
    } finally {
      tree.dispose();
    }
  } finally {
    parser.dispose();
  }
}
```

### Low-Level API (Advanced)

```dart
import 'package:goox_editor_sdk/goox_editor_sdk.dart';

void main() {
  final bindings = TreeSitterBindings();
  
  // Create a parser
  final parser = bindings.createParser();
  
  try {
    // Load a language grammar
    final language = bindings.loadLanguage('dart');
    bindings.setLanguage(parser, language);
    
    // Parse some code
    final code = 'void main() { print("Hello"); }';
    final tree = bindings.parseString(parser, null, code);
    
    try {
      // Get the root node
      final rootNode = bindings.getRootNode(tree);
      print('Root node type: ${bindings.getNodeType(rootNode)}');
      
      // Query the tree
      final querySource = '(function_signature name: (identifier) @function)';
      final queryResult = bindings.createQuery(language, querySource);
      
      if (queryResult.isSuccess) {
        final query = queryResult.query!;
        final cursor = bindings.createQueryCursor();
        
        try {
          bindings.executeQuery(cursor, query, rootNode);
          
          while (true) {
            final match = bindings.nextMatch(cursor);
            if (match == null) break;
            
            for (final capture in match.captures) {
              final captureName = bindings.getCaptureName(query, capture.index);
              final nodeType = bindings.getNodeType(capture.node);
              print('Captured $captureName: $nodeType');
            }
          }
        } finally {
          bindings.deleteQueryCursor(cursor);
          bindings.deleteQuery(query);
        }
      }
    } finally {
      bindings.deleteTree(tree);
    }
  } finally {
    bindings.deleteParser(parser);
  }
}
```

## Platform Support

- ✅ macOS (Intel and Apple Silicon)
- ✅ Linux (x86_64)
- ✅ Windows (x86_64)

## Notes

- The bindings use manual memory management. Always call delete methods to avoid memory leaks.
- Tree-sitter uses incremental parsing for performance. Reuse trees when possible.
- Query syntax follows Tree-sitter's S-expression format (.scm files).
