import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dunebox_protocol/dunebox_protocol.dart';
import 'object_registry.dart';

/// Binary decoder for parsing and executing Canvas commands
/// 
/// Decodes command buffers from guest modules and executes them on a real Canvas.
/// Uses zero-copy parsing with ByteData.view for performance.
class BinaryDecoder {
  final ObjectRegistry _registry;
  
  BinaryDecoder(this._registry);
  
  /// Decode and execute all commands in buffer
  /// 
  /// Returns the number of commands processed.
  /// Throws [UnsupportedVersionException] if protocol version is not supported.
  /// Throws [UnknownOpCodeException] if an unknown OpCode is encountered.
  /// Throws [FormatException] if buffer is malformed or has insufficient data.
  int decode(Uint8List buffer, ui.Canvas canvas) {
    if (buffer.isEmpty) {
      throw FormatException('Command buffer is empty');
    }
    
    // Check protocol version
    final version = buffer[0];
    if (version != OpCode.protocolVersion) {
      throw UnsupportedVersionException(version);
    }
    
    int offset = 1;
    int commandCount = 0;
    
    // Parse and execute commands
    while (offset < buffer.length) {
      offset = _decodeCommand(buffer, offset, canvas);
      commandCount++;
    }
    
    return commandCount;
  }
  
  /// Decode single command at offset
  /// 
  /// Returns new offset after command.
  int _decodeCommand(Uint8List buffer, int offset, ui.Canvas canvas) {
    if (offset >= buffer.length) {
      throw FormatException('Unexpected end of buffer at offset $offset');
    }
    
    final opCode = buffer[offset];
    final opCodeOffset = offset;
    offset++;
    
    try {
      switch (opCode) {
        // Primitive drawing operations
        case OpCode.drawRect:
          return _decodeDrawRect(buffer, offset, canvas);
        case OpCode.drawCircle:
          return _decodeDrawCircle(buffer, offset, canvas);
        case OpCode.drawLine:
          return _decodeDrawLine(buffer, offset, canvas);
        case OpCode.drawPath:
          return _decodeDrawPath(buffer, offset, canvas);
        
        // Canvas state operations
        case OpCode.save:
          canvas.save();
          return offset;
        case OpCode.restore:
          canvas.restore();
          return offset;
        case OpCode.translate:
          return _decodeTranslate(buffer, offset, canvas);
        case OpCode.scale:
          return _decodeScale(buffer, offset, canvas);
        case OpCode.rotate:
          return _decodeRotate(buffer, offset, canvas);
        
        // Paint object management
        case OpCode.createPaint:
          return _decodeCreatePaint(buffer, offset);
        case OpCode.updatePaint:
          return _decodeUpdatePaint(buffer, offset);
        case OpCode.disposePaint:
          return _decodeDisposePaint(buffer, offset);
        
        // Path object management
        case OpCode.createPath:
          return _decodeCreatePath(buffer, offset);
        case OpCode.disposePath:
          return _decodeDisposePath(buffer, offset);
        
        default:
          throw UnknownOpCodeException(opCode, opCodeOffset);
      }
    } catch (e) {
      if (e is UnknownOpCodeException || e is FormatException || e is ObjectNotFoundException) {
        rethrow;
      }
      // Wrap other exceptions with context
      throw DecodingException(
        'Error decoding command: $e',
        opCode: opCode,
        offset: opCodeOffset,
      );
    }
  }
  
  // ========== Primitive Drawing Command Decoders ==========
  
  /// Decode drawRect command
  /// Payload: x (f32) + y (f32) + width (f32) + height (f32) + paint_id (u32)
  int _decodeDrawRect(Uint8List buffer, int offset, ui.Canvas canvas) {
    _checkBufferSize(buffer, offset, 20, 'drawRect', OpCode.drawRect);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final x = data.getFloat32(0, Endian.little);
    final y = data.getFloat32(4, Endian.little);
    final width = data.getFloat32(8, Endian.little);
    final height = data.getFloat32(12, Endian.little);
    final paintId = data.getUint32(16, Endian.little);
    
    final paint = _registry.getPaint(paintId);
    canvas.drawRect(ui.Rect.fromLTWH(x, y, width, height), paint);
    
    return offset + 20;
  }
  
