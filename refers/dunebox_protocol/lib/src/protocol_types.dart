/// Protocol type definitions and enums
/// 
/// These types mirror dart:ui types but are serializable across Wasm boundary.

/// Painting style enum (matches dart:ui PaintingStyle)
enum PaintingStyleEnum {
  fill(0x00),
  stroke(0x01);
  
  final int value;
  const PaintingStyleEnum(this.value);
  
  static PaintingStyleEnum fromValue(int value) {
    switch (value) {
      case 0x00: return fill;
      case 0x01: return stroke;
      default: throw ArgumentError('Invalid PaintingStyle value: $value');
    }
  }
}

/// Blend mode enum (matches dart:ui BlendMode ordinal values)
enum BlendModeEnum {
  clear(0),
  src(1),
  dst(2),
  srcOver(3),
  dstOver(4),
  srcIn(5),
  dstIn(6),
  srcOut(7),
  dstOut(8),
  srcATop(9),
  dstATop(10),
  xor(11),
  plus(12),
  modulate(13),
  screen(14),
  overlay(15),
  darken(16),
  lighten(17),
  colorDodge(18),
  colorBurn(19),
  hardLight(20),
  softLight(21),
  difference(22),
  exclusion(23),
  multiply(24),
  hue(25),
  saturation(26),
  color(27),
  luminosity(28);
  
  final int value;
  const BlendModeEnum(this.value);
  
  static BlendModeEnum fromValue(int value) {
    return BlendModeEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid BlendMode value: $value'),
    );
  }
}

/// Stroke cap enum (matches dart:ui StrokeCap)
enum StrokeCapEnum {
  butt(0x00),
  round(0x01),
  square(0x02);
  
  final int value;
  const StrokeCapEnum(this.value);
  
  static StrokeCapEnum fromValue(int value) {
    switch (value) {
      case 0x00: return butt;
      case 0x01: return round;
      case 0x02: return square;
      default: throw ArgumentError('Invalid StrokeCap value: $value');
    }
  }
}

/// Stroke join enum (matches dart:ui StrokeJoin)
enum StrokeJoinEnum {
  miter(0x00),
  round(0x01),
  bevel(0x02);
  
  final int value;
  const StrokeJoinEnum(this.value);
  
  static StrokeJoinEnum fromValue(int value) {
    switch (value) {
      case 0x00: return miter;
      case 0x01: return round;
      case 0x02: return bevel;
      default: throw ArgumentError('Invalid StrokeJoin value: $value');
    }
  }
}

/// Clip operation enum (matches dart:ui ClipOp)
enum ClipOpEnum {
  difference(0x00),
  intersect(0x01);
  
  final int value;
  const ClipOpEnum(this.value);
  
  static ClipOpEnum fromValue(int value) {
    switch (value) {
      case 0x00: return difference;
      case 0x01: return intersect;
      default: throw ArgumentError('Invalid ClipOp value: $value');
    }
  }
}

/// Text alignment enum
enum TextAlignmentEnum {
  left(0x00),
  center(0x01),
  right(0x02);
  
  final int value;
  const TextAlignmentEnum(this.value);
  
  static TextAlignmentEnum fromValue(int value) {
    switch (value) {
      case 0x00: return left;
      case 0x01: return center;
      case 0x02: return right;
      default: throw ArgumentError('Invalid TextAlignment value: $value');
    }
  }
}

/// Path command types
enum PathCommandType {
  moveTo(0x01),
  lineTo(0x02),
  quadraticBezierTo(0x03),
  cubicTo(0x04),
  close(0x05),
  addRect(0x10),
  addOval(0x11);
  
  final int value;
  const PathCommandType(this.value);
  
  static PathCommandType fromValue(int value) {
    return PathCommandType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid PathCommandType value: $value'),
    );
  }
}

/// Paint update field mask bits
class PaintFieldMask {
  static const int color = 1 << 0;
  static const int strokeWidth = 1 << 1;
  static const int style = 1 << 2;
  static const int blendMode = 1 << 3;
  static const int isAntiAlias = 1 << 4;
  static const int strokeCap = 1 << 5;
  static const int strokeJoin = 1 << 6;
  static const int miterLimit = 1 << 7;
}
