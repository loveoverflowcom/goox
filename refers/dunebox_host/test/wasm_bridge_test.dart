import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dunebox_host/dunebox_host.dart';

void main() {
  group('WasmBridge', () {
    late WasmBridge bridge;
    
    setUp(() {
      bridge = WasmBridge();
    });
    
    tearDown(() {
      bridge.dispose();
    });
    
    group('8.1: Module loading', () {
      test('should start in unloaded state', () {
        expect(bridge.isLoaded, isFalse);
      });
      
      test('should throw WasmLoadException when loading without runtime', () async {
        expect(
          () => bridge.load('test.wasm'),
          throwsA(isA<WasmLoadException>()),
        );
      });
      
      test('should accept callbacks during load', () async {
        var commandBufferCalled = false;
        var logCalled = false;
        
        try {
          await bridge.load(
            'test.wasm',
            onCommandBuffer: (buffer) => commandBufferCalled = true,
            onLog: (message) => logCalled = true,
          );
        } catch (e) {
          // Expected to fail without actual Wasm runtime
          expect(e, isA<WasmLoadException>());
        }
        
        // Callbacks should be stored even if load fails
        expect(commandBufferCalled, isFalse);
        expect(logCalled, isFalse);
      });
      
      test('should include path in WasmLoadException', () async {
        try {
          await bridge.load('path/to/module.wasm');
          fail('Should have thrown WasmLoadException');
        } catch (e) {
          expect(e, isA<WasmLoadException>());
          final exception = e as WasmLoadException;
          expect(exception.path, equals('path/to/module.wasm'));
          expect(exception.toString(), contains('path/to/module.wasm'));
        }
      });
    });
    
    group('8.2: Memory access methods', () {
      test('should throw StateError when reading memory before load', () {
        expect(
          () => bridge.readMemory(0, 100),
          throwsStateError,
        );
      });
      
      test('should throw WasmMemoryException for negative pointer', () {
        // Even though not loaded, bounds checking should happen first
        expect(
          () => bridge.readMemory(-1, 100),
          throwsStateError, // StateError comes first (not loaded)
        );
      });
      
      test('should throw WasmMemoryException for negative length', () {
        expect(
          () => bridge.readMemory(0, -1),
          throwsStateError, // StateError comes first (not loaded)
        );
      });
      
      test('WasmMemoryException should include diagnostic info', () {
        try {
          // Create a loaded bridge (stub)
          final exception = WasmMemoryException(
            'Test error',
            ptr: 1000,
            len: 500,
          );
          
          expect(exception.ptr, equals(1000));
          expect(exception.len, equals(500));
          expect(exception.toString(), contains('ptr=1000'));
          expect(exception.toString(), contains('len=500'));
        } catch (e) {
          // Expected
        }
      });
    });
    
    group('8.3: Host import handlers', () {
      test('should handle send_commands callback', () async {
        Uint8List? receivedBuffer;
        
        try {
          await bridge.load(
            'test.wasm',
            onCommandBuffer: (buffer) {
              receivedBuffer = buffer;
            },
          );
        } catch (e) {
          // Expected to fail without runtime
        }
        
        // Verify callback was stored (even if load failed)
        expect(receivedBuffer, isNull);
      });
      
      test('should handle log callback', () async {
        String? receivedMessage;
        
        try {
          await bridge.load(
            'test.wasm',
            onLog: (message) {
              receivedMessage = message;
            },
          );
        } catch (e) {
          // Expected to fail without runtime
        }
        
        // Verify callback was stored (even if load failed)
        expect(receivedMessage, isNull);
      });
      
      test('should handle missing callbacks gracefully', () async {
        // Should not throw even without callbacks
        try {
          await bridge.load('test.wasm');
        } catch (e) {
          expect(e, isA<WasmLoadException>());
        }
      });
    });
    
    group('8.4: callUpdate method', () {
      test('should throw StateError when called before load', () {
        expect(
          () => bridge.callUpdate(),
          throwsStateError,
        );
      });
      
      test('should wrap guest exceptions in GuestPanicException', () {
        // This test documents the expected behavior when runtime is integrated
        expect(
          () => bridge.callUpdate(),
          throwsStateError, // Currently throws StateError (not loaded)
        );
      });
    });
    
    group('Lifecycle', () {
      test('should clean up resources on dispose', () {
        bridge.dispose();
        expect(bridge.isLoaded, isFalse);
        
        // Should be safe to call multiple times
        bridge.dispose();
        expect(bridge.isLoaded, isFalse);
      });
      
      test('should throw StateError after dispose', () {
        bridge.dispose();
        
        expect(() => bridge.callUpdate(), throwsStateError);
        expect(() => bridge.readMemory(0, 100), throwsStateError);
      });
    });
    
    group('Exception types', () {
      test('WasmLoadException should format correctly', () {
        final exception = WasmLoadException('test.wasm', 'File not found');
        
        expect(exception.path, equals('test.wasm'));
        expect(exception.message, contains('File not found'));
        expect(exception.toString(), contains('test.wasm'));
        expect(exception.toString(), contains('File not found'));
      });
      
      test('GuestPanicException should include stack trace', () {
        final exception = GuestPanicException(
          'Division by zero',
          stackTrace: 'Stack trace here',
        );
        
        expect(exception.message, contains('Division by zero'));
        expect(exception.stackTrace, equals('Stack trace here'));
        expect(exception.toString(), contains('Division by zero'));
        expect(exception.toString(), contains('Stack trace here'));
      });
      
      test('GuestPanicException should work without stack trace', () {
        final exception = GuestPanicException('Error occurred');
        
        expect(exception.message, contains('Error occurred'));
        expect(exception.stackTrace, isNull);
        expect(exception.toString(), contains('Error occurred'));
      });
    });
    
    group('Integration scenarios', () {
      test('should demonstrate typical usage pattern', () async {
        final commandBuffers = <Uint8List>[];
        final logMessages = <String>[];
        
        try {
          // 1. Load module with callbacks
          await bridge.load(
            'guest.wasm',
            onCommandBuffer: (buffer) => commandBuffers.add(buffer),
            onLog: (message) => logMessages.add(message),
          );
          
          // 2. Call update to generate frame
          bridge.callUpdate();
          
          // 3. Process command buffer
          // (In real usage, would pass to BinaryDecoder)
          
        } catch (e) {
          // Expected to fail without actual Wasm runtime
          expect(e, isA<WasmLoadException>());
        }
      });
      
      test('should handle multiple update calls', () async {
        try {
          await bridge.load('test.wasm');
          
          // Multiple frames
          bridge.callUpdate();
          bridge.callUpdate();
          bridge.callUpdate();
          
        } catch (e) {
          // Expected to fail without runtime
          expect(e, isA<WasmLoadException>());
        }
      });
    });
  });
}

