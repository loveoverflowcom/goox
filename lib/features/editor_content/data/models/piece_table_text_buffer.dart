/// Piece-table text buffer optimized for append-only edits and cheap undo/redo.
///
/// The buffer keeps the original file content read-only and stores inserted text
/// in a separate add buffer. The logical document is represented by a list of
/// pieces that point into either buffer.
library;

enum BufferType { original, add }

/// A slice of text inside either the original or add buffer.
final class Piece {
  const Piece({
    required this.bufferType,
    required this.start,
    required this.length,
  });

  final BufferType bufferType;
  final int start;
  final int length;

  Piece copyWith({
    BufferType? bufferType,
    int? start,
    int? length,
  }) {
    return Piece(
      bufferType: bufferType ?? this.bufferType,
      start: start ?? this.start,
      length: length ?? this.length,
    );
  }
}

final class _EditRecord {
  const _EditRecord({
    required this.offset,
    required this.insertedText,
    required this.deletedText,
  });

  final int offset;
  final String insertedText;
  final String deletedText;

  bool get isInsertion => insertedText.isNotEmpty && deletedText.isEmpty;
  bool get isDeletion => deletedText.isNotEmpty && insertedText.isEmpty;
}

/// A piece-table buffer for large text files.
///
/// Notes:
/// - Offsets are measured in UTF-16 code units, matching Dart String indices.
/// - The original buffer is immutable after construction.
/// - The add buffer is append-only and stores inserted code units.
/// - Undo/redo is instant because edits are inverted as piece operations.
final class PieceTableTextBuffer {
  PieceTableTextBuffer._({
    required String originalBuffer,
  }) : _originalBuffer = originalBuffer,
       _length = originalBuffer.length {
    _pieces = <Piece>[
      if (originalBuffer.isNotEmpty)
        Piece(
          bufferType: BufferType.original,
          start: 0,
          length: originalBuffer.length,
        ),
    ];
    _rebuildLineIndex();
  }

  /// Creates a buffer from existing text.
  factory PieceTableTextBuffer.fromText(String text) {
    return PieceTableTextBuffer._(originalBuffer: text);
  }

  final String _originalBuffer;
  final List<int> _addBuffer = <int>[];
  late List<Piece> _pieces;
  final List<_EditRecord> _undoStack = <_EditRecord>[];
  final List<_EditRecord> _redoStack = <_EditRecord>[];
  int _length;

  bool _lineIndexDirty = true;
  List<int> _lineStarts = <int>[0];

  /// Number of UTF-16 code units in the logical document.
  int get length => _length;

