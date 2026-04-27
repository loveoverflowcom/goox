import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/editor_content/presentation/blocs/editor_content_bloc.dart';
import 'package:goox_ui/goox_ui.dart';

final class TextEditorWidget extends StatefulWidget {
  const TextEditorWidget({super.key});

  @override
  State<TextEditorWidget> createState() => _TextEditorWidgetState();
}

final class _TextEditorWidgetState extends State<TextEditorWidget> {
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateCursorPosition() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.baseOffset >= 0) {
      final textBeforeCursor = text.substring(0, selection.baseOffset);
      final lines = textBeforeCursor.split('\n');
      final line = lines.length;
      final column = lines.last.length + 1;

      context.read<EditorContentBloc>().add(
        UpdateCursorPositionEvent(line: line, column: column),
      );
    }
  }

  void _handleEditorPointerDown(PointerDownEvent event) {
    _focusNode.requestFocus();

    // Defer the selection update so TextField's own tap handling does not
    // overwrite the end-of-file cursor placement on blank space clicks.
    final lines = _controller.text.split('\n').length;
    const lineHeight = AppSpacing.fontSize * AppSpacing.lineHeight;
    final contentHeight = lines * lineHeight + AppSpacing.editorPadding * 2;
    final tapY = event.localPosition.dy + _scrollController.offset;

    if (tapY >= contentHeight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final endPosition = _controller.text.length;
        _controller.selection = TextSelection.collapsed(offset: endPosition);
        _updateCursorPosition();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          context.read<EditorContentBloc>().add(const UndoContentEvent());
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          context.read<EditorContentBloc>().add(const UndoContentEvent());
        },
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          context.read<EditorContentBloc>().add(const RedoContentEvent());
        },
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true): () {
          context.read<EditorContentBloc>().add(const RedoContentEvent());
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () {
          context.read<EditorContentBloc>().add(const RedoContentEvent());
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          shift: true,
        ): () {
          context.read<EditorContentBloc>().add(const RedoContentEvent());
        },
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          context.read<EditorContentBloc>().add(const SaveFileEvent());
        },
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          context.read<EditorContentBloc>().add(const SaveFileEvent());
        },
      },
      child: Focus(
        autofocus: true,
        child: BlocConsumer<EditorContentBloc, EditorContentState>(
          listenWhen: (previous, current) =>
              current.fileContent != null &&
              !identical(previous.fileContent, current.fileContent),
          listener: (context, state) {
            _controller.text = state.fileContent!.content;
          },
          builder: (context, state) {
            if (state.status == EditorContentStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == EditorContentStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: AppSpacing.xxxlg,
                      color: editorTheme.textColor,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Error loading file',
                      style: TextStyle(
                        color: editorTheme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      state.errorMessage ?? 'Unknown error occurred',
                      style: TextStyle(
                        color: editorTheme.textColorDimmed,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (state.fileContent == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.code,
                      size: AppSpacing.xxxlg,
                      color: editorTheme.textColor,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No file open',
                      style: TextStyle(
                        color: editorTheme.textColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Select a file from the explorer to start editing',
                      style: TextStyle(
                        color: editorTheme.textColorDimmed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }

            final lineCount = state.fileContent!.lineCount;

            return ColoredBox(
              color: editorTheme.editorBackground,
              child: SizedBox.expand(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Scrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Line numbers scroll together with the editor content.
                            Container(
                              width: AppSpacing.lineNumberWidth,
                              color: editorTheme.editorBackground,
                              padding: const EdgeInsets.only(
                                right: AppSpacing.editorPadding,
                                top: AppSpacing.editorPadding,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  for (var i = 0; i < lineCount; i++)
                                    Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: editorTheme.textColorDimmed,
                                        fontSize: AppSpacing.fontSize,
                                        fontFamily: 'monospace',
                                        height: AppSpacing.lineHeight,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Editor content
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                maxLines: null,
                                style: TextStyle(
                                  color: editorTheme.textColor,
                                  fontSize: AppSpacing.fontSize,
                                  fontFamily: 'monospace',
                                  height: AppSpacing.lineHeight,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(
                                    AppSpacing.editorPadding,
                                  ),
                                ),
                                onChanged: (value) {
                                  context.read<EditorContentBloc>().add(
                                    UpdateContentEvent(value),
                                  );
                                  _updateCursorPosition();
                                },
                                onTap: _updateCursorPosition,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: _handleEditorPointerDown,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