  /// Decode drawCircle command
  /// Payload: cx (f32) + cy (f32) + radius (f32) + paint_id (u32)
  int _decodeDrawCircle(Uint8List buffer, int offset, ui.Canvas canvas) {
    _checkBufferSize(buffer, offset, 16, 'drawCircle', OpCode.drawCircle);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final cx = data.getFloat32(0, Endian.little);
    final cy = data.getFloat32(4, Endian.little);
    final radius = data.getFloat32(8, Endian.little);
    final paintId = data.getUint32(12, Endian.little);
    
    final paint = _registry.getPaint(paintId);
    canvas.drawCircle(ui.Offset(cx, cy), radius, paint);
    
    return offset + 16;
  }
  
  /// Decode drawLine command
  /// Payload: x1 (f32) + y1 (f32) + x2 (f32) + y2 (f32) + paint_id (u32)
  int _decodeDrawLine(Uint8List buffer, int offset, ui.Canvas canvas) {
    _checkBufferSize(buffer, offset, 20, 'drawLine', OpCode.drawLine);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final x1 = data.getFloat32(0, Endian.little);
    final y1 = data.getFloat32(4, Endian.little);
    final x2 = data.getFloat32(8, Endian.little);
    final y2 = data.getFloat32(12, Endian.little);
    final paintId = data.getUint32(16, Endian.little);
    
    final paint = _registry.getPaint(paintId);
    canvas.drawLine(ui.Offset(x1, y1), ui.Offset(x2, y2), paint);
    
    return offset + 20;
  }
  
  /// Decode drawPath command
  /// Payload: path_id (u32) + paint_id (u32)
  int _decodeDrawPath(Uint8List buffer, int offset, ui.Canvas canvas) {
    _checkBufferSize(buffer, offset, 8, 'drawPath', OpCode.drawPath);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final pathId = data.getUint32(0, Endian.little);
    final paintId = data.getUint32(4, Endian.little);
    
    final path = _registry.getPath(pathId);
    final paint = _registry.getPaint(paintId);
    canvas.drawPath(path, paint);
    
    return offset + 8;
  }
  
  // ========== Canvas State Command Decoders ==========
  
  /// Decode translate command
  /// Payload: dx (f32) + dy (f32)
  int _decodeTranslate(Uint8List buffer, int offset, ui.Canvas canvas) {
    _checkBufferSize(buffer, offset, 8, 'translate', OpCode.translate);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final dx = data.getFloat32(0, Endian.little);
    final dy = data.getFloat32(4, Endian.little);
    
    canvas.translate(dx, dy);
    
    return offset + 8;
  }
  
  /// Decode scale command
  /// Payload: sx (f32) + sy (f32)
  int _decodeScale(Uint8List buffer, int offset, ui.Canvas canvas) {
    _checkBufferSize(buffer, offset, 8, 'scale', OpCode.scale);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final sx = data.getFloat32(0, Endian.little);
    final sy = data.getFloat32(4, Endian.little);
    
    canvas.scale(sx, sy);
    
    return offset + 8;
  }
  
  /// Decode rotate command
  /// Payload: radians (f32)
  int _decodeRotate(Uint8List buffer, int offset, ui.Canvas canvas) {
    _checkBufferSize(buffer, offset, 4, 'rotate', OpCode.rotate);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final radians = data.getFloat32(0, Endian.little);
    
    canvas.rotate(radians);
    
    return offset + 4;
  }
  
  // ========== Paint Object Command Decoders ==========
  
