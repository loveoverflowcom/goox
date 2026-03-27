import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';
import 'package:goox_ui_shared/goox_ui_shared.dart';
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
import '../../layout/views/vscode_layout.dart';

class EditorDemoPage extends StatefulWidget {
  const EditorDemoPage({super.key});

  @override
  State<EditorDemoPage> createState() => _EditorDemoPageState();
}

class _EditorDemoPageState extends State<EditorDemoPage> {
  late final GooxEditorController _controller;
  late final FocusNode _focusNode;
  String? _loadedFilePath;

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
      await _controller.loadDocument('');
      return;
    }

    try {
      final file = File(path);
      if (file.existsSync()) {
        final text = await file.readAsString();
        await _controller.loadDocument(text);
      } else {
        await _controller.loadDocument('');
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
    final hasActiveFile = appState.activeFile != null;

    return ValueListenableBuilder<EditorViewState>(
      valueListenable: _controller.stateListenable,
      builder: (context, state, _) {
        return VscodeLayout(
          editor: hasActiveFile
              ? CallbackShortcuts(
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
          statusBar: GooxStatusBar(
            revision: state.revision,
            line: state.cursor.line,
            column: state.cursor.column,
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
