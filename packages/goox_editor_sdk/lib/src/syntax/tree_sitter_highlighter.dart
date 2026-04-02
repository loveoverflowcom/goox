import 'package:flutter/material.dart';

import 'query_parser.dart';
import 'tree_sitter_parser.dart';

/// Theme-aware color mapping for Tree-sitter captures
/// 
/// Maps Tree-sitter capture names (e.g., @keyword, @function, @variable)
/// to colors for both light and dark themes
class ThemeColorMap {
  const ThemeColorMap({
    required this.lightTheme,
    required this.darkTheme,
  });

  /// Create a VSCode-style color map with standard colors
  factory ThemeColorMap.vscode() {
    return ThemeColorMap(
      lightTheme: const {
        'keyword': Color(0xFF0000FF),
        'type': Color(0xFF267F99),
        'string': Color(0xFFA31515),
        'comment': Color(0xFF6A9955),
        'number': Color(0xFF098658),
        'constant': Color(0xFF0000FF),
        'function': Color(0xFF795E26),
        'function.method': Color(0xFF795E26),
        'operator': Color(0xFF000000),
        'punctuation': Color(0xFF000000),
        'variable': Color(0xFF001080),
        'variable.parameter': Color(0xFF001080),
        'property': Color(0xFF001080),
        'tag': Color(0xFF800000),
        'attribute': Color(0xFFFF0000),
      },
      darkTheme: const {
        'keyword': Color(0xFFC586C0),
        'type': Color(0xFF4EC9B0),
        'string': Color(0xFFCE9178),
        'comment': Color(0xFF6A9955),
        'number': Color(0xFFB5CEA8),
        'constant': Color(0xFF569CD6),
        'function': Color(0xFFDCDCAA),
        'function.method': Color(0xFFDCDCAA),
        'operator': Color(0xFFD4D4D4),
        'punctuation': Color(0xFFD4D4D4),
        'variable': Color(0xFF9CDCFE),
        'variable.parameter': Color(0xFF9CDCFE),
        'property': Color(0xFF9CDCFE),
        'tag': Color(0xFF569CD6),
        'attribute': Color(0xFF9CDCFE),
      },
    );
  }

  final Map<String, Color> lightTheme;
  final Map<String, Color> darkTheme;

  /// Get color for a Tree-sitter capture name
  /// 
  /// Supports hierarchical capture names (e.g., @function.method)
  /// Falls back to parent category if specific capture not found
  Color getColor(String captureName, bool isDark) {
    final palette = isDark ? darkTheme : lightTheme;
    
    // Remove @ prefix if present
    final normalized = captureName.startsWith('@') 
        ? captureName.substring(1) 
        : captureName;
    
    // Try exact match first
    if (palette.containsKey(normalized)) {
      return palette[normalized]!;
    }
    
    // Try parent categories (e.g., function.method -> function)
    final parts = normalized.split('.');
    for (var i = parts.length - 1; i > 0; i--) {
      final parent = parts.sublist(0, i).join('.');
      if (palette.containsKey(parent)) {
        return palette[parent]!;
      }
    }
    
    // Default fallback
    return palette['variable'] ?? (isDark ? Colors.white : Colors.black);
  }
}

/// Represents a highlighted span of text
class HighlightSpan {
  const HighlightSpan({
    required this.start,
    required this.end,
    required this.captureName,
    required this.color,
  });

  /// Start byte offset in the source code
  final int start;
  
  /// End byte offset in the source code
  final int end;
  
  /// Tree-sitter capture name (e.g., @keyword, @function)
  final String captureName;
  
  /// Color to apply to this span
  final Color color;

  @override
  String toString() {
    return 'HighlightSpan(start: $start, end: $end, capture: $captureName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HighlightSpan &&
        other.start == start &&
        other.end == end &&
        other.captureName == captureName &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(start, end, captureName, color);
}

/// Tree-sitter based syntax highlighter
/// 
/// Uses Tree-sitter queries to generate syntax highlighting spans
/// with theme-aware colors
class TreeSitterHighlighter {
  TreeSitterHighlighter({
    required this.parser,
    required this.highlightQuery,
    ThemeColorMap? colorMap,
  }) : colorMap = colorMap ?? ThemeColorMap.vscode();

  final TreeSitterParser parser;
  final ParsedQuery highlightQuery;
  final ThemeColorMap colorMap;
  
  // Cache for highlighting results keyed by (code hash, start, end, isDark)
  final Map<String, List<HighlightSpan>> _highlightCache = {};
  
  // Cache for parse trees to avoid re-parsing
  SyntaxTree? _cachedTree;
  String? _cachedCode;
  
  static const int _maxCacheSize = 100;