  /// Decode createPaint command
  /// Payload: paint_id (u32) + color (u32) + stroke_width (f32) + style (u8) + 
  ///          blend_mode (u8) + is_anti_alias (u8) + stroke_cap (u8) + 
  ///          stroke_join (u8) + miter_limit (f32)
  int _decodeCreatePaint(Uint8List buffer, int offset) {
    _checkBufferSize(buffer, offset, 22, 'createPaint', OpCode.createPaint);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final paintId = data.getUint32(0, Endian.little);
    final colorValue = data.getUint32(4, Endian.little);
    final strokeWidth = data.getFloat32(8, Endian.little);
    final styleValue = data.getUint8(12);
    final blendModeValue = data.getUint8(13);
    final isAntiAlias = data.getUint8(14) != 0;
    final strokeCapValue = data.getUint8(15);
    final strokeJoinValue = data.getUint8(16);
    final miterLimit = data.getFloat32(17, Endian.little);
    
    // Create Paint object
    final paint = ui.Paint()
      ..color = ui.Color(colorValue)
      ..strokeWidth = strokeWidth
      ..style = _decodePaintingStyle(styleValue)
      ..blendMode = _decodeBlendMode(blendModeValue)
      ..isAntiAlias = isAntiAlias
      ..strokeCap = _decodeStrokeCap(strokeCapValue)
      ..strokeJoin = _decodeStrokeJoin(strokeJoinValue)
      ..strokeMiterLimit = miterLimit;
    
    _registry.registerPaint(paintId, paint);
    
    return offset + 22;
  }
  
  /// Decode updatePaint command
  /// Payload: paint_id (u32) + field_mask (u8) + updated fields
  int _decodeUpdatePaint(Uint8List buffer, int offset) {
    _checkBufferSize(buffer, offset, 5, 'updatePaint', OpCode.updatePaint);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final paintId = data.getUint32(0, Endian.little);
    final fieldMask = data.getUint8(4);
    
    final paint = _registry.getPaint(paintId);
    int fieldOffset = offset + 5;
    
    // Update fields based on mask
    if (fieldMask & PaintFieldMask.color != 0) {
      _checkBufferSize(buffer, fieldOffset, 4, 'updatePaint.color', OpCode.updatePaint);
      final colorValue = ByteData.view(buffer.buffer, buffer.offsetInBytes + fieldOffset)
          .getUint32(0, Endian.little);
      paint.color = ui.Color(colorValue);
      fieldOffset += 4;
    }
    
    if (fieldMask & PaintFieldMask.strokeWidth != 0) {
      _checkBufferSize(buffer, fieldOffset, 4, 'updatePaint.strokeWidth', OpCode.updatePaint);
      final strokeWidth = ByteData.view(buffer.buffer, buffer.offsetInBytes + fieldOffset)
          .getFloat32(0, Endian.little);
      paint.strokeWidth = strokeWidth;
      fieldOffset += 4;
    }
    
    if (fieldMask & PaintFieldMask.style != 0) {
      _checkBufferSize(buffer, fieldOffset, 1, 'updatePaint.style', OpCode.updatePaint);
      final styleValue = buffer[fieldOffset];
      paint.style = _decodePaintingStyle(styleValue);
      fieldOffset += 1;
    }
    
    if (fieldMask & PaintFieldMask.blendMode != 0) {
      _checkBufferSize(buffer, fieldOffset, 1, 'updatePaint.blendMode', OpCode.updatePaint);
      final blendModeValue = buffer[fieldOffset];
      paint.blendMode = _decodeBlendMode(blendModeValue);
      fieldOffset += 1;
    }
    
    if (fieldMask & PaintFieldMask.isAntiAlias != 0) {
      _checkBufferSize(buffer, fieldOffset, 1, 'updatePaint.isAntiAlias', OpCode.updatePaint);
      paint.isAntiAlias = buffer[fieldOffset] != 0;
      fieldOffset += 1;
    }
    
    if (fieldMask & PaintFieldMask.strokeCap != 0) {
      _checkBufferSize(buffer, fieldOffset, 1, 'updatePaint.strokeCap', OpCode.updatePaint);
      final strokeCapValue = buffer[fieldOffset];
      paint.strokeCap = _decodeStrokeCap(strokeCapValue);
      fieldOffset += 1;
    }
    
    if (fieldMask & PaintFieldMask.strokeJoin != 0) {
      _checkBufferSize(buffer, fieldOffset, 1, 'updatePaint.strokeJoin', OpCode.updatePaint);
      final strokeJoinValue = buffer[fieldOffset];
      paint.strokeJoin = _decodeStrokeJoin(strokeJoinValue);
      fieldOffset += 1;
    }
    
    if (fieldMask & PaintFieldMask.miterLimit != 0) {
      _checkBufferSize(buffer, fieldOffset, 4, 'updatePaint.miterLimit', OpCode.updatePaint);
      final miterLimit = ByteData.view(buffer.buffer, buffer.offsetInBytes + fieldOffset)
          .getFloat32(0, Endian.little);
      paint.strokeMiterLimit = miterLimit;
      fieldOffset += 4;
    }
    
    return fieldOffset;
  }
  
