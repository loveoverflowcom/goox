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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;

    return CallbackShortcuts(
      bindings: {
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
          listenWhen: (_, current) => current.fileContent != null && current.fileContent!.content != _controller.text,
          listener: (context, state) {
            _controller.text = state.fileContent!.content;
          },
          builder: (context, state) {
            if (state.status == .loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == .error) {
              return Center(
                child: Column(
                  mainAxisAlignment: .center,
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
                  mainAxisAlignment: .center,
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

            final lines = state.fileContent!.content.split('\n');
            final lineCount = lines.length;

            return ColoredBox(
              color: editorTheme.editorBackground,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line numbers
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
                    child: Scrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: TextField(
                          controller: _controller,
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
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