  /// Highlight visible range of code
  /// 
  /// Returns a list of [HighlightSpan] objects for the specified byte range.
  /// Uses incremental parsing and caching for performance.
  List<HighlightSpan> highlight(
    String code,
    SyntaxTree tree,
    int startByte,
    int endByte, {
    required bool isDark,
  }) {
    // Check cache
    final cacheKey = '${code.hashCode}:$startByte:$endByte:$isDark';
    if (_cachedCode == code && _highlightCache.containsKey(cacheKey)) {
      return _highlightCache[cacheKey]!;
    }

    // Update cached tree if code changed
    if (_cachedCode != code) {
      _cachedTree = tree;
      _cachedCode = code;
    }

    // Execute query on the tree
    final matches = highlightQuery.execute(tree);
    
    // Convert matches to highlight spans
    final spans = <HighlightSpan>[];
    for (final match in matches) {
      for (final entry in match.captures.entries) {
        final captureName = entry.key;
        final node = entry.value;
        
        // Only include spans that overlap with the requested range
        if (node.endByte <= startByte || node.startByte >= endByte) {
          continue;
        }
        
        final color = colorMap.getColor(captureName, isDark);
        spans.add(HighlightSpan(
          start: node.startByte,
          end: node.endByte,
          captureName: captureName,
          color: color,
        ));
      }
    }
    
    // Sort spans by start position
    spans.sort((a, b) => a.start.compareTo(b.start));
    
    // Cache the result with LRU eviction
    _cacheHighlightResult(cacheKey, spans);
    
    return spans;
  }
  
  /// Cache highlighting result with LRU eviction
  void _cacheHighlightResult(String key, List<HighlightSpan> spans) {
    if (_highlightCache.length >= _maxCacheSize) {
      // Remove oldest entry (simple FIFO for now)
      final firstKey = _highlightCache.keys.first;
      _highlightCache.remove(firstKey);
    }
    _highlightCache[key] = spans;
  }

  /// Incrementally update highlighting after edit
  /// 
  /// Uses Tree-sitter's incremental parsing to efficiently update
  /// highlighting for only the affected regions
  List<HighlightSpan> updateHighlighting(
    String code,
    SyntaxTree oldTree,
    SyntaxTree newTree,
    Edit edit, {
    required bool isDark,
  }) {
    // Invalidate cache entries affected by the edit
    _invalidateAffectedCache(edit);
    
    // Update cached tree
    _cachedTree = newTree;
    _cachedCode = code;
    
    // Calculate affected region with context
    // We expand the region to ensure multi-line patterns are re-highlighted
    final affectedStart = edit.startByte;
    final affectedEnd = edit.newEndByte;
    
    // Expand the affected region to include some context (1000 bytes before/after)
    final contextStart = (affectedStart - 1000).clamp(0, code.length);
    final contextEnd = (affectedEnd + 1000).clamp(0, code.length);
    
    // Re-highlight only the affected region
    return highlight(
      code,
      newTree,
      contextStart,
      contextEnd,
      isDark: isDark,
    );
  }
  
  /// Invalidate cache entries affected by an edit
  void _invalidateAffectedCache(Edit edit) {
    final keysToRemove = <String>[];
    
    for (final key in _highlightCache.keys) {
      final parts = key.split(':');
      if (parts.length != 4) continue;
      
      final start = int.tryParse(parts[1]);
      final end = int.tryParse(parts[2]);
      if (start == null || end == null) continue;
      
      // Check if this cache entry overlaps with the edit
      // An entry is affected if its range overlaps with the edited region
      if (!(end <= edit.startByte || start >= edit.oldEndByte)) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _highlightCache.remove(key);
    }
  }

  /// Clear cached highlighting state
  void clearCache() {
    _highlightCache.clear();
    _cachedCode = null;
    _cachedTree = null;
  }

  /// Convert highlight spans to Flutter TextSpans
  /// 
  /// Helper method to convert [HighlightSpan] objects to Flutter's
  /// [TextSpan] for rendering
  List<TextSpan> toTextSpans(
    String code,
    List<HighlightSpan> spans,
    TextStyle baseStyle,
  ) {
    if (spans.isEmpty) {
      return [TextSpan(text: code, style: baseStyle)];
    }

    final result = <TextSpan>[];
    var currentPos = 0;

    for (final span in spans) {
      // Add unstyled text before this span
      if (span.start > currentPos) {
        result.add(TextSpan(
          text: code.substring(currentPos, span.start),
          style: baseStyle,
        ));
      }

      // Add styled span
      result.add(TextSpan(
        text: code.substring(span.start, span.end),
        style: baseStyle.copyWith(color: span.color),
      ));

      currentPos = span.end;
    }

    // Add remaining unstyled text
    if (currentPos < code.length) {
      result.add(TextSpan(
        text: code.substring(currentPos),
        style: baseStyle,
      ));
    }

    return result;
  }

  /// Dispose resources
  void dispose() {
    clearCache();
  }
}
