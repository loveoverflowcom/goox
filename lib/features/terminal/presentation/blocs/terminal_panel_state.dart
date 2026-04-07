part of 'terminal_panel_bloc.dart';

/// Status of terminal panel initialization
enum TerminalPanelStatus {
  /// Initial state
  initial,

  /// Panel loaded with saved preferences
  loaded,
}

/// State for terminal panel management
final class TerminalPanelState extends Equatable {
  /// Constructor
  const TerminalPanelState({
    this.isVisible = false,
    this.height = TerminalConfig.defaultHeight,
    this.status = TerminalPanelStatus.initial,
    this.sessions = const [],
    this.activeSessionId,
    this.errorMessage,
  });

  /// Whether the terminal panel is visible
  final bool isVisible;

  /// Height of the terminal panel in pixels
  final double height;

  /// Loading status
  final TerminalPanelStatus status;

  /// List of active terminal sessions
  final List<TerminalSession> sessions;

  /// ID of the currently active session
  final String? activeSessionId;

  /// Error message if any operation fails
  final String? errorMessage;

  /// Get the currently active terminal session
  TerminalSession? get activeSession {
    if (activeSessionId == null || sessions.isEmpty) return null;
    return sessions.cast<TerminalSession?>().firstWhere(
          (s) => s?.id == activeSessionId,
          orElse: () => null,
        );
  }

  /// Get the number of active sessions
  int get sessionCount => sessions.length;

  /// Check if a new session can be created
  bool get canCreateSession => sessions.length < 10;

  /// Copy with method for immutable updates
  TerminalPanelState copyWith({
    bool? isVisible,
    double? height,
    TerminalPanelStatus? status,
    List<TerminalSession>? sessions,
    String? activeSessionId,
    String? errorMessage,
  }) {
    return TerminalPanelState(
      isVisible: isVisible ?? this.isVisible,
      height: height ?? this.height,
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isVisible,
        height,
        status,
        sessions,
        activeSessionId,
        errorMessage,
      ];
}
