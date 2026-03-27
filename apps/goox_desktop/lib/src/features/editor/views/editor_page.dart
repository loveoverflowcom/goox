import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';
import 'package:goox_ui_shared/goox_ui_shared.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
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
  String? _lastSyntaxErrorSignature;

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

  Future<void> _loadFile(String? path) async {
    if (path == null) {
      await _controller.setActiveExtension(null);
      await _controller.loadDocument('');
      return;
    }

    try {
      final workspaceRoot = context.read<AppState>().rootPath ?? '';
      await GooxEditorSdkBootstrap.ensureInitialized(
        workspaceRoot: workspaceRoot,
      );

      final file = File(path);
      final extension = await GooxEditorSdkBootstrap.resolveExtensionForFile(
        workspaceRoot: workspaceRoot,
        filePath: path,
      );
      await _controller.setActiveExtension(extension);
      final isPdf = path.toLowerCase().endsWith('.pdf');

      if (isPdf && extension?.hasWasmEntry == true) {
        await GooxEditorSdkBootstrap.activateExtensionForFile(
          workspaceRoot: workspaceRoot,
          filePath: path,
        );
        if (mounted) {
          context.read<AppState>().markFileDirty(path, false);
        }
        return;
      }

      if (file.existsSync()) {
        final text = await file.readAsString();
        await _controller.loadDocument(text);
        await _updateSyntaxFeedback(text);
      } else {
        await _controller.loadDocument('');
        await _hideSyntaxError();
      }

      if (mounted) {
        context.read<AppState>().markFileDirty(path, false);
      }
    } catch (error) {
      await _controller.loadDocument('Error loading file: $error');
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

  Future<void> _handleEditorTextChanged(GooxEditorTextChange change) async {
    await _controller.replaceTextRange(
      change.start,
      change.end,
      change.replacement,
    );
    _markDirty();

    final activeExtension = _controller.stateListenable.value.activeExtension;
    final languageId = activeExtension?.languageId;
    if (languageId != null && languageId.trim().isNotEmpty) {
      final text = await _controller.getDocumentText();
      await _updateSyntaxFeedback(text);
    }
  }

  Future<void> _updateSyntaxFeedback(String text) async {
    final activeExtension = _controller.stateListenable.value.activeExtension;
    final languageId = activeExtension?.languageId?.trim().toLowerCase();
    if (languageId == null || languageId.isEmpty) {
      await _hideSyntaxError();
      return;
    }

    final syntaxError = await GooxEditorSdkBootstrap.validateSourceText(
      languageId: languageId,
      text: text,
    );
    if (!mounted) {
      return;
    }

    final signature =
        '${_loadedFilePath ?? ''}|$languageId|${syntaxError ?? 'ok'}';
    if (_lastSyntaxErrorSignature == signature) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (syntaxError == null) {
      _lastSyntaxErrorSignature = signature;
      messenger.hideCurrentSnackBar();
      return;
    }

    _lastSyntaxErrorSignature = signature;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(syntaxError),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _hideSyntaxError() async {
    _lastSyntaxErrorSignature = null;
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeFile = appState.activeFile;
    final hasActiveFile = activeFile != null;
    final isPdf =
        activeFile != null && activeFile.toLowerCase().endsWith('.pdf');
    final pdfFilePath = activeFile ?? '';

    return ValueListenableBuilder<EditorViewState>(
      valueListenable: _controller.stateListenable,
      builder: (context, state, _) {
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
              builder: (context) => const Center(child: Text('Extensions')),
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
              ? isPdf
                    ? _PdfPreviewPane(
                        key: ValueKey(activeFile),
                        filePath: activeFile,
                      )
                    : CallbackShortcuts(
                        bindings: <ShortcutActivator, VoidCallback>{
                          const SingleActivator(
                            LogicalKeyboardKey.keyS,
                            control: true,
                          ): () {
                            _saveCurrentFile();
                          },
                          const SingleActivator(
                            LogicalKeyboardKey.keyS,
                            meta: true,
                          ): () {
                            _saveCurrentFile();
                          },
                          const SingleActivator(
                            LogicalKeyboardKey.keyZ,
                            control: true,
                          ): () {
                            _controller.undo();
                            _markDirty();
                          },
                          const SingleActivator(
                            LogicalKeyboardKey.keyZ,
                            meta: true,
                          ): () {
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
                        ),
                      )
              : _EditorWelcomeView(onOpenFolder: appState.pickDirectory),
          statusBar: isPdf
              ? _PdfStatusBar(filePath: pdfFilePath)
              : GooxStatusBar(
                  revision: state.revision,
                  line: state.cursor.line,
                  column: state.cursor.column,
                ),
        );
      },
    );
  }
}

// ignore: unused_element
String? _syntaxErrorMessage({
  required String text,
  required String? languageId,
}) {
  if (text.trim().isEmpty || languageId == null) {
    return null;
  }

  switch (languageId) {
    case 'python':
      return _validatePythonSyntax(text);
    case 'javascript':
    case 'js':
    case 'typescript':
      return _validateJavaScriptSyntax(text);
    default:
      return null;
  }
}

String? _validatePythonSyntax(String text) {
  final scanner = _SyntaxScanner(text);
  return scanner.scan(
    allowHashComments: true,
    allowBlockComments: false,
    allowBackticks: false,
    languageName: 'Python',
  );
}

String? _validateJavaScriptSyntax(String text) {
  final scanner = _SyntaxScanner(text);
  return scanner.scan(
    allowHashComments: false,
    allowBlockComments: true,
    allowBackticks: true,
    languageName: 'JavaScript',
  );
}

class _SyntaxScanner {
  _SyntaxScanner(this.text);

  final String text;

  final List<_Delimiter> _stack = [];

  String? scan({
    required bool allowHashComments,
    required bool allowBlockComments,
    required bool allowBackticks,
    required String languageName,
  }) {
    var index = 0;

    while (index < text.length) {
      final current = text[index];

      if (allowHashComments && current == '#') {
        index = _lineEnd(index);
        continue;
      }

      if (allowBlockComments && _startsWith(index, '/*')) {
        final end = text.indexOf('*/', index + 2);
        if (end == -1) {
          return '$languageName syntax error: block comment is not closed.';
        }
        index = end + 2;
        continue;
      }

      if (allowBlockComments && _startsWith(index, '//')) {
        index = _lineEnd(index);
        continue;
      }

      if (allowBackticks && current == '`') {
        final end = _consumeString(index, '`', allowMultiline: true);
        if (end == -1) {
          return '$languageName syntax error: template string is not closed.';
        }
        index = end;
        continue;
      }

      if (_startsWith(index, "'''") || _startsWith(index, '"""')) {
        final quote = _startsWith(index, "'''") ? "'''" : '"""';
        final end = _consumeTripleString(index, quote);
        if (end == -1) {
          return '$languageName syntax error: string is not closed.';
        }
        index = end;
        continue;
      }

      if (current == '\'' || current == '"') {
        final end = _consumeString(index, current, allowMultiline: false);
        if (end == -1) {
          return '$languageName syntax error: string is not closed.';
        }
        index = end;
        continue;
      }

      if (_isOpenDelimiter(current)) {
        _stack.add(_Delimiter(current, index));
        index++;
        continue;
      }

      if (_isCloseDelimiter(current)) {
        if (_stack.isEmpty) {
          return '$languageName syntax error: unexpected "$current".';
        }

        final last = _stack.removeLast();
        if (last.closing != current) {
          return '$languageName syntax error: expected "${last.closing}" before "$current".';
        }

        index++;
        continue;
      }

      index++;
    }

    if (_stack.isNotEmpty) {
      final last = _stack.last;
      return '$languageName syntax error: missing "${last.closing}".';
    }

    return null;
  }

  bool _startsWith(int index, String pattern) {
    return index + pattern.length <= text.length &&
        text.substring(index, index + pattern.length) == pattern;
  }

  int _lineEnd(int index) {
    final newline = text.indexOf('\n', index);
    return newline == -1 ? text.length : newline;
  }

  int _consumeString(int start, String quote, {required bool allowMultiline}) {
    var index = start + 1;
    var escaped = false;

    while (index < text.length) {
      final current = text[index];
      if (!allowMultiline && current == '\n') {
        return -1;
      }

      if (escaped) {
        escaped = false;
        index++;
        continue;
      }

      if (current == '\\') {
        escaped = true;
        index++;
        continue;
      }

      if (current == quote) {
        return index + 1;
      }

      index++;
    }

    return -1;
  }

  int _consumeTripleString(int start, String quote) {
    var index = start + 3;
    while (index < text.length) {
      if (_startsWith(index, quote)) {
        return index + 3;
      }
      index++;
    }

    return -1;
  }

  bool _isOpenDelimiter(String char) =>
      char == '(' || char == '{' || char == '[';

  bool _isCloseDelimiter(String char) =>
      char == ')' || char == '}' || char == ']';
}

class _Delimiter {
  const _Delimiter(this.opening, this.index);

  final String opening;
  final int index;

  String get closing => switch (opening) {
    '(' => ')',
    '{' => '}',
    '[' => ']',
    _ => '',
  };
}

class _PdfPreviewPane extends StatefulWidget {
  const _PdfPreviewPane({super.key, required this.filePath});

  final String filePath;

  @override
  State<_PdfPreviewPane> createState() => _PdfPreviewPaneState();
}

class _PdfPreviewPaneState extends State<_PdfPreviewPane> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: PdfViewPinch(
        controller: _controller,
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          ),
          pageLoaderBuilder: (_) => Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          ),
          errorBuilder: (_, error) => Center(
            child: Text(
              'Failed to load PDF: $error',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _PdfStatusBar extends StatelessWidget {
  const _PdfStatusBar({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: colorScheme.primary,
      child: Row(
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 12,
            color: colorScheme.onPrimary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              path.basename(filePath),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'PDF view',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
          ),
        ],
      ),
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
          ? ListView(
              scrollDirection: Axis.horizontal,
              children: state.openFiles
                  .map(
                    (itemPath) => _TabItem(
                      title: path.basename(itemPath),
                      isSelected: itemPath == state.activeFile,
                      isDirty: state.isFileDirty(itemPath),
                      onTap: () => state.openFile(itemPath),
                      onClose: () => state.closeFile(itemPath),
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

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.title,
    required this.isSelected,
    required this.isDirty,
    required this.onTap,
    required this.onClose,
  });

  final String title;
  final bool isSelected;
  final bool isDirty;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.surface : colorScheme.surfaceContainerLow,
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
