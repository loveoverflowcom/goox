import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/editor_demo_controller.dart';
import '../models/editor_models.dart';
import '../widgets/editor_canvas.dart';

class EditorDemoPage extends StatefulWidget {
  const EditorDemoPage({super.key});

  @override
  State<EditorDemoPage> createState() => _EditorDemoPageState();
}

class _EditorDemoPageState extends State<EditorDemoPage> {
  late final EditorDemoController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = EditorDemoController();
    _focusNode = FocusNode(debugLabel: 'editor-demo');
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

    if (commandModified && logicalKey == LogicalKeyboardKey.keyZ) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        _controller.redo();
      } else {
        _controller.undo();
      }
      return KeyEventResult.handled;
    }

    if (commandModified) {
      return KeyEventResult.ignored;
    }

    switch (logicalKey) {
      case LogicalKeyboardKey.enter:
        _controller.insertNewline();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.backspace:
        _controller.backspace();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _controller.moveViewport(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _controller.moveViewport(1);
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
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<EditorViewState>(
          valueListenable: _controller.stateListenable,
          builder: (context, state, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 1100;
                final compactEditorHeight = switch (constraints.maxHeight) {
                  < 520 => 520.0,
                  > 760 => 760.0,
                  final height => height,
                };
                final shell = isCompact
                    ? ListView(
                        children: [
                          SizedBox(
                            height: compactEditorHeight,
                            child: _buildEditorColumn(context, state),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 440,
                            child: _buildSystemPanel(
                              context,
                              state,
                              stacked: constraints.maxWidth < 720,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: _buildEditorColumn(context, state),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 4,
                            child: _buildSystemPanel(context, state),
                          ),
                        ],
                      );

                return Padding(padding: const EdgeInsets.all(20), child: shell);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditorColumn(BuildContext context, EditorViewState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goox Editor Architecture Demo',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Flutter shell paints the viewport while a mock bridge mirrors the Rust-first data flow.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _FlowChip(label: 'Flutter shell'),
            _FlowChip(label: 'Event queue'),
            _FlowChip(label: 'Rust core'),
            _FlowChip(label: 'Patch stream'),
            _FlowChip(label: 'Viewport paint'),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.tonal(
              onPressed: _controller.seedDocument,
              child: const Text('Seed sample'),
            ),
            FilledButton(
              onPressed: _controller.loadLargeDocument,
              child: const Text('Load 120 lines'),
            ),
            OutlinedButton(
              onPressed: _controller.insertBurst,
              child: const Text('Insert patch burst'),
            ),
            OutlinedButton(
              onPressed: _controller.deleteCurrentLine,
              child: const Text('Delete line'),
            ),
            IconButton.filledTonal(
              onPressed: state.hasUndo ? _controller.undo : null,
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton.filledTonal(
              onPressed: state.hasRedo ? _controller.redo : null,
              icon: const Icon(Icons.redo_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: KeyboardListener(
              autofocus: true,
              focusNode: _focusNode,
              onKeyEvent: _handleKeyEvent,
              child: EditorCanvas(
                state: state,
                focusNode: _focusNode,
                onTap: _focusNode.requestFocus,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Keys: type to insert, Enter for newline, Backspace to delete, Cmd/Ctrl+Z to undo, Shift+Cmd/Ctrl+Z to redo, Arrow Up/Down to move viewport.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemPanel(
    BuildContext context,
    EditorViewState state, {
    bool stacked = false,
  }) {
    final ownershipCard = _PanelCard(
      title: 'Ownership',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _BulletLine('Rust owns the canonical buffer and revision clock.'),
          _BulletLine('Flutter observes patches and paints a viewport cache.'),
          _BulletLine(
            'Plugins return edits later; they never mutate directly.',
          ),
        ],
      ),
    );
    final patchCard = _PanelCard(
      title: 'Last patch batch',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.lastPatches.isEmpty)
            const _BulletLine('No patch applied yet in this frame window.')
          else
            for (final patch in state.lastPatches)
              _BulletLine(patch.description),
        ],
      ),
    );
    final ownershipAndPatches = stacked
        ? Column(
            children: [
              Expanded(child: ownershipCard),
              const SizedBox(height: 16),
              Expanded(child: patchCard),
            ],
          )
        : Row(
            children: [
              Expanded(child: ownershipCard),
              const SizedBox(width: 16),
              Expanded(child: patchCard),
            ],
          );

    return Column(
      children: [
        _MetricCard(state: state),
        const SizedBox(height: 16),
        Expanded(child: ownershipAndPatches),
        const SizedBox(height: 16),
        Expanded(
          child: _PanelCard(
            title: 'Event log',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final event in state.eventLog) _BulletLine(event),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.state});

  final EditorViewState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 180,
              child: _MetricValue(
                label: 'Revision',
                value: '${state.revision}',
              ),
            ),
            SizedBox(
              width: 220,
              child: _MetricValue(
                label: 'Buffer',
                value: '${state.totalLines} lines / ${state.totalChars} chars',
              ),
            ),
            SizedBox(
              width: 180,
              child: _MetricValue(
                label: 'Cursor',
                value: 'L${state.cursor.line} C${state.cursor.column}',
              ),
            ),
            SizedBox(
              width: 220,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.65),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last command',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.lastCommand,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricValue extends StatelessWidget {
  const _MetricValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}

class _FlowChip extends StatelessWidget {
  const _FlowChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xFFE7E0CC), Color(0xFFD6E7E5)],
        ),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text('- $text', style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
