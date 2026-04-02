import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';
import 'package:goox_ui_shared/goox_ui_shared.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
import '../../widgets/extensions_view.dart';
import '../widgets/extension_webview_shell.dart';
import '../../widgets/settings_view.dart';
import '../../widgets/sidebar.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final GooxEditorController _controller;
  late final FocusNode _focusNode;
  String? _loadedFilePath;
  bool _isUnsupportedFile = false;
  String? _unsupportedMessage;
  TextMateGrammar? _syntaxGrammar;
  String? _syntaxGrammarPath;
  DateTime? _syntaxGrammarModifiedAt;
  String? _lastSyntaxGrammarError;
  Timer? _syntaxGrammarWatchTimer;
  final _extensionsKey = GlobalKey<ExtensionsViewState>();

  // Dual-mode support
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = GooxEditorController();
    _focusNode = FocusNode(debugLabel: 'editor-demo');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    if (appState.activeFile != _loadedFilePath) {
      _loadedFilePath = appState.activeFile;
      _loadFile(_loadedFilePath);
    }
  }

  Future<void> _loadFile(String? filePath) async {
    if (filePath == null) {
      await _controller.setActiveExtension(null);
      await _configureSyntaxGrammar(null);
      await _controller.loadDocument('');
      if (mounted) {
        setState(() {
          _isUnsupportedFile = false;
          _unsupportedMessage = null;
          _showPreview = false;
        });
      }
      return;
    }

    try {
      // Capture context-dependent values before any await
      final appState = context.read<AppState>();
      final workspaceRoot = appState.rootPath ?? '';

      await GooxEditorSdkBootstrap.ensureInitialized(
        workspaceRoot: workspaceRoot,
      );

      final extension = await GooxEditorSdkBootstrap.resolveExtensionForFile(
        workspaceRoot: workspaceRoot,
        filePath: filePath,
      );
      await _controller.setActiveExtension(extension);
      await _configureSyntaxGrammar(extension);

      final isRendererOnly = extension?.isRendererOnly == true;

      if (mounted) {
        setState(() {
          _showPreview = false;
        });
      }

      if (isRendererOnly) {
        if (mounted) {
          setState(() {
            _isUnsupportedFile = false;
            _unsupportedMessage = null;
          });
        }
        appState.markFileDirty(filePath, false);
        return;
      }

      if (mounted) {
        setState(() {
          _isUnsupportedFile = false;
          _unsupportedMessage = null;
        });
      }

      final file = File(filePath);
      final text = file.existsSync() ? await file.readAsString() : '';
      await _controller.loadDocument(
        text,
        filePath: filePath,
        workspaceRoot: workspaceRoot,
      );

      await _applyPendingNavigationTarget(filePath);

      if (mounted) {
        appState.markFileDirty(filePath, false);
      }
    } on FileSystemException catch (_) {
      if (mounted) {
        setState(() {
          _isUnsupportedFile = true;
          _unsupportedMessage =
              'This file cannot be opened as plain text. Install or enable a compatible extension for ${path.basename(filePath)}.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isUnsupportedFile = true;
          _unsupportedMessage =
              'Failed to open ${path.basename(filePath)}. Please try again or check the extension configuration.';
        });
      }
    }
  }

  Future<void> _saveCurrentFile() async {
    final path = _loadedFilePath;
    if (path == null) {
      return;
    }

    try {
      final text = await _controller.getDocumentText();
      await File(path).writeAsString(text);
      if (mounted) {
        context.read<AppState>().markFileDirty(path, false);
      }
    } catch (error) {
      debugPrint('Save error: $error');
    }
  }

  void _markDirty() {
    final path = _loadedFilePath;
    if (path != null && mounted) {
      context.read<AppState>().markFileDirty(path, true);
    }
  }

  Future<void> _handleGoToDefinition() async {
    final locations = await _controller.lspFindDefinitions();
    if (mounted) {
      _handleLocations(locations);
    }
  }

  Future<void> _handleGoToDeclaration() async {
    final locations = await _controller.lspFindDeclarations();
    if (mounted) {
      _handleLocations(locations);
    }
  }

  Future<void> _handleGoToImplementation() async {
    final locations = await _controller.lspFindImplementations();
    if (mounted) {
      _handleLocations(locations);
    }
  }

  Future<void> _handleFindReferences() async {
    final locations = await _controller.lspFindReferences();
    if (mounted) {
      _handleLocations(locations);
    }
  }

  void _handleLocations(List<LanguageServerLocation> locations) {
    if (locations.isEmpty) return;

    final location = locations.first;
    final uri = Uri.parse(location.uri);
    final filePath = uri.toFilePath();
    final line = location.range.start.line + 1;
    final column = location.range.start.character + 1;

    final appState = context.read<AppState>();
    if (filePath != _loadedFilePath) {
      appState.setPendingNavigationTarget(
        filePath: filePath,
        line: line,
        column: column,
      );
      appState.openFile(filePath);
    } else {
      _controller.moveCursorToPosition(line, column);
    }
  }

  Future<void> _applyPendingNavigationTarget(String currentFilePath) async {
    final appState = context.read<AppState>();
    final target = appState.pendingNavigationTarget;
    if (target == null || target.filePath != currentFilePath) {
      return;
    }

    appState.consumePendingNavigationTarget();
    await _controller.moveCursorToPosition(target.line, target.column);
  }

  Future<void> _handleEditorTextChanged(GooxEditorTextChange change) async {
    await _controller.replaceTextRange(
      change.start,
      change.end,
      change.replacement,
    );
    _markDirty();
  }

  void _togglePreviewMode() {
    final nextShowPreview = !_showPreview;
    setState(() {
      _showPreview = nextShowPreview;
    });

    if (!nextShowPreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    } else {
      _focusNode.unfocus();
    }
  }

  Widget _buildEditorContent(
    EditorViewState state,
    ActiveExtensionInfo? activeExtension,
    String activeFile,
    String? resolvedWebEntryPath,
    AppState appState,
  ) {
    final isDualMode = activeExtension?.isDualMode == true;
    final isRendererOnly = activeExtension?.isRendererOnly == true;

    if (_isUnsupportedFile) {
      return _UnsupportedFileView(message: _unsupportedMessage ?? '');
    }

    if (activeExtension != null && isRendererOnly) {
      return _buildWebviewContent(
        activeExtension: activeExtension,
        activeFile: activeFile,
        resolvedWebEntryPath: resolvedWebEntryPath,
      );
    }

    final editorContent = _buildEditorCanvas(state: state, appState: appState);

    if (activeExtension != null && isDualMode) {
      return IndexedStack(
        index: _showPreview ? 1 : 0,
        children: [
          editorContent,
          _buildWebviewContent(
            activeExtension: activeExtension,
            activeFile: activeFile,
            resolvedWebEntryPath: resolvedWebEntryPath,
          ),
        ],
      );
    }

    return editorContent;
  }

  Widget _buildEditorCanvas({
    required EditorViewState state,
    required AppState appState,
  }) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          _saveCurrentFile();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          _saveCurrentFile();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          _controller.undo();
          _markDirty();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          _controller.undo();
          _markDirty();
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () {
          _controller.redo();
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          shift: true,
        ): () {
          _controller.redo();
        },
      },
      child: GooxEditorCanvas(
        state: state,
        focusNode: _focusNode,
        autofocus: true,
        onTap: _focusNode.requestFocus,
        onTextChanged: _handleEditorTextChanged,
        onCursorOffsetChanged: _controller.moveCursorToOffset,
        onGoToDefinition: _handleGoToDefinition,
        onGoToDeclaration: _handleGoToDeclaration,
        onGoToImplementation: _handleGoToImplementation,
        onFindReferences: _handleFindReferences,
        onHover: (offset) {
          if (offset == -1) {
            _controller.requestHover(-1);
          } else {
            _controller.requestHover(offset);
          }
        },
        fontSize: appState.settings.fontSize,
        fontWeight: appState.settings.fontWeight,
        fontFamily: appState.settings.fontFamily,
        syntaxGrammar: _syntaxGrammar,
      ),
    );
  }

  Widget _buildWebviewContent({
    required ActiveExtensionInfo activeExtension,
    required String activeFile,
    required String? resolvedWebEntryPath,
  }) {
    return GooxExtensionWebViewShell(
      extensionName: activeExtension.name,
      filePath: activeFile,
      fileType: activeExtension.filetypes.isNotEmpty
          ? activeExtension.filetypes.first
          : path.extension(activeFile).replaceFirst('.', ''),
      webEntryPath: resolvedWebEntryPath,
      onBridgeMessage: (message) {
        debugPrint('WebView bridge: $message');
      },
    );
  }

  @override
  void dispose() {
    _syntaxGrammarWatchTimer?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _configureSyntaxGrammar(ActiveExtensionInfo? extension) async {
    _syntaxGrammarWatchTimer?.cancel();
    _syntaxGrammarWatchTimer = null;
    _syntaxGrammarPath = extension?.syntaxGrammarPath;
    _syntaxGrammarModifiedAt = null;

    if (_syntaxGrammarPath == null) {
      if (mounted && _syntaxGrammar != null) {
        setState(() {
          _syntaxGrammar = null;
        });
      }
      return;
    }

    await _reloadSyntaxGrammar(
      path: _syntaxGrammarPath!,
      replaceExisting: true,
    );

    _syntaxGrammarWatchTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_pollSyntaxGrammarReload()),
    );
  }

  Future<void> _pollSyntaxGrammarReload() async {
    final grammarPath = _syntaxGrammarPath;
    if (grammarPath == null) {
      return;
    }

    try {
      final modified = await FileStat.stat(
        grammarPath,
      ).then((stat) => stat.modified);
      if (_syntaxGrammarModifiedAt == null ||
          modified.isAfter(_syntaxGrammarModifiedAt!)) {
        await _reloadSyntaxGrammar(path: grammarPath, replaceExisting: false);
      }
    } catch (error) {
      debugPrint('Failed to poll syntax grammar at $grammarPath: $error');
    }
  }

  Future<void> _reloadSyntaxGrammar({
    required String path,
    required bool replaceExisting,
  }) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        throw FileSystemException('Missing syntax grammar file', path);
      }

      final content = await file.readAsString();
      final grammar = const TextMateParser().parse(content);
      final modified = await file.lastModified();
      if (!mounted) {
        return;
      }

      setState(() {
        _syntaxGrammar = grammar;
        _syntaxGrammarModifiedAt = modified;
        _lastSyntaxGrammarError = null;
      });
    } catch (error) {
      debugPrint('Failed to load syntax grammar from $path: $error');
      if (mounted && replaceExisting) {
        setState(() {
          _syntaxGrammar = null;
        });
      }
      final message = error.toString();
      if (mounted && _lastSyntaxGrammarError != message) {
        _lastSyntaxGrammarError = message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load syntax grammar: $message')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeFile = appState.activeFile;
    final hasActiveFile = activeFile != null;

    return ValueListenableBuilder<EditorViewState>(
      valueListenable: _controller.stateListenable,
      builder: (context, state, _) {
        final activeExtension = state.activeExtension;
        final webEntryPath =
            activeExtension != null && activeExtension.hasWebViewCapability
            ? activeExtension.webEntry
            : null;
        final resolvedWebEntryPath =
            webEntryPath != null && activeExtension != null
            ? path.join(activeExtension.path, webEntryPath)
            : null;
        return GooxLayout(
          tabs: [
            GooxWidgetTab(
              id: 'explorer',
              title: 'Explorer',
              icon: Icons.copy_rounded,
              builder: (context) => const ExplorerView(),
            ),
            GooxSearchTab(),
            GooxWidgetTab(
              id: 'source-control',
              title: 'Source Control',
              icon: Icons.account_tree_outlined,
              builder: (context) => const Center(child: Text('Source Control')),
            ),
            GooxWidgetTab(
              id: 'run-and-debug',
              title: 'Run and Debug',
              icon: Icons.play_arrow_outlined,
              builder: (context) => const Center(child: Text('Run and Debug')),
            ),
            GooxWidgetTab(
              id: 'extensions',
              title: 'Extensions',
              icon: Icons.extension_outlined,
              builder: (context) => ExtensionsView(key: _extensionsKey),
              trailing: (context) =>
                  _ExtensionsTrailing(extensionsKey: _extensionsKey),
            ),
            GooxWidgetTab(
              id: 'settings',
              title: 'Settings',
              icon: Icons.settings_outlined,
              alignment: GooxTabAlignment.bottom,
              builder: (context) => const SettingsView(),
            ),
          ],
          panels: [GooxTerminalPanelTab(workingDirectory: appState.rootPath)],
          editorHeader: const _EditorTabHeader(),
          editor: hasActiveFile
              ? Column(
                  children: [
                    _LspDiagnosticsBanner(state: state),
                    // Add Preview button for dual-mode extensions
                    if (activeExtension?.isDualMode == true)
                      _DualModeToolbar(
                        showPreview: _showPreview,
                        onToggle: _togglePreviewMode,
                      ),
                    Expanded(
                      child: _buildEditorContent(
                        state,
                        activeExtension,
                        activeFile,
                        resolvedWebEntryPath,
                        appState,
                      ),
                    ),
                  ],
                )
              : _EditorWelcomeView(onOpenFolder: appState.pickDirectory),
          statusBar: GooxStatusBar(
            revision: state.revision,
            line: state.cursor.line,
            column: state.cursor.column,
            lspStatus: state.lspStatus,
            diagnosticCount: state.lspDiagnostics.length,
          ),
        );
      },
    );
  }
}