  /// Decode disposePaint command
  /// Payload: paint_id (u32)
  int _decodeDisposePaint(Uint8List buffer, int offset) {
    _checkBufferSize(buffer, offset, 4, 'disposePaint', OpCode.disposePaint);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final paintId = data.getUint32(0, Endian.little);
    
    _registry.disposePaint(paintId);
    
    return offset + 4;
  }
  
  // ========== Path Object Command Decoders ==========
  
  /// Decode createPath command
  /// Payload: path_id (u32) + command_count (u16) + path_commands
  int _decodeCreatePath(Uint8List buffer, int offset) {
    _checkBufferSize(buffer, offset, 6, 'createPath', OpCode.createPath);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final pathId = data.getUint32(0, Endian.little);
    final commandCount = data.getUint16(4, Endian.little);
    
    final path = ui.Path();
    int cmdOffset = offset + 6;
    
    // Decode and execute path commands
    for (int i = 0; i < commandCount; i++) {
      cmdOffset = _decodePathCommand(buffer, cmdOffset, path);
    }
    
    _registry.registerPath(pathId, path);
    
    return cmdOffset;
  }
  
  /// Decode single path command
  int _decodePathCommand(Uint8List buffer, int offset, ui.Path path) {
    if (offset >= buffer.length) {
      throw FormatException('Unexpected end of buffer in path command at offset $offset');
    }
    
    final cmdType = buffer[offset];
    offset++;
    
    switch (cmdType) {
      case 0x01: // moveTo
        _checkBufferSize(buffer, offset, 8, 'path.moveTo', OpCode.createPath);
        final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
        final x = data.getFloat32(0, Endian.little);
        final y = data.getFloat32(4, Endian.little);
        path.moveTo(x, y);
        return offset + 8;
      
      case 0x02: // lineTo
        _checkBufferSize(buffer, offset, 8, 'path.lineTo', OpCode.createPath);
        final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
        final x = data.getFloat32(0, Endian.little);
        final y = data.getFloat32(4, Endian.little);
        path.lineTo(x, y);
        return offset + 8;
      
      case 0x03: // quadraticBezierTo
        _checkBufferSize(buffer, offset, 16, 'path.quadraticBezierTo', OpCode.createPath);
        final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
        final x1 = data.getFloat32(0, Endian.little);
        final y1 = data.getFloat32(4, Endian.little);
        final x2 = data.getFloat32(8, Endian.little);
        final y2 = data.getFloat32(12, Endian.little);
        path.quadraticBezierTo(x1, y1, x2, y2);
        return offset + 16;
      
      case 0x04: // cubicTo
        _checkBufferSize(buffer, offset, 24, 'path.cubicTo', OpCode.createPath);
        final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
        final x1 = data.getFloat32(0, Endian.little);
        final y1 = data.getFloat32(4, Endian.little);
        final x2 = data.getFloat32(8, Endian.little);
        final y2 = data.getFloat32(12, Endian.little);
        final x3 = data.getFloat32(16, Endian.little);
        final y3 = data.getFloat32(20, Endian.little);
        path.cubicTo(x1, y1, x2, y2, x3, y3);
        return offset + 24;
      
      case 0x05: // close
        path.close();
        return offset;
      
      case 0x10: // addRect
        _checkBufferSize(buffer, offset, 16, 'path.addRect', OpCode.createPath);
        final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
        final left = data.getFloat32(0, Endian.little);
        final top = data.getFloat32(4, Endian.little);
        final right = data.getFloat32(8, Endian.little);
        final bottom = data.getFloat32(12, Endian.little);
        path.addRect(ui.Rect.fromLTRB(left, top, right, bottom));
        return offset + 16;
      
      case 0x11: // addOval
        _checkBufferSize(buffer, offset, 16, 'path.addOval', OpCode.createPath);
        final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
        final left = data.getFloat32(0, Endian.little);
        final top = data.getFloat32(4, Endian.little);
        final right = data.getFloat32(8, Endian.little);
        final bottom = data.getFloat32(12, Endian.little);
        path.addOval(ui.Rect.fromLTRB(left, top, right, bottom));
        return offset + 16;
      
      default:
        throw FormatException('Unknown path command type: 0x${cmdType.toRadixString(16)} at offset ${offset - 1}');
    }
  }
  
