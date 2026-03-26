import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/editor_demo_controller.dart';
import '../models/editor_models.dart';
import '../widgets/editor_canvas.dart';
import '../../layout/views/vscode_layout.dart';
import '../../../state/app_state.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class EditorDemoPage extends StatefulWidget {
  const EditorDemoPage({super.key});

  @override
  State<EditorDemoPage> createState() => _EditorDemoPageState();
}

class _EditorDemoPageState extends State<EditorDemoPage> {
  late final EditorDemoController _controller;
  late final FocusNode _focusNode;
  String? _loadedFilePath;

  @override
  void initState() {
    super.initState();
    _controller = EditorDemoController();
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
    } catch (e) {
      await _controller.loadDocument('Error loading file: $e');
    }
  }

  Future<void> _saveCurrentFile() async {
    final path = _loadedFilePath;
    if (path == null) return;
    try {
      final text = await _controller.getDocumentText();
      await File(path).writeAsString(text);
      if (mounted) {
        context.read<AppState>().markFileDirty(path, false);
      }
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  void _markDirty() {
    if (_loadedFilePath != null && mounted) {
      context.read<AppState>().markFileDirty(_loadedFilePath!, true);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final pressedControl = HardwareKeyboard.instance.isControlPressed;
    final pressedMeta = HardwareKeyboard.instance.isMetaPressed;
    final commandModified = pressedControl || pressedMeta;
    final logicalKey = event.logicalKey;

    if (commandModified && logicalKey == LogicalKeyboardKey.keyS) {
      _saveCurrentFile();
      return KeyEventResult.handled;
    }

    if (commandModified && logicalKey == LogicalKeyboardKey.keyZ) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        _controller.redo();
      } else {
        _controller.undo();
      }
      _markDirty();
      return KeyEventResult.handled;
    }

    if (commandModified) {
      return KeyEventResult.ignored;
    }

    switch (logicalKey) {
      case LogicalKeyboardKey.enter:
        _controller.insertNewline();
        _markDirty();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.backspace:
        _controller.backspace();
        _markDirty();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _controller.moveViewport(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _controller.moveViewport(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _controller.moveCursorRelative(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _controller.moveCursorRelative(1);
        return KeyEventResult.handled;
      default:
        break;
    }

    final character = event.character;
    if (character == null ||
        character.isEmpty ||
        character == '\t' ||
        character == '\r') {
      return KeyEventResult.ignored;
    }

    _controller.insertText(character);
    _markDirty();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EditorViewState>(
      valueListenable: _controller.stateListenable,
      builder: (context, state, _) {
        return VscodeLayout(
          editor: KeyboardListener(
            autofocus: true,
            focusNode: _focusNode,
            onKeyEvent: _handleKeyEvent,
            child: EditorCanvas(
              state: state,
              focusNode: _focusNode,
              onTap: _focusNode.requestFocus,
              onTapDown: (details, ctx) {
                final y = details.localPosition.dy;
                final x = details.localPosition.dx;
                const gutterWidth = 70.0;
                const lineHeight = 32.0;
                const topPadding = 20.0;
                
                final relativeLineIndex = ((y - topPadding) / lineHeight).floor();
                if (relativeLineIndex < 0 || relativeLineIndex >= state.visibleLines.length) {
                  return;
                }
                
                final clickedLine = state.visibleLines[relativeLineIndex];
                final lineIndex = clickedLine.lineNumber;
                
                // monospace size 16 approx width is 9.6
                final col = ((x - gutterWidth - 16) / 9.6).round() + 1;
                final column = col.clamp(1, clickedLine.text.length + 1);
                
                _controller.moveCursorToPosition(lineIndex, column);
              },
            ),
          ),
          statusBar: StatusBar(
            revision: state.revision,
            line: state.cursor.line,
            column: state.cursor.column,
          ),
        );
      },
    );
  }
}

