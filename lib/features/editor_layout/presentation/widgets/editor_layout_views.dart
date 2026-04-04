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
            repository: TerminalRepositoryImpl(),
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
            listener: (context, state) {
              // Load content when active tab changes
              if (state.activeTab != null) {
                context.read<EditorContentBloc>().add(
                      LoadFileContentEvent(state.activeTab!.filePath),
                    );
              }
            },
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
    return Scaffold(
      backgroundColor: AppColors.editorBackground,
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
                            _buildSidebar(context, layoutState.sidebarWidth),
                            _buildResizeHandle(context),
                          ],
                        ),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: _buildEditorArea()),
                            BlocBuilder<TerminalBloc, TerminalState>(
                              builder: (context, terminalState) {
                                if (!terminalState.isVisible) {
                                  return const SizedBox.shrink();
                                }
                                return const TerminalPanelWidget();
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

  Widget _buildSidebar(BuildContext context, double width) {
    // Width includes activity bar + content area
    final contentWidth = width - AppSpacing.activityBarWidth;
    
    return SizedBox(
      width: width,
      child: GooxNavigationRail(
        initialSelectedId: 'explorer',
        destinations: [
          GooxDestinationTab(
            id: 'explorer',
            title: 'Explorer',
            icon: Icons.copy_rounded,
            builder: (context) => Container(
              width: contentWidth,
              decoration: const BoxDecoration(
                color: AppColors.sidebarBackground,
                border: Border(
                  right: BorderSide(color: AppColors.borderColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: const Text(
                      'EXPLORER',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FileExplorerWidget(
                      onFileSelected: (filePath, fileName) {
                        context.read<TabManagerBloc>().add(
                              OpenTabEvent(
                                filePath: filePath,
                                fileName: fileName,
                              ),
                            );
                        context.read<EditorContentBloc>().add(
                              LoadFileContentEvent(filePath),
                            );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          GooxDestinationTab(
            id: 'search',
            title: 'Search',
            icon: Icons.search,
            builder: (context) => Container(
              width: contentWidth,
              decoration: const BoxDecoration(
                color: AppColors.sidebarBackground,
                border: Border(
                  right: BorderSide(color: AppColors.borderColor),
                ),
              ),
              child: const Center(
                child: Text(
                  'Search',
                  style: TextStyle(color: AppColors.textColor),
                ),
              ),
            ),
          ),
          GooxDestinationTab(
            id: 'source-control',
            title: 'Source Control',
            icon: Icons.account_tree_outlined,
            builder: (context) => Container(
              width: contentWidth,
              decoration: const BoxDecoration(
                color: AppColors.sidebarBackground,
                border: Border(
                  right: BorderSide(color: AppColors.borderColor),
                ),
              ),
              child: const Center(
                child: Text(
                  'Source Control',
                  style: TextStyle(color: AppColors.textColor),
                ),
              ),
            ),
          ),
          GooxDestinationTab(
            id: 'extensions',
            title: 'Extensions',
            icon: Icons.extension_outlined,
            builder: (context) => Container(
              width: contentWidth,
              decoration: const BoxDecoration(
                color: AppColors.sidebarBackground,
                border: Border(
                  right: BorderSide(color: AppColors.borderColor),
                ),
              ),
              child: const Center(
                child: Text(
                  'Extensions',
                  style: TextStyle(color: AppColors.textColor),
                ),
              ),
            ),
          ),
          GooxDestinationTab(
            id: 'settings',
            title: 'Settings',
            icon: Icons.settings_outlined,
            alignment: GooxTabAlignment.bottom,
            builder: (context) => Container(
              width: contentWidth,
              decoration: const BoxDecoration(
                color: AppColors.sidebarBackground,
                border: Border(
                  right: BorderSide(color: AppColors.borderColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: const Text(
                      'SETTINGS',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const ThemeSelectorWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResizeHandle(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final layoutBloc = context.read<EditorLayoutBloc>();
        final currentWidth = layoutBloc.state.sidebarWidth;
        layoutBloc.add(ResizeSidebarEvent(currentWidth + details.delta.dx));
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: AppSpacing.resizeHandleWidth,
          color: AppColors.borderColor,
        ),
      ),
    );
  }

  Widget _buildEditorArea() {
    return const ColoredBox(
      color: AppColors.editorBackground,
      child: Column(
        children: [
          TabBarWidget(),
          Expanded(child: TextEditorWidget()),
        ],
      ),
    );
  }

  KeyEventResult _handleKeyEvent(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // Ctrl/Cmd + B: Toggle sidebar
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyB) {
      context.read<EditorLayoutBloc>().add(const ToggleSidebarEvent());
      return KeyEventResult.handled;
    }

    // Ctrl + ` (backtick): Toggle terminal
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.backquote) {
      context.read<TerminalBloc>().add(const ToggleTerminalEvent());
      return KeyEventResult.handled;
    }

    // Ctrl/Cmd + W: Close active tab
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyW) {
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
        !HardwareKeyboard.instance.isShiftPressed) {
      context.read<TabManagerBloc>().add(const NextTabEvent());
      return KeyEventResult.handled;
    }

    // Ctrl + Shift + Tab: Previous tab
    if (HardwareKeyboard.instance.isControlPressed &&
        HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.tab) {
      context.read<TabManagerBloc>().add(const PreviousTabEvent());
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
