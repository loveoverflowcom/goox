import 'dart:ui' as ui;
import 'package:dunebox_protocol/dunebox_protocol.dart';

/// Object registry for managing Paint, Path, and Paragraph objects
/// 
/// Maintains mappings from IDs to objects for efficient lookup.
/// Handles object lifecycle (create, update, dispose).
class ObjectRegistry {
  final Map<int, ui.Paint> _paints = {};
  final Map<int, ui.Path> _paths = {};
  final Map<int, ui.Paragraph> _paragraphs = {};
  
  // ========== Paint Management ==========
  
  /// Register a new Paint object with given ID
  void registerPaint(int id, ui.Paint paint) {
    if (_paints.containsKey(id)) {
      throw StateError('Paint with ID $id already exists');
    }
    _paints[id] = paint;
  }
  
  /// Get Paint object by ID
  ui.Paint getPaint(int id) {
    final paint = _paints[id];
    if (paint == null) {
      throw ObjectNotFoundException('Paint', id);
    }
    return paint;
  }
  
  /// Update existing Paint object
  void updatePaint(int id, ui.Paint paint) {
    if (!_paints.containsKey(id)) {
      throw ObjectNotFoundException('Paint', id);
    }
    _paints[id] = paint;
  }
  
  /// Dispose Paint object
  void disposePaint(int id) {
    if (_paints.remove(id) == null) {
      throw ObjectNotFoundException('Paint', id);
    }
  }
  
  /// Check if Paint exists
  bool hasPaint(int id) => _paints.containsKey(id);
  
  // ========== Path Management ==========
  
  /// Register a new Path object with given ID
  void registerPath(int id, ui.Path path) {
    if (_paths.containsKey(id)) {
      throw StateError('Path with ID $id already exists');
    }
    _paths[id] = path;
  }
  
  /// Get Path object by ID
  ui.Path getPath(int id) {
    final path = _paths[id];
    if (path == null) {
      throw ObjectNotFoundException('Path', id);
    }
    return path;
  }
  
  /// Dispose Path object
  void disposePath(int id) {
    if (_paths.remove(id) == null) {
      throw ObjectNotFoundException('Path', id);
    }
  }
  
  /// Check if Path exists
  bool hasPath(int id) => _paths.containsKey(id);
  
  // ========== Paragraph Management ==========
  
  /// Register a new Paragraph object with given ID
  void registerParagraph(int id, ui.Paragraph paragraph) {
    if (_paragraphs.containsKey(id)) {
      throw StateError('Paragraph with ID $id already exists');
    }
    _paragraphs[id] = paragraph;
  }
  
  /// Get Paragraph object by ID
  ui.Paragraph getParagraph(int id) {
    final paragraph = _paragraphs[id];
    if (paragraph == null) {
      throw ObjectNotFoundException('Paragraph', id);
    }
    return paragraph;
  }
  
  /// Dispose Paragraph object
  void disposeParagraph(int id) {
    if (_paragraphs.remove(id) == null) {
      throw ObjectNotFoundException('Paragraph', id);
    }
  }
  
  /// Check if Paragraph exists
  bool hasParagraph(int id) => _paragraphs.containsKey(id);
  
  // ========== Cleanup ==========
  
  /// Clear all objects from registry
  void clear() {
    _paints.clear();
    _paths.clear();
    _paragraphs.clear();
  }
  
  // ========== Statistics ==========
  
  /// Get number of Paint objects
  int get paintCount => _paints.length;
  
  /// Get number of Path objects
  int get pathCount => _paths.length;
  
  /// Get number of Paragraph objects
  int get paragraphCount => _paragraphs.length;
  
  /// Get total number of objects
  int get totalCount => paintCount + pathCount + paragraphCount;
}
