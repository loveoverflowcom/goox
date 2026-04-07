import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/terminal/data/models/terminal_config.dart';
import 'package:goox/features/terminal/data/models/terminal_session.dart';
import 'package:goox/features/terminal/data/repositories/terminal_repository.dart';
import 'package:goox_terminal/goox_terminal.dart';
import 'package:uuid/uuid.dart';

part 'terminal_panel_event.dart';
part 'terminal_panel_state.dart';

/// BLoC for managing terminal panel (visibility, size, sessions)
/// 
/// This BLoC is simplified to only handle:
/// - Panel visibility toggle
/// - Panel height/resize
/// - Terminal session lifecycle (create, close, switch)
/// - Persistence of panel state
/// 
/// All terminal UI and PTY logic is delegated to goox_terminal package.
class TerminalPanelBloc extends Bloc<TerminalPanelEvent, TerminalPanelState> {
  /// Constructor
  TerminalPanelBloc({
    required TerminalRepository repository,
    required PTYService ptyService,
    required ShellDetector shellDetector,
    required ANSIParser ansiParser,
  })  : _repository = repository,
        _ptyService = ptyService,
        _shellDetector = shellDetector,
        _ansiParser = ansiParser,
        super(const TerminalPanelState()) {
    on<InitializeTerminalPanelEvent>(_onInitialize);
    on<ToggleTerminalPanelEvent>(_onToggle);
    on<ResizeTerminalPanelEvent>(_onResize);
    on<CreateTerminalSessionEvent>(_onCreateSession);
    on<CloseTerminalSessionEvent>(_onCloseSession);
    on<SwitchTerminalSessionEvent>(_onSwitchSession);
    on<CycleTerminalSessionEvent>(_onCycleSession);
  }

  final TerminalRepository _repository;
  final PTYService _ptyService;
  final ShellDetector _shellDetector;
  final ANSIParser _ansiParser;
  final _uuid = const Uuid();

  /// Handle initialization with saved preferences
  Future<void> _onInitialize(
    InitializeTerminalPanelEvent event,
    Emitter<TerminalPanelState> emit,
  ) async {
    try {
      // Load saved preferences
      final visibility = await _repository.loadVisibility();
      final height = await _repository.loadHeight();
      final sessionCount = await _repository.loadTerminalCount();
      final workingDirs = await _repository.loadWorkingDirectories();

      // Restore sessions with saved working directories
      final sessions = <TerminalSession>[];
      final count = math.min(sessionCount, 10); // Respect max limit

      for (var i = 0; i < count; i++) {
        final workingDir =
            i < workingDirs.length ? workingDirs[i] : Directory.current.path;

        final session = await _createSession(workingDir);
        if (session != null) {
          sessions.add(session);
        }
      }

      // If no sessions were created, create at least one
      if (sessions.isEmpty) {
        final session = await _createSession(Directory.current.path);
        if (session != null) {
          sessions.add(session);
        }
      }

      emit(
        state.copyWith(
          isVisible: visibility,
          height: height,
          status: TerminalPanelStatus.loaded,
          sessions: sessions,
          activeSessionId: sessions.isNotEmpty ? sessions.first.id : null,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: TerminalPanelStatus.loaded,
          errorMessage: 'Failed to initialize terminal panel: $e',
        ),
      );
    }
  }

  /// Handle panel visibility toggle
  Future<void> _onToggle(
    ToggleTerminalPanelEvent event,
    Emitter<TerminalPanelState> emit,
  ) async {
    final newVisibility = !state.isVisible;

    // Save to repository
    await _repository.saveVisibility(isVisible: newVisibility);

    emit(
      state.copyWith(
        isVisible: newVisibility,
      ),
    );
  }

  /// Handle panel resize
  Future<void> _onResize(
    ResizeTerminalPanelEvent event,
    Emitter<TerminalPanelState> emit,
  ) async {
    // Constrain height to valid range
    final constrainedHeight = math.max(
      TerminalConfig.minHeight,
      event.newHeight,
    );

    emit(
      state.copyWith(
        height: constrainedHeight,
      ),
    );
  }