  /// Number of logical lines in the current document.
  ///
  /// This is 1-based from the editor's point of view: an empty document still
  /// reports one line.
  int get lineCount {
    _ensureLineIndex();
    return _lineStarts.length;
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Inserts [text] at [offset].
  void insert(int offset, String text) {
    if (text.isEmpty) return;
    _validateOffset(offset);

    final start = _addBuffer.length;
    _addBuffer.addAll(text.codeUnits);

    _insertInternal(
      offset,
      Piece(
        bufferType: BufferType.add,
        start: start,
        length: text.length,
      ),
    );
    _length += text.length;

    _undoStack.add(
      _EditRecord(offset: offset, insertedText: text, deletedText: ''),
    );
    _redoStack.clear();
  }

  /// Deletes [length] code units starting at [offset].
  void delete(int offset, int length) {
    if (length <= 0) return;
    _validateRange(offset, length);

    final deletedText = getTextRange(offset, length);
    _deleteInternal(offset, length);
    _length -= length;

    _undoStack.add(
      _EditRecord(offset: offset, insertedText: '', deletedText: deletedText),
    );
    _redoStack.clear();
  }

  /// Reverts the last edit.
  bool undo() {
    if (_undoStack.isEmpty) return false;

    final record = _undoStack.removeLast();
    if (record.isInsertion) {
      _deleteInternal(record.offset, record.insertedText.length);
      _length -= record.insertedText.length;
    } else if (record.isDeletion) {
      _insertInternal(
        record.offset,
        Piece(
          bufferType: BufferType.add,
          start: _appendToAddBuffer(record.deletedText),
          length: record.deletedText.length,
        ),
      );
      _length += record.deletedText.length;
    }

    _redoStack.add(record);
    return true;
  }

  /// Re-applies the most recently undone edit.
  bool redo() {
    if (_redoStack.isEmpty) return false;

    final record = _redoStack.removeLast();
    if (record.isInsertion) {
      _insertInternal(
        record.offset,
        Piece(
          bufferType: BufferType.add,
          start: _appendToAddBuffer(record.insertedText),
          length: record.insertedText.length,
        ),
      );
      _length += record.insertedText.length;
    } else if (record.isDeletion) {
      _deleteInternal(record.offset, record.deletedText.length);
      _length -= record.deletedText.length;
    }

    _undoStack.add(record);
    return true;
  }

  /// Reconstructs the full document text.
  String getRawText() {
    final buffer = StringBuffer();

    for (final piece in _pieces) {
      buffer.write(_slicePiece(piece));
    }

    return buffer.toString();
  }

  /// Returns the line at [index], where [index] is zero-based.
  String getLine(int index) {
    _ensureLineIndex();

    if (index < 0 || index >= _lineStarts.length) {
      throw RangeError.range(index, 0, _lineStarts.length - 1, 'index');
    }

    final start = _lineStarts[index];
    final end = index + 1 < _lineStarts.length
        ? _lineStarts[index + 1] - 1
        : length;
    final lineLength = end - start;

    if (lineLength <= 0) return '';
    return getTextRange(start, lineLength);
  }

  /// Returns the line at [lineNumber], where [lineNumber] is one-based.
  String getLineAt(int lineNumber) => getLine(lineNumber - 1);

  /// Returns the text in the half-open range [offset, offset + length).
  String getTextRange(int offset, int length) {
    if (length <= 0) return '';
    _validateRange(offset, length);

    final result = StringBuffer();
    var remaining = length;
    var currentOffset = 0;

    for (final piece in _pieces) {
      final pieceEnd = currentOffset + piece.length;
      if (pieceEnd <= offset) {
        currentOffset = pieceEnd;
        continue;
      }

      final sliceStart = offset > currentOffset ? offset - currentOffset : 0;
      final sliceLength = (piece.length - sliceStart).clamp(0, remaining);

      if (sliceLength > 0) {
        result.write(_slicePiece(piece, sliceStart, sliceLength));
        remaining -= sliceLength;
        if (remaining == 0) break;
      }

      currentOffset = pieceEnd;
    }

    return result.toString();
  }

  void _insertInternal(int offset, Piece piece) {
    if (_pieces.isEmpty) {
      _pieces = <Piece>[piece];
      _markDirty();
      return;
    }

    final split = _splitAt(offset);
    _pieces.insert(split.index, piece);
    _mergeAround(split.index);
    _markDirty();
  }

  void _deleteInternal(int offset, int length) {
    if (length <= 0 || _pieces.isEmpty) return;

    final start = offset;
    final end = offset + length;
    final nextPieces = <Piece>[];
    var currentOffset = 0;

    for (final piece in _pieces) {
      final pieceStart = currentOffset;
      final pieceEnd = currentOffset + piece.length;

      if (pieceEnd <= start || pieceStart >= end) {
        nextPieces.add(piece);
      } else {
        if (pieceStart < start) {
          nextPieces.add(
            piece.copyWith(length: start - pieceStart),
          );
        }

        if (pieceEnd > end) {
          final suffixStart = piece.start + (end - pieceStart);
          nextPieces.add(
            piece.copyWith(
              start: suffixStart,
              length: pieceEnd - end,
            ),
          );
        }
      }

      currentOffset = pieceEnd;
    }

    _pieces = nextPieces;
    _mergeAll();
    _markDirty();
  }

  _SplitResult _splitAt(int offset) {
    if (offset <= 0) {
      return const _SplitResult(index: 0);
    }

    var currentOffset = 0;
    for (var i = 0; i < _pieces.length; i++) {
      final piece = _pieces[i];
      final pieceEnd = currentOffset + piece.length;

      if (offset == currentOffset) {
        return _SplitResult(index: i);
      }

      if (offset < pieceEnd) {
        final leftLength = offset - currentOffset;
        final rightLength = piece.length - leftLength;
        final rightStart = piece.start + leftLength;

        _pieces[i] = piece.copyWith(length: leftLength);
        _pieces.insert(
          i + 1,
          piece.copyWith(start: rightStart, length: rightLength),
        );
        return _SplitResult(index: i + 1);
      }

      currentOffset = pieceEnd;
    }

    return _SplitResult(index: _pieces.length);
  }

  void _mergeAround(int index) {
    if (_pieces.length < 2) return;

    final start = index.clamp(0, _pieces.length - 1);
    final begin = start > 0 ? start - 1 : 0;
    var i = begin;

    while (i < _pieces.length - 1) {
      final current = _pieces[i];
      final next = _pieces[i + 1];

      if (current.bufferType == next.bufferType &&
          current.start + current.length == next.start) {
        _pieces[i] = current.copyWith(length: current.length + next.length);
        _pieces.removeAt(i + 1);
        if (i > 0) {
          i -= 1;
        }
        continue;
      }

      i += 1;
    }
  }

  void _mergeAll() {
    if (_pieces.length < 2) return;

    final merged = <Piece>[];
    for (final piece in _pieces) {
      if (merged.isEmpty) {
        merged.add(piece);
        continue;
      }

      final last = merged.last;
      if (last.bufferType == piece.bufferType &&
          last.start + last.length == piece.start) {
        merged[merged.length - 1] = last.copyWith(
          length: last.length + piece.length,
        );
      } else {
        merged.add(piece);
      }
    }

    _pieces = merged;
  }

  String _slicePiece(Piece piece, [int startOffset = 0, int? sliceLength]) {
    final start = piece.start + startOffset;
    final length = sliceLength ?? (piece.length - startOffset);

    if (length <= 0) return '';

    switch (piece.bufferType) {
      case BufferType.original:
        return _originalBuffer.substring(start, start + length);
      case BufferType.add:
        return String.fromCharCodes(_addBuffer, start, start + length);
    }
  }

  int _appendToAddBuffer(String text) {
    final start = _addBuffer.length;
    _addBuffer.addAll(text.codeUnits);
    return start;
  }

  void _rebuildLineIndex() {
    _lineStarts = <int>[0];

    var offset = 0;
    for (final piece in _pieces) {
      final text = _slicePiece(piece);
      for (var i = 0; i < text.length; i++) {
        if (text.codeUnitAt(i) == 0x0A) {
          _lineStarts.add(offset + i + 1);
        }
      }
      offset += text.length;
    }

    if (_lineStarts.isEmpty) {
      _lineStarts = <int>[0];
    }

    _lineIndexDirty = false;
  }

  void _ensureLineIndex() {
    if (_lineIndexDirty) {
      _rebuildLineIndex();
    }
  }

  void _markDirty() {
    _lineIndexDirty = true;
  }

  void _validateOffset(int offset) {
    if (offset < 0 || offset > length) {
      throw RangeError.range(offset, 0, length, 'offset');
    }
  }

  void _validateRange(int offset, int length) {
    if (offset < 0 || length < 0 || offset + length > this.length) {
      throw RangeError.range(
        offset,
        0,
        this.length,
        'offset',
        'Invalid range length $length',
      );
    }
  }
}

final class _SplitResult {
  const _SplitResult({
    required this.index,
  });

  final int index;
}
