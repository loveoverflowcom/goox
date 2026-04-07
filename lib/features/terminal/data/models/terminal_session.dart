import 'package:equatable/equatable.dart';
import 'package:goox_terminal/goox_terminal.dart';

/// Lightweight model representing a terminal session in the app
/// 
/// This model wraps a TerminalController from goox_terminal package
/// and adds app-specific metadata like ID and creation time.
final class TerminalSession extends Equatable {
  /// Creates a terminal session
  const TerminalSession({
    required this.id,
    required this.workingDirectory,
    required this.controller,
    required this.createdAt,
  });

  /// Unique identifier for this session
  final String id;

  /// Working directory for the terminal
  final String workingDirectory;

  /// Terminal controller from goox_terminal package
  final TerminalController controller;

  /// When this session was created
  final DateTime createdAt;

  /// Get the terminal title
  String get title => controller.title ?? 'Terminal';

  /// Get the terminal status
  TerminalStatus get status => controller.status;

  @override
  List<Object?> get props => [id, workingDirectory, createdAt];
}
