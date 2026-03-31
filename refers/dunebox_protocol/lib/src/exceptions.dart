/// Exception classes for Binary Canvas Protocol

/// Base exception for protocol errors
abstract class ProtocolException implements Exception {
  final String message;
  
  const ProtocolException(this.message);
  
  @override
  String toString() => 'ProtocolException: $message';
}

/// Thrown when an unsupported protocol version is encountered
class UnsupportedVersionException extends ProtocolException {
  final int version;
  
  UnsupportedVersionException(this.version)
      : super('Unsupported protocol version: 0x${version.toRadixString(16)}');
  
  @override
  String toString() => 'UnsupportedVersionException: version=0x${version.toRadixString(16)}';
}

/// Thrown when an unknown OpCode is encountered
class UnknownOpCodeException extends ProtocolException {
  final int opCode;
  final int offset;
  
  UnknownOpCodeException(this.opCode, this.offset)
      : super('Unknown OpCode 0x${opCode.toRadixString(16)} at offset $offset');
  
  @override
  String toString() => 'UnknownOpCodeException: opCode=0x${opCode.toRadixString(16)}, offset=$offset';
}

/// Thrown when command buffer decoding fails
class DecodingException extends ProtocolException {
  final int? opCode;
  final int? offset;
  
  DecodingException(String message, {this.opCode, this.offset})
      : super(message);
  
  @override
  String toString() {
    final parts = ['DecodingException: $message'];
    if (opCode != null) parts.add('opCode=0x${opCode!.toRadixString(16)}');
    if (offset != null) parts.add('offset=$offset');
    return parts.join(', ');
  }
}

/// Thrown when an object is not found in registry
class ObjectNotFoundException extends ProtocolException {
  final String objectType;
  final int id;
  
  ObjectNotFoundException(this.objectType, this.id)
      : super('$objectType with ID $id not found');
  
  @override
  String toString() => 'ObjectNotFoundException: type=$objectType, id=$id';
}

/// Thrown when object type doesn't match expected type
class ObjectTypeMismatchException extends ProtocolException {
  final String expectedType;
  final String actualType;
  final int id;
  
  ObjectTypeMismatchException(this.expectedType, this.actualType, this.id)
      : super('Expected $expectedType but got $actualType for ID $id');
  
  @override
  String toString() => 'ObjectTypeMismatchException: expected=$expectedType, actual=$actualType, id=$id';
}

/// Thrown when Wasm memory access fails
class WasmMemoryException extends ProtocolException {
  final int? ptr;
  final int? len;
  
  WasmMemoryException(String message, {this.ptr, this.len})
      : super(message);
  
  @override
  String toString() {
    final parts = ['WasmMemoryException: $message'];
    if (ptr != null) parts.add('ptr=$ptr');
    if (len != null) parts.add('len=$len');
    return parts.join(', ');
  }
}

/// Thrown when Wasm module loading fails
class WasmLoadException extends ProtocolException {
  final String path;
  
  WasmLoadException(this.path, String message)
      : super('Failed to load Wasm module from $path: $message');
  
  @override
  String toString() => 'WasmLoadException: path=$path, message=$message';
}

/// Thrown when guest module panics
class GuestPanicException extends ProtocolException {
  final String? stackTrace;
  
  GuestPanicException(String message, {this.stackTrace})
      : super('Guest module panicked: $message');
  
  @override
  String toString() {
    if (stackTrace != null) {
      return 'GuestPanicException: $message\nStack trace:\n$stackTrace';
    }
    return 'GuestPanicException: $message';
  }
}
