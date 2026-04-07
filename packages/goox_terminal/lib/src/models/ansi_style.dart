import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents ANSI styling information for terminal text
class ANSIStyle extends Equatable {
  /// Starting character index for this style (inclusive)
  final int startIndex;

  /// Ending character index for this style (exclusive)
  final int endIndex;

  /// Foreground text color
  final Color? foregroundColor;

  /// Background color
  final Color? backgroundColor;

  /// Whether text is bold
  final bool bold;

  /// Whether text is italic
  final bool italic;

  /// Whether text is underlined
  final bool underline;

  const ANSIStyle({
    required this.startIndex,
    required this.endIndex,
    this.foregroundColor,
    this.backgroundColor,
    this.bold = false,
    this.italic = false,
    this.underline = false,
  });

  /// Create a copy with updated fields
  ANSIStyle copyWith({
    int? startIndex,
    int? endIndex,
    Color? foregroundColor,
    Color? backgroundColor,
    bool? bold,
    bool? italic,
    bool? underline,
  }) {
    return ANSIStyle(
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
    );
  }

  @override
  List<Object?> get props => [
        startIndex,
        endIndex,
        foregroundColor,
        backgroundColor,
        bold,
        italic,
        underline,
      ];
}
