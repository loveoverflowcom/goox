import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'binary_decoder.dart';
import 'object_registry.dart';
import 'wasm_bridge.dart';

/// CustomPainter that renders DuneBox guest output
/// 
/// This painter calls the guest update() function each frame,
/// receives the command buffer, decodes it, and executes the
/// commands on the real Canvas.
class DuneBoxPainter extends CustomPainter {
  final WasmBridge wasmBridge;
  final BinaryDecoder decoder;
  final ObjectRegistry registry;
  final bool debugMode;
  
  Uint8List? _lastCommandBuffer;
  
  DuneBoxPainter({
    required this.wasmBridge,
    required this.decoder,
    required this.registry,
    this.debugMode = false,
  });
  
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    // Clear canvas to black
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.width, size.height),
      ui.Paint()..color = const ui.Color(0xFF000000),
    );
    
    // Call guest update() and process command buffer
    try {
      // Call guest update() - this will trigger send_commands callback
      wasmBridge.callUpdate();
      
      // Process the command buffer if we received one
      if (_lastCommandBuffer != null) {
        final commandCount = decoder.decode(_lastCommandBuffer!, canvas);
        
        if (debugMode) {
          print('DuneBoxPainter: Processed $commandCount commands');
        }
        
        _lastCommandBuffer = null;
      }
    } catch (e, stackTrace) {
      // Log error with full context
      print('ERROR: DuneBoxPainter failed to render frame');
      print('  Error: $e');
      print('  Stack trace: $stackTrace');
      
      // Draw error overlay
      _drawErrorOverlay(canvas, size, e.toString());
    }
  }
  
  /// Called by WasmBridge when guest calls send_commands
  void onCommandBuffer(Uint8List buffer) {
    _lastCommandBuffer = buffer;
    
    if (debugMode) {
      print('DuneBoxPainter: Received command buffer (${buffer.length} bytes)');
    }
  }
  
  /// Called by WasmBridge when guest calls log
  void onLog(String message) {
    print('GUEST LOG: $message');
  }
  
  /// Draw error overlay when guest crashes or decoder fails
  void _drawErrorOverlay(ui.Canvas canvas, ui.Size size, String error) {
    // Draw semi-transparent red background
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.width, size.height),
      ui.Paint()..color = const ui.Color(0x80FF0000),
    );
    
    // Draw error text
    final textStyle = ui.TextStyle(
      color: const ui.Color(0xFFFFFFFF),
      fontSize: 14,
      fontFamily: 'monospace',
    );
    
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: ui.TextAlign.left,
      fontSize: 14,
    );
    
    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText('ERROR: Guest module crashed\n\n')
      ..addText(error);
    
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: size.width - 20));
    
    canvas.drawParagraph(paragraph, const ui.Offset(10, 10));
  }
  
  @override
  bool shouldRepaint(DuneBoxPainter oldDelegate) {
    // Always repaint to maintain animation loop
    return true;
  }
}
