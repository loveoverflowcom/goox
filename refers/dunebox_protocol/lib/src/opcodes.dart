/// OpCode definitions for Binary Canvas Protocol
/// 
/// Each OpCode represents a specific Canvas operation or object management command.
/// OpCodes are organized into ranges by category for extensibility.
class OpCode {
  // Primitive drawing operations (0x01-0x0F)
  
  /// Draw a rectangle: x (f32) + y (f32) + width (f32) + height (f32) + paint_id (u32)
  static const int drawRect = 0x01;
  
  /// Draw a circle: cx (f32) + cy (f32) + radius (f32) + paint_id (u32)
  static const int drawCircle = 0x02;
  
  /// Draw a line: x1 (f32) + y1 (f32) + x2 (f32) + y2 (f32) + paint_id (u32)
  static const int drawLine = 0x03;
  
  /// Draw a path: path_id (u32) + paint_id (u32)
  static const int drawPath = 0x04;
  
  /// Draw points: point_mode (u8) + count (u16) + points (f32[]) + paint_id (u32)
  static const int drawPoints = 0x05;
  
  // Canvas state operations (0x10-0x1F)
  
  /// Save canvas state (no parameters)
  static const int save = 0x10;
  
  /// Restore canvas state (no parameters)
  static const int restore = 0x11;
  
  /// Translate canvas: dx (f32) + dy (f32)
  static const int translate = 0x12;
  
  /// Scale canvas: sx (f32) + sy (f32)
  static const int scale = 0x13;
  
  /// Rotate canvas: radians (f32)
  static const int rotate = 0x14;
  
  /// Apply matrix transform: m11 (f32) + m12 (f32) + m13 (f32) + m21 (f32) + m22 (f32) + m23 (f32)
  static const int transform = 0x15;
  
  // Text operations (0x20-0x2F)
  
  /// Draw paragraph: paragraph_id (u32) + x (f32) + y (f32)
  static const int drawParagraph = 0x20;
  
  // Object management (0x30-0x3F)
  
  /// Create Paint object: paint_id (u32) + color (u32) + stroke_width (f32) + style (u8) + blend_mode (u8) + is_anti_alias (u8) + stroke_cap (u8) + stroke_join (u8) + miter_limit (f32)
  static const int createPaint = 0x30;
  
  /// Update Paint object: paint_id (u32) + field_mask (u8) + updated fields
  static const int updatePaint = 0x31;
  
  /// Create Path object: path_id (u32) + command_count (u16) + path_commands
  static const int createPath = 0x32;
  
  /// Dispose Paint object: paint_id (u32)
  static const int disposePaint = 0x33;
  
  /// Dispose Path object: path_id (u32)
  static const int disposePath = 0x34;
  
  /// Create Paragraph object: paragraph_id (u32) + text_length (u16) + text_bytes (UTF-8) + font_size (f32) + color (u32)
  static const int createParagraph = 0x35;
  
  /// Dispose Paragraph object: paragraph_id (u32)
  static const int disposeParagraph = 0x36;
  
  // Clipping operations (0x40-0x4F)
  
  /// Clip to rectangle: left (f32) + top (f32) + right (f32) + bottom (f32) + clip_op (u8)
  static const int clipRect = 0x40;
  
  /// Clip to path: path_id (u32) + clip_op (u8)
  static const int clipPath = 0x41;
  
  /// Draw shadow: path_id (u32) + color (u32) + elevation (f32) + transparent_occluder (u8)
  static const int drawShadow = 0x42;
  
  // Shader operations (0x50-0x5F)
  
  /// Create linear gradient: shader_id (u32) + from_x (f32) + from_y (f32) + to_x (f32) + to_y (f32) + color_count (u8) + colors (u32[]) + stops (f32[])
  static const int createLinearGradient = 0x50;
  
  /// Create radial gradient: shader_id (u32) + cx (f32) + cy (f32) + radius (f32) + color_count (u8) + colors (u32[]) + stops (f32[])
  static const int createRadialGradient = 0x51;
  
  // Filter operations (0x60-0x6F)
  
  /// Create blur filter: filter_id (u32) + sigma_x (f32) + sigma_y (f32)
  static const int createBlurFilter = 0x60;
  
  // Reserved for future use (0x70-0xFE)
  
  // Extension mechanism (0xFF)
  
  /// Extension mechanism for future protocol versions
  static const int extension = 0xFF;
  
  /// Protocol version
  static const int protocolVersion = 0x01;
  
  /// Get OpCode name for debugging
  static String getName(int opCode) {
    switch (opCode) {
      case drawRect: return 'drawRect';
      case drawCircle: return 'drawCircle';
      case drawLine: return 'drawLine';
      case drawPath: return 'drawPath';
      case drawPoints: return 'drawPoints';
      case save: return 'save';
      case restore: return 'restore';
      case translate: return 'translate';
      case scale: return 'scale';
      case rotate: return 'rotate';
      case transform: return 'transform';
      case drawParagraph: return 'drawParagraph';
      case createPaint: return 'createPaint';
      case updatePaint: return 'updatePaint';
      case createPath: return 'createPath';
      case disposePaint: return 'disposePaint';
      case disposePath: return 'disposePath';
      case createParagraph: return 'createParagraph';
      case disposeParagraph: return 'disposeParagraph';
      case clipRect: return 'clipRect';
      case clipPath: return 'clipPath';
      case drawShadow: return 'drawShadow';
      case createLinearGradient: return 'createLinearGradient';
      case createRadialGradient: return 'createRadialGradient';
      case createBlurFilter: return 'createBlurFilter';
      case extension: return 'extension';
      default: return 'unknown(0x${opCode.toRadixString(16)})';
    }
  }
}