class _EditorWelcomeView extends StatelessWidget {
  const _EditorWelcomeView({required this.onOpenFolder});

  final Future<void> Function() onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = context.watch<AppState>();
    final recentFolders = appState.recentFolders;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Icon(
                    Icons.auto_awesome_mosaic_outlined,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  Text(
                    'Get started with Goox',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Open a folder to start editing files. Once a file is opened, the editor will appear here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onOpenFolder,
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Open Folder'),
              ),
              const SizedBox(height: 28),
              if (recentFolders
                  .where((f) => f.path != appState.rootPath)
                  .isNotEmpty) ...[
                Text(
                  'Recent Folders',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: recentFolders
                      .where((folder) => folder.path != appState.rootPath)
                      .map((folder) {
                        final folderName = path.basename(folder.path);
                        final folderPath = folder.path;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: () => appState.openDirectory(folderPath),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder_open_outlined,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    folderName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                      decorationColor: colorScheme.primary
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    folderPath,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ] else ...[
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: const [
                    _ShortcutCard(
                      title: 'Open Folder',
                      shortcut: 'Explorer',
                      description:
                          'Use the Explorer button or the welcome action to choose a workspace.',
                    ),
                    _ShortcutCard(
                      title: 'Save File',
                      shortcut: 'Cmd/Ctrl + S',
                      description:
                          'Write the current editor contents back to disk.',
                    ),
                    _ShortcutCard(
                      title: 'Undo / Redo',
                      shortcut: 'Cmd/Ctrl + Z',
                      description:
                          'Use Shift with the same shortcut to redo the last change.',
                    ),
                    _ShortcutCard(
                      title: 'Explorer Actions',
                      shortcut: 'Right Click',
                      description:
                          'Rename or delete files and folders directly from the Explorer tree.',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorTabHeader extends StatelessWidget {
  const _EditorTabHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();
    final hasOpenFiles = state.openFiles.isNotEmpty;

    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: hasOpenFiles
          ? ReorderableListView(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              onReorder: state.reorderFile,
              children: state.openFiles
                  .map(
                    (itemPath) => ReorderableDragStartListener(
                      key: ValueKey(itemPath),
                      index: state.openFiles.indexOf(itemPath),
                      child: _TabItem(
                        itemPath: itemPath,
                        title: path.basename(itemPath),
                        isSelected: itemPath == state.activeFile,
                        isDirty: state.isFileDirty(itemPath),
                        onTap: () => state.openFile(itemPath),
                        onClose: () => state.closeFile(itemPath),
                        onCloseAll: () => state.closeAllFiles(),
                        onCloseOthers: () => state.closeOthers(itemPath),
                      ),
                    ),
                  )
                  .toList(),
            )
          : Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No file open',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _LspDiagnosticsBanner extends StatelessWidget {
  const _LspDiagnosticsBanner({required this.state});

  final EditorViewState state;

  @override
  Widget build(BuildContext context) {
    final diagnostics = state.lspDiagnostics;
    final shouldShowBanner =
        diagnostics.isNotEmpty || state.lspStatus == 'error';
    if (!shouldShowBanner) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final diagnostic = diagnostics.isNotEmpty ? diagnostics.first : null;
    final message = diagnostic != null
        ? '${diagnostic.location}: ${diagnostic.message}'
        : 'LSP ${state.lspStatus}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.itemPath,
    required this.title,
    required this.isSelected,
    required this.isDirty,
    required this.onTap,
    required this.onClose,
    required this.onCloseAll,
    required this.onCloseOthers,
  });

  final String itemPath;
  final String title;
  final bool isSelected;
  final bool isDirty;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onCloseAll;
  final VoidCallback onCloseOthers;

  void _showContextMenu(BuildContext context, Offset position) {
    final colorScheme = Theme.of(context).colorScheme;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      color: colorScheme.surface,
      elevation: 4,
      popUpAnimationStyle: AnimationStyle(duration: Duration.zero),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      items: [
        PopupMenuItem(
          height: 32,
          onTap: onClose,
          child: Text(
            'Close',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ),
        PopupMenuItem(
          height: 32,
          onTap: onCloseOthers,
          child: Text(
            'Close Others',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          height: 32,
          onTap: onCloseAll,
          child: Text(
            'Close All',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.surface : colorScheme.surfaceContainerLow,
      child: GestureDetector(
        onSecondaryTapDown: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                  width: 0.5,
                ),
                top: BorderSide(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 14,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isDirty)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.title,
    required this.shortcut,
    required this.description,
  });

  final String title;
  final String shortcut;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                shortcut,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtensionsTrailing extends StatelessWidget {
  const _ExtensionsTrailing({required this.extensionsKey});

  final GlobalKey<ExtensionsViewState> extensionsKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_horiz,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        tooltip: 'More actions',
        popUpAnimationStyle: AnimationStyle(duration: Duration.zero),
        color: colorScheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        onSelected: (value) {
          if (value == 'import') {
            extensionsKey.currentState?.importExtension();
          } else if (value == 'refresh') {
            extensionsKey.currentState?.reloadExtensions();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            height: 32,
            value: 'import',
            child: Text(
              'Import Extension',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
            ),
          ),
          PopupMenuItem(
            height: 32,
            value: 'refresh',
            child: Text(
              'Refresh',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedFileView extends StatelessWidget {
  const _UnsupportedFileView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              size: 56,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DualModeToolbar extends StatelessWidget {
  const _DualModeToolbar({required this.showPreview, required this.onToggle});

  final bool showPreview;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _ModeButton(
            label: 'Editor',
            icon: Icons.code,
            isSelected: !showPreview,
            onTap: showPreview ? onToggle : null,
          ),
          const SizedBox(width: 4),
          _ModeButton(
            label: 'Preview',
            icon: Icons.visibility,
            isSelected: showPreview,
            onTap: !showPreview ? onToggle : null,
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
