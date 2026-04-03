import 'package:equatable/equatable.dart';

final class CursorPosition extends Equatable {

  const CursorPosition({
    required this.line,
    required this.column,
    required this.offset,
  });
  final int line;
  final int column;
  final int offset;

  CursorPosition copyWith({
    int? line,
    int? column,
    int? offset,
  }) {
    return CursorPosition(
      line: line ?? this.line,
      column: column ?? this.column,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [line, column, offset];
}
