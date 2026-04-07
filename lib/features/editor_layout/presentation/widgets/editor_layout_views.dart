import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/editor_content/data.dart';
import 'package:goox/features/editor_content/presentation.dart';
import 'package:goox/features/editor_layout/presentation.dart';
import 'package:goox/features/file_explorer/data.dart';
import 'package:goox/features/file_explorer/presentation.dart';
import 'package:goox/features/status_bar/presentation.dart';
import 'package:goox/features/tab_manager/presentation.dart';
import 'package:goox/features/terminal.dart';
import 'package:goox/features/theme.dart';
import 'package:goox_ui/goox_ui.dart';

part 'editor_layout_views_resize_handle.dart';
part 'editor_layout_views_sidebar.dart';
part 'editor_layout_views_editor_area.dart';
part 'editor_layout_views_tab_contents.dart';

/// Main editor layout page.
final class EditorLayoutView extends StatelessWidget {
  /// Creates an editor layout page.
  const EditorLayoutView({
    required this.workspacePath,
    super.key,
  });

  /// The workspace path to load.
  final String workspacePath;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => EditorLayoutBloc()
            ..add(InitializeLayoutEvent(workspacePath)),
        ),
        BlocProvider(
          create: (context) {
            final bloc = FileExplorerBloc(
              repository: context.read<WorkspaceRepository>(),
            );
            // Only load workspace if path is not empty
            if (workspacePath.isNotEmpty) {
              bloc.add(LoadWorkspaceEvent(workspacePath));
            }
            return bloc;
          },
        ),
        BlocProvider(
          create: (context) => TabManagerBloc(),
        ),
        BlocProvider(
          create: (context) => EditorContentBloc(
            repository: context.read<FileRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => TerminalBloc(
            repository: context.read<TerminalRepository>(),
          )..add(const InitializeTerminalEvent()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<EditorContentBloc, EditorContentState>(
            listener: (context, state) {
              // Sync modified state with tab manager
              final tabState = context.read<TabManagerBloc>().state;
              if (tabState.activeTabId != null) {
                context.read<TabManagerBloc>().add(
                      UpdateTabModifiedEvent(
                        tabId: tabState.activeTabId!,
                        isModified: state.isModified,
                      ),
                    );
              }
            },
          ),
          BlocListener<TabManagerBloc, TabManagerState>(
            listenWhen: (previous, current) => previous.activeTabId != current.activeTabId,
            listener: (context, state) {
              final noTabOpened = state.activeTabId == null;
              context.read<EditorContentBloc>()
                .add(noTabOpened 
                  ? const CloseContentEvent() 
                  : LoadFileContentEvent(state.activeTab!.filePath)
                );
            }
          ),
        ],
        child: const _EditorLayoutView(),
      ),
    );
  }
}

final class _EditorLayoutView extends StatelessWidget {
  const _EditorLayoutView();

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;
    
    return Scaffold(
      backgroundColor: editorTheme.editorBackground,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) => _handleKeyEvent(context, event),
        child: BlocBuilder<EditorLayoutBloc, EditorLayoutState>(
          builder: (context, layoutState) {
            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (layoutState.sidebarVisible)
                        Row(
                          children: [
                            _SidebarWidget(
                              width: layoutState.sidebarWidth,
                              theme: editorTheme,
                            ),
                            _ResizeHandleWidget(
                              currentWidth: layoutState.sidebarWidth,
                              theme: editorTheme,
                            ),
                          ],
                        ),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _EditorAreaWidget(theme: editorTheme),
                            ),
                            BlocBuilder<TerminalBloc, TerminalState>(
                              builder: (context, terminalState) {
                                return Visibility.maintain(
                                  visible: terminalState.isVisible,
                                  child: const TerminalPanelWidget(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const StatusBarWidget(),
              ],
            );
          },
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // Ctrl/Cmd + B: Toggle sidebar
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyB) {
      context.read<EditorLayoutBloc>().add(const ToggleSidebarEvent());
      return KeyEventResult.handled;
    }

    // Ctrl + ` (backtick): Toggle terminal
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.backquote &&
        !isShift) {
      context.read<TerminalBloc>().add(const ToggleTerminalEvent());
      return KeyEventResult.handled;
    }

    // Ctrl + Shift + ` (backtick): Create new terminal
    if (HardwareKeyboard.instance.isControlPressed &&
        isShift &&
        event.logicalKey == LogicalKeyboardKey.backquote) {
      context.read<TerminalBloc>().add(const CreateTerminalEvent());
      return KeyEventResult.handled;
    }

    // Ctrl + PageUp: Cycle to previous terminal
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.pageUp) {
      context.read<TerminalBloc>().add(const CycleTerminalEvent(forward: false));
      return KeyEventResult.handled;
    }

    // Ctrl + PageDown: Cycle to next terminal
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.pageDown) {
      context.read<TerminalBloc>().add(const CycleTerminalEvent(forward: true));
      return KeyEventResult.handled;
    }

    // Ctrl + Shift + W: Close active terminal
    if (HardwareKeyboard.instance.isControlPressed &&
        isShift &&
        event.logicalKey == LogicalKeyboardKey.keyW) {
      final terminalState = context.read<TerminalBloc>().state;
      if (terminalState.activeTerminalId != null) {
        context.read<TerminalBloc>().add(
              CloseTerminalEvent(terminalState.activeTerminalId!),
            );
      }
      return KeyEventResult.handled;
    }

    // Ctrl/Cmd + W: Close active tab
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyW && !isShift) {
      final tabState = context.read<TabManagerBloc>().state;
      if (tabState.activeTabId != null) {
        context
            .read<TabManagerBloc>()
            .add(CloseTabEvent(tabState.activeTabId!));
      }
      return KeyEventResult.handled;
    }

    // Ctrl + Tab: Next tab
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.tab &&
        !isShift) {
      context.read<TabManagerBloc>().add(const NextTabEvent());
      return KeyEventResult.handled;
    }

    // Ctrl + Shift + Tab: Previous tab
    if (HardwareKeyboard.instance.isControlPressed &&
        isShift &&
        event.logicalKey == LogicalKeyboardKey.tab) {
      context.read<TabManagerBloc>().add(const PreviousTabEvent());
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