  /// Handle creating a new terminal session
  Future<void> _onCreateSession(
    CreateTerminalSessionEvent event,
    Emitter<TerminalPanelState> emit,
  ) async {
    // Check if we can create more sessions
    if (!state.canCreateSession) {
      emit(
        state.copyWith(
          errorMessage: 'Maximum number of terminals (10) reached',
        ),
      );
      return;
    }

    try {
      final workingDir = event.workingDirectory ?? Directory.current.path;
      final session = await _createSession(workingDir);

      if (session == null) {
        emit(
          state.copyWith(
            errorMessage: 'Failed to create terminal session',
          ),
        );
        return;
      }

      // Add to sessions list and set as active
      final updatedSessions = [...state.sessions, session];

      emit(
        state.copyWith(
          sessions: updatedSessions,
          activeSessionId: session.id,
        ),
      );

      // Save session count
      await _repository.saveTerminalCount(count: updatedSessions.length);
      await _repository.saveWorkingDirectories(
        paths: updatedSessions.map((s) => s.workingDirectory).toList(),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to create terminal session: $e',
        ),
      );
    }
  }

  /// Handle closing a terminal session
  Future<void> _onCloseSession(
    CloseTerminalSessionEvent event,
    Emitter<TerminalPanelState> emit,
  ) async {
    try {
      // Find the session to close
      final sessionIndex =
          state.sessions.indexWhere((s) => s.id == event.sessionId);
      if (sessionIndex == -1) return;

      final session = state.sessions[sessionIndex];

      // Stop the terminal controller
      await session.controller.stop(force: true);

      // Remove from sessions list
      final updatedSessions = List<TerminalSession>.from(state.sessions)
        ..removeAt(sessionIndex);

      // Determine new active session
      String? newActiveId;

      if (updatedSessions.isEmpty) {
        // If this was the last session, create a new one
        final newSession = await _createSession(Directory.current.path);
        if (newSession != null) {
          updatedSessions.add(newSession);
          newActiveId = newSession.id;
        }
      } else if (state.activeSessionId == event.sessionId) {
        // If we closed the active session, activate the previous one
        // or the first one if we closed the first session
        final newIndex = sessionIndex > 0 ? sessionIndex - 1 : 0;
        newActiveId = updatedSessions[newIndex].id;
      } else {
        // Keep the current active session
        newActiveId = state.activeSessionId;
      }

      emit(
        state.copyWith(
          sessions: updatedSessions,
          activeSessionId: newActiveId,
        ),
      );

      // Save session count and working directories
      await _repository.saveTerminalCount(count: updatedSessions.length);
      await _repository.saveWorkingDirectories(
        paths: updatedSessions.map((s) => s.workingDirectory).toList(),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to close terminal session: $e',
        ),
      );
    }
  }

  /// Handle switching to a different session
  Future<void> _onSwitchSession(
    SwitchTerminalSessionEvent event,
    Emitter<TerminalPanelState> emit,
  ) async {
    // Verify the session exists
    final sessionExists = state.sessions.any((s) => s.id == event.sessionId);
    if (!sessionExists) return;

    emit(
      state.copyWith(
        activeSessionId: event.sessionId,
      ),
    );
  }

  /// Handle cycling through sessions
  Future<void> _onCycleSession(
    CycleTerminalSessionEvent event,
    Emitter<TerminalPanelState> emit,
  ) async {
    if (state.sessions.isEmpty) return;

    // Find current active session index
    final currentIndex = state.sessions.indexWhere(
      (s) => s.id == state.activeSessionId,
    );

    // Calculate next/previous index with wrapping
    int newIndex;
    if (event.forward) {
      // Cycle forward (next)
      newIndex = (currentIndex + 1) % state.sessions.length;
    } else {
      // Cycle backward (previous)
      newIndex =
          (currentIndex - 1 + state.sessions.length) % state.sessions.length;
    }

    emit(
      state.copyWith(
        activeSessionId: state.sessions[newIndex].id,
      ),
    );
  }

  /// Create a terminal session with controller
  Future<TerminalSession?> _createSession(String workingDir) async {
    final id = _uuid.v4();

    try {
      // Create terminal controller
      final controller = TerminalController(
        ptyService: _ptyService,
        shellDetector: _shellDetector,
        ansiParser: _ansiParser,
        workingDirectory: workingDir,
      );

      // Start the terminal
      await controller.start();

      // Create session
      final session = TerminalSession(
        id: id,
        workingDirectory: workingDir,
        controller: controller,
        createdAt: DateTime.now(),
      );

      return session;
    } catch (e) {
      // Failed to create session
      return null;
    }
  }

  @override
  Future<void> close() async {
    // Stop all terminal controllers
    for (final session in state.sessions) {
      await session.controller.stop(force: true);
    }

    return super.close();
  }
}
