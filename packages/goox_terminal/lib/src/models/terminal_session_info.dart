/// Immutable session metadata used by the Dart wrappers and UI.
library;

import 'dart:collection';

import 'package:goox_terminal/src/models/pty_config.dart';
import 'package:goox_terminal/src/models/pty_size.dart';
import 'package:goox_terminal/src/models/terminal_status.dart';

/// Immutable snapshot of a terminal session.
final class TerminalSessionInfo {
  /// Creates a session snapshot.
  const TerminalSessionInfo({
    required this.id,
    required this.status,
    required this.shell,
    required this.args,
    required this.size,
    this.pid,
    this.exitCode,
    this.workingDirectory,
    this.environment = const <String, String>{},
    this.attached = false,
    this.createdAt,
    this.startedAt,
    this.lastActivityAt,
  });

  /// Stable session identifier.
  final String id;

  /// Current lifecycle status.
  final TerminalStatus status;

  /// Process identifier, if known.
  final int? pid;

  /// Exit code after process termination.
  final int? exitCode;

  /// Resolved shell command used to start the session.
  final String shell;

  /// Shell arguments passed on spawn.
  final List<String> args;

  /// Working directory used for the shell.
  final String? workingDirectory;

  /// Environment overrides passed to the shell.
  final Map<String, String> environment;

  /// Current terminal size.
  final PtySize size;

  /// Whether an output stream is currently attached.
  final bool attached;

  /// Session creation time.
  final DateTime? createdAt;

  /// Time when the process was spawned.
  final DateTime? startedAt;

  /// Last input/output activity timestamp.
  final DateTime? lastActivityAt;

  /// Returns true when the session can still accept input.
  bool get canSendInput => status.canAcceptInput;

  /// Returns true if the session is still running.
  bool get isRunning => status.isActive;

  /// Returns true if the process has exited.
  bool get hasExited => status == TerminalStatus.exited;

  /// Returns true if the session has been closed and cleaned up.
  bool get isClosed => status == TerminalStatus.closed;

  /// Returns a copy of the session info with the provided fields replaced.
  TerminalSessionInfo copyWith({
    String? id,
    TerminalStatus? status,
    int? pid,
    Object? exitCode = _unset,
    String? shell,
    List<String>? args,
    String? workingDirectory,
    Map<String, String>? environment,
    PtySize? size,
    bool? attached,
    Object? createdAt = _unset,
    Object? startedAt = _unset,
    Object? lastActivityAt = _unset,
  }) {
    return TerminalSessionInfo(
      id: id ?? this.id,
      status: status ?? this.status,
      pid: pid ?? this.pid,
      exitCode: identical(exitCode, _unset) ? this.exitCode : exitCode as int?,
      shell: shell ?? this.shell,
      args: args ?? this.args,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      environment: environment ?? this.environment,
      size: size ?? this.size,
      attached: attached ?? this.attached,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as DateTime?,
      startedAt: identical(startedAt, _unset)
          ? this.startedAt
          : startedAt as DateTime?,
      lastActivityAt: identical(lastActivityAt, _unset)
          ? this.lastActivityAt
          : lastActivityAt as DateTime?,
    );
  }

  /// Converts this snapshot back into a public config.
  PtyConfig toConfig() {
    return PtyConfig(
      shell: shell,
      args: List<String>.unmodifiable(args),
      workingDirectory: workingDirectory,
      environment: environment.isEmpty
          ? null
          : Map<String, String>.unmodifiable(environment),
      size: size,
    );
  }

  /// Returns a queue-friendly transcript hint for UI rendering.
  /// This intentionally preserves session state only.
  UnmodifiableMapView<String, String> get environmentView =>
      UnmodifiableMapView<String, String>(environment);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TerminalSessionInfo &&
        other.id == id &&
        other.status == status &&
        other.pid == pid &&
        other.exitCode == exitCode &&
        other.shell == shell &&
        _listEquals(other.args, args) &&
        other.workingDirectory == workingDirectory &&
        _mapEquals(other.environment, environment) &&
        other.size == size &&
        other.attached == attached &&
        other.createdAt == createdAt &&
        other.startedAt == startedAt &&
        other.lastActivityAt == lastActivityAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        status,
        pid,
        exitCode,
        shell,
        Object.hashAll(args),
        workingDirectory,
        Object.hashAllUnordered(environment.entries),
        size,
        attached,
        createdAt,
        startedAt,
        lastActivityAt,
      );

  @override
  String toString() {
    return 'TerminalSessionInfo('
        'id: $id, '
        'status: $status, '
        'pid: $pid, '
        'exitCode: $exitCode, '
        'shell: $shell, '
        'args: $args, '
        'workingDirectory: $workingDirectory, '
        'size: $size, '
        'attached: $attached'
        ')';
  }

  static bool _listEquals<T>(List<T> left, List<T> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  static bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
    if (identical(left, right)) return true;
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}

const Object _unset = Object();
