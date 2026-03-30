import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';
import 'package:goox_ui_shared/goox_ui_shared.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GooxEditorSdkBootstrap.ensureInitialized();
  runApp(const SimpleEditorApp());
}

class SimpleEditorApp extends StatelessWidget {
  const SimpleEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goox Simple Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF264653)),
        useMaterial3: true,
      ),
      home: const SimpleEditorHome(),
    );
  }
}

class SimpleEditorHome extends StatefulWidget {
  const SimpleEditorHome({super.key});

  @override
  State<SimpleEditorHome> createState() => _SimpleEditorHomeState();
}

class _SimpleEditorHomeState extends State<SimpleEditorHome> {
  late final GooxEditorController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = GooxEditorController();
    _focusNode = FocusNode(debugLabel: 'simple-editor');
    _controller.seedDocument();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleEditorTextChanged(GooxEditorTextChange change) {
    return _controller.replaceTextRange(
      change.start,
      change.end,
      change.replacement,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EditorViewState>(
      valueListenable: _controller.stateListenable,
      builder: (context, state, _) {
        return GooxLayout(
          appBar: AppBar(
            title: const Text('Simple Editor Playground'),
            actions: [
              TextButton(
                onPressed: _controller.seedDocument,
                child: const Text('Seed'),
              ),
              TextButton(
                onPressed: _controller.loadLargeDocument,
                child: const Text('Large'),
              ),
            ],
          ),
          tabs: [
            GooxSearchTab(),
          ],
          editor: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(
                LogicalKeyboardKey.keyZ,
                control: true,
              ): () {
                _controller.undo();
              },
              const SingleActivator(
                LogicalKeyboardKey.keyZ,
                meta: true,
              ): () {
                _controller.undo();
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GooxEditorCanvas(
                state: state,
                focusNode: _focusNode,
                autofocus: true,
                onTap: _focusNode.requestFocus,
                onTextChanged: _handleEditorTextChanged,
                onCursorOffsetChanged: _controller.moveCursorToOffset,
              ),
            ),
          ),
          statusBar: GooxStatusBar(
            revision: state.revision,
            line: state.cursor.line,
            column: state.cursor.column,
            lspStatus: 'inactive',
            diagnosticCount: 0,
          ),
        );
      },
    );
  }
}
