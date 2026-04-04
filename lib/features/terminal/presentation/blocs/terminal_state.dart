part of 'terminal_bloc.dart';

/// Status of terminal initialization
enum TerminalStatus {
  /// Initial state
  initial,

  /// Terminal loaded with saved preferences
  loaded,
}

/// State for terminal panel management
final class TerminalState extends Equatable {
  /// Constructor
  const TerminalState({
    this.isVisible = false,
    this.height = TerminalConfig.defaultHeight,
    this.status = TerminalStatus.initial,
  });

  /// Whether the terminal panel is visible
  final bool isVisible;

  /// Height of the terminal panel in pixels
  final double height;

  /// Loading status
  final TerminalStatus status;

  /// Copy with method for immutable updates
  TerminalState copyWith({
    bool? isVisible,
    double? height,
    TerminalStatus? status,
  }) {
    return TerminalState(
      isVisible: isVisible ?? this.isVisible,
      height: height ?? this.height,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [isVisible, height, status];
}
