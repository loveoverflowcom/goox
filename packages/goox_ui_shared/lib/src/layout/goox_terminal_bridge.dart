import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:goox_flutter_bridge/goox_flutter_bridge.dart';

class RustTerminalCellSnapshot {
  RustTerminalCellSnapshot({
    required this.ch,
    required this.bold,
    this.fg,
    this.bg,
  });

  factory RustTerminalCellSnapshot.fromJson(Map<String, dynamic> json) {
    return RustTerminalCellSnapshot(
      ch: (json['ch'] as String?) ?? ' ',
      fg: (json['fg'] as num?)?.toInt(),
      bg: (json['bg'] as num?)?.toInt(),
      bold: json['bold'] as bool? ?? false,
    );
  }

  final String ch;
  final int? fg;
  final int? bg;
  final bool bold;
}

class RustTerminalRowSnapshot {
  RustTerminalRowSnapshot({required this.cells});

  factory RustTerminalRowSnapshot.fromJson(Map<String, dynamic> json) {
    final rawCells = (json['cells'] as List<dynamic>? ?? const <dynamic>[]);
    return RustTerminalRowSnapshot(
      cells: rawCells
          .map(
            (entry) => RustTerminalCellSnapshot.fromJson(
              (entry as Map).cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
    );
  }

  final List<RustTerminalCellSnapshot> cells;
}

class RustTerminalScreenSnapshot {
  RustTerminalScreenSnapshot({
    required this.terminalId,
    required this.generation,
    required this.rows,
    required this.cols,
    required this.cursorX,
    required this.cursorY,
    required this.isAlternateScreen,
    required this.cursorVisible,
    required this.exited,
    required this.grid,
    this.exitCode,
    this.exitMessage,
  });

  factory RustTerminalScreenSnapshot.fromJson(Map<String, dynamic> json) {
    final rawRows = (json['grid'] as List<dynamic>? ?? const <dynamic>[]);
    return RustTerminalScreenSnapshot(
      terminalId: (json['terminalId'] as num?)?.toInt() ?? 0,
      generation: (json['generation'] as num?)?.toInt() ?? 0,
      rows: (json['rows'] as num?)?.toInt() ?? 0,
      cols: (json['cols'] as num?)?.toInt() ?? 0,
      cursorX: (json['cursorX'] as num?)?.toInt() ?? 0,
      cursorY: (json['cursorY'] as num?)?.toInt() ?? 0,
      isAlternateScreen: json['isAlternateScreen'] as bool? ?? false,
      cursorVisible: json['cursorVisible'] as bool? ?? true,
      exited: json['exited'] as bool? ?? false,
      exitCode: (json['exitCode'] as num?)?.toInt(),
      exitMessage: json['exitMessage'] as String?,
      grid: rawRows
          .map(
            (entry) => RustTerminalRowSnapshot.fromJson(
              (entry as Map).cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
    );
  }

  final int terminalId;
  final int generation;
  final int rows;
  final int cols;
  final int cursorX;
  final int cursorY;
  final bool isAlternateScreen;
  final bool cursorVisible;
  final bool exited;
  final int? exitCode;
  final String? exitMessage;
  final List<RustTerminalRowSnapshot> grid;
}

typedef _GooxTerminalCreateNative =
    Uint64 Function(Uint16 rows, Uint16 cols, Pointer<Utf8> workingDirectory);
typedef _GooxTerminalCreateDart =
    int Function(int rows, int cols, Pointer<Utf8> workingDirectory);

typedef _GooxTerminalSendNative =
    Bool Function(Uint64 id, Pointer<Uint8> bytes, IntPtr len);
typedef _GooxTerminalSendDart =
    bool Function(int id, Pointer<Uint8> bytes, int len);

typedef _GooxTerminalPollNative = Pointer<Utf8> Function(Uint64 id);
typedef _GooxTerminalPollDart = Pointer<Utf8> Function(int id);

typedef _GooxTerminalResizeNative =
    Bool Function(Uint64 id, Uint16 rows, Uint16 cols);
typedef _GooxTerminalResizeDart = bool Function(int id, int rows, int cols);

typedef _GooxTerminalDisposeNative = Void Function(Uint64 id);
typedef _GooxTerminalDisposeDart = void Function(int id);

typedef _GooxTerminalFreeStringNative = Void Function(Pointer<Utf8> value);
typedef _GooxTerminalFreeStringDart = void Function(Pointer<Utf8> value);

final class RustTerminalBridge {
  RustTerminalBridge._(this._library) {
    _create = _library
        .lookupFunction<_GooxTerminalCreateNative, _GooxTerminalCreateDart>(
          'goox_terminal_create',
        );
    _sendInput = _library
        .lookupFunction<_GooxTerminalSendNative, _GooxTerminalSendDart>(
          'goox_terminal_send_input',
        );
    _pollScreenJson = _library
        .lookupFunction<_GooxTerminalPollNative, _GooxTerminalPollDart>(
          'goox_terminal_poll_screen_json',
        );
    _resize = _library
        .lookupFunction<_GooxTerminalResizeNative, _GooxTerminalResizeDart>(
          'goox_terminal_resize',
        );
    _dispose = _library
        .lookupFunction<_GooxTerminalDisposeNative, _GooxTerminalDisposeDart>(
          'goox_terminal_dispose',
        );
    _freeString = _library
        .lookupFunction<
          _GooxTerminalFreeStringNative,
          _GooxTerminalFreeStringDart
        >('goox_terminal_free_string');
  }

  static RustTerminalBridge? _instance;

  final DynamicLibrary _library;
  late final _GooxTerminalCreateDart _create;
  late final _GooxTerminalSendDart _sendInput;
  late final _GooxTerminalPollDart _pollScreenJson;
  late final _GooxTerminalResizeDart _resize;
  late final _GooxTerminalDisposeDart _dispose;
  late final _GooxTerminalFreeStringDart _freeString;

  static Future<RustTerminalBridge> instance() async {
    if (_instance != null) {
      return _instance!;
    }

    await GooxRustBootstrap.ensureInitialized();
    final libraryPath = GooxRustBootstrap.nativeLibraryPath;
    if (libraryPath == null) {
      throw StateError('Goox Rust library path is unavailable');
    }

    _instance = RustTerminalBridge._(DynamicLibrary.open(libraryPath));
    return _instance!;
  }

  int createTerminal({
    required int rows,
    required int cols,
    String? workingDirectory,
  }) {
    final directoryPtr = workingDirectory == null
        ? nullptr
        : workingDirectory.toNativeUtf8();

    try {
      final terminalId = _create(rows, cols, directoryPtr);
      if (terminalId == 0) {
        throw StateError('Rust terminal creation failed');
      }
      return terminalId;
    } finally {
      if (directoryPtr.address != 0) {
        malloc.free(directoryPtr);
      }
    }
  }

  bool sendInput(int id, Uint8List bytes) {
    if (bytes.isEmpty) {
      return true;
    }

    final pointer = calloc<Uint8>(bytes.length);
    try {
      final buffer = pointer.asTypedList(bytes.length);
      buffer.setAll(0, bytes);
      return _sendInput(id, pointer, bytes.length);
    } finally {
      calloc.free(pointer);
    }
  }

  RustTerminalScreenSnapshot pollScreen(int id) {
    final pointer = _pollScreenJson(id);
    if (pointer == nullptr) {
      throw StateError('Rust terminal snapshot is unavailable');
    }

    try {
      final json = pointer.toDartString();
      return RustTerminalScreenSnapshot.fromJson(
        (jsonDecode(json) as Map).cast<String, dynamic>(),
      );
    } finally {
      _freeString(pointer);
    }
  }

  bool resize(int id, {required int rows, required int cols}) =>
      _resize(id, rows, cols);

  void dispose(int id) {
    _dispose(id);
  }
}