  /// Decode disposePath command
  /// Payload: path_id (u32)
  int _decodeDisposePath(Uint8List buffer, int offset) {
    _checkBufferSize(buffer, offset, 4, 'disposePath', OpCode.disposePath);
    
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset);
    final pathId = data.getUint32(0, Endian.little);
    
    _registry.disposePath(pathId);
    
    return offset + 4;
  }
  
  // ========== Helper Methods ==========
  
  /// Check if buffer has enough bytes remaining
  void _checkBufferSize(Uint8List buffer, int offset, int required, String command, int opCode) {
    if (offset + required > buffer.length) {
      throw FormatException(
        'Insufficient data for $command: expected $required bytes, '
        'but only ${buffer.length - offset} bytes remaining at offset $offset '
        '(OpCode: 0x${opCode.toRadixString(16)})'
      );
    }
  }
  
  /// Decode PaintingStyle from u8
  ui.PaintingStyle _decodePaintingStyle(int value) {
    final styleEnum = PaintingStyleEnum.fromValue(value);
    switch (styleEnum) {
      case PaintingStyleEnum.fill:
        return ui.PaintingStyle.fill;
      case PaintingStyleEnum.stroke:
        return ui.PaintingStyle.stroke;
    }
  }
  
  /// Decode BlendMode from u8
  ui.BlendMode _decodeBlendMode(int value) {
    final blendModeEnum = BlendModeEnum.fromValue(value);
    return ui.BlendMode.values[blendModeEnum.value];
  }
  
  /// Decode StrokeCap from u8
  ui.StrokeCap _decodeStrokeCap(int value) {
    final strokeCapEnum = StrokeCapEnum.fromValue(value);
    switch (strokeCapEnum) {
      case StrokeCapEnum.butt:
        return ui.StrokeCap.butt;
      case StrokeCapEnum.round:
        return ui.StrokeCap.round;
      case StrokeCapEnum.square:
        return ui.StrokeCap.square;
    }
  }
  
  /// Decode StrokeJoin from u8
  ui.StrokeJoin _decodeStrokeJoin(int value) {
    final strokeJoinEnum = StrokeJoinEnum.fromValue(value);
    switch (strokeJoinEnum) {
      case StrokeJoinEnum.miter:
        return ui.StrokeJoin.miter;
      case StrokeJoinEnum.round:
        return ui.StrokeJoin.round;
      case StrokeJoinEnum.bevel:
        return ui.StrokeJoin.bevel;
    }
  }
}
