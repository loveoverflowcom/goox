import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'goox_terminal_bridge.dart';
import 'goox_layout.dart';

class GooxTerminalPanelTab extends GooxWidgetPanel {
  GooxTerminalPanelTab({
    super.id = 'terminal',
    super.title = 'Terminal',
    String? workingDirectory,
  }) : super(
         icon: Icons.terminal_rounded,
         shortcuts: const <ShortcutActivator>[
           SingleActivator(LogicalKeyboardKey.backquote, control: true),
           SingleActivator(LogicalKeyboardKey.backquote, meta: true),
         ],
         builder: (context) =>
             GooxTerminalPanel(workingDirectory: workingDirectory),
       );
}

class TerminalCell {
  final String char;
  final Color? fgColor;
  final Color? bgColor;
  final bool bold;

  const TerminalCell({
    this.char = ' ',
    this.fgColor,
    this.bgColor,
    this.bold = false,
  });
}

class TerminalScreenState {
  final List<List<TerminalCell>> grid;
  final int cursorRow;
  final int cursorCol;
  final int generation;
  final bool isAlternateScreen;
  final bool cursorVisible;
  final bool isExited;
  final int? exitCode;
  final String? exitMessage;
  final String? errorMessage;

  const TerminalScreenState({
    required this.grid,
    required this.cursorRow,
    required this.cursorCol,
    required this.generation,
    required this.isAlternateScreen,
    required this.cursorVisible,
    required this.isExited,
    this.exitCode,
    this.exitMessage,
    this.errorMessage,
  });

  factory TerminalScreenState.empty({
    required int rows,
    required int cols,
    String? errorMessage,
  }) {
    return TerminalScreenState(
      grid: List.generate(
        rows,
        (_) => List.generate(cols, (_) => const TerminalCell()),
      ),
      cursorRow: 0,
      cursorCol: 0,
      generation: 0,
      isAlternateScreen: false,
      cursorVisible: true,
      isExited: false,
      errorMessage: errorMessage,
    );
  }
}

class TerminalSelection {
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;

  const TerminalSelection({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });

  bool contains(int row, int col) {
    int sR = startRow, sC = startCol, eR = endRow, eC = endCol;
    if (sR > eR || (sR == eR && sC > eC)) {
      sR = endRow;
      sC = endCol;
      eR = startRow;
      eC = startCol;
    }
    if (row < sR || row > eR) return false;
    if (row == sR && row == eR) return col >= sC && col <= eC;
    if (row == sR) return col >= sC;
    if (row == eR) return col <= eC;
    return true;
  }
}

class TerminalController extends ChangeNotifier {
  TerminalController({this.workingDirectory, this.cols = 80, this.rows = 24})
      : _state = TerminalScreenState.empty(rows: rows, cols: cols) {
    _bootstrap();
  }

  final String? workingDirectory;
  final int cols;
  final int rows;
  final Future<RustTerminalBridge> _bridgeFuture = RustTerminalBridge.instance();
  final List<String> _pendingInput = <String>[];
  TerminalScreenState _state;
  TerminalSelection? _selection;
  Timer? _pollTimer;
  int? _terminalId;
  bool _disposed = false;

  TerminalScreenState get state => _state;
  TerminalSelection? get selection => _selection;

  Future<void> _bootstrap() async {
    try {
      final bridge = await _bridgeFuture;
      if (_disposed) {
        return;
      }

      _terminalId = bridge.createTerminal(
        rows: rows,
        cols: cols,
        workingDirectory: workingDirectory,
      );
      if (_disposed) {
        bridge.dispose(_terminalId!);
        return;
      }
      _startPolling();
      await _refreshFromBridge();
      _flushPendingInput();
    } catch (error) {
      _state = TerminalScreenState.empty(
        rows: rows,
        cols: cols,
        errorMessage: 'Terminal unavailable: $error',
      );
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => unawaited(_refreshFromBridge()),
    );
  }

  Future<void> _refreshFromBridge() async {
    if (_disposed) {
      return;
    }

    final terminalId = _terminalId;
    if (terminalId == null) {
      return;
    }

    try {
      final bridge = await _bridgeFuture;
      final snapshot = bridge.pollScreen(terminalId);
      final nextState = _stateFromSnapshot(snapshot);
      final shouldNotify =
          _state.generation != nextState.generation ||
          _state.isExited != nextState.isExited ||
          _state.exitMessage != nextState.exitMessage ||
          _state.errorMessage != nextState.errorMessage ||
          _state.cursorRow != nextState.cursorRow ||
          _state.cursorCol != nextState.cursorCol;

      _state = nextState;

      if (shouldNotify && !_disposed) {
        notifyListeners();
      }

      if (nextState.isExited) {
        _pollTimer?.cancel();
      }
    } catch (error) {
      if (!_disposed) {
        _state = TerminalScreenState.empty(
          rows: rows,
          cols: cols,
          errorMessage: 'Terminal poll failed: $error',
        );
        notifyListeners();
      }
    }
  }

  void _flushPendingInput() {
    if (_pendingInput.isEmpty) {
      return;
    }

    final pending = List<String>.from(_pendingInput);
    _pendingInput.clear();
    for (final input in pending) {
      unawaited(_sendInputString(input));
    }
  }

  Future<void> _sendInputString(String input) async {
    if (_disposed) {
      return;
    }

    final terminalId = _terminalId;
    if (terminalId == null) {
      return;
    }

    final bridge = await _bridgeFuture;
    final bytes = Uint8List.fromList(utf8.encode(input));
    final ok = bridge.sendInput(terminalId, bytes);
    if (!ok && !_disposed) {
      _state = TerminalScreenState.empty(
        rows: rows,
        cols: cols,
        errorMessage: 'Failed to write to terminal backend',
      );
      notifyListeners();
      return;
    }

    unawaited(_refreshFromBridge());
  }

  TerminalScreenState _stateFromSnapshot(RustTerminalScreenSnapshot snapshot) {
    final grid = snapshot.grid
        .map(
          (row) => row.cells.map(_cellFromSnapshot).toList(growable: false),
        )
        .toList(growable: false);

    return TerminalScreenState(
      grid: grid,
      cursorRow: snapshot.cursorY,
      cursorCol: snapshot.cursorX,
      generation: snapshot.generation,
      isAlternateScreen: snapshot.isAlternateScreen,
      cursorVisible: snapshot.cursorVisible,
      isExited: snapshot.exited,
      exitCode: snapshot.exitCode,
      exitMessage: snapshot.exitMessage,
    );
  }

  TerminalCell _cellFromSnapshot(RustTerminalCellSnapshot cell) {
    return TerminalCell(
      char: cell.ch.isEmpty ? ' ' : cell.ch,
      fgColor: _colorFromArgb(cell.fg),
      bgColor: _colorFromArgb(cell.bg),
      bold: cell.bold,
    );
  }

  Color? _colorFromArgb(int? value) => value == null ? null : Color(value);

  void setSelection(TerminalSelection? selection) {
    _selection = selection;
    notifyListeners();
  }

  String getSelectedText() {
    if (_selection == null) return '';
    final buffer = StringBuffer();
    int sR = _selection!.startRow;
    int sC = _selection!.startCol;
    int eR = _selection!.endRow;
    int eC = _selection!.endCol;

    if (sR > eR || (sR == eR && sC > eC)) {
      sR = _selection!.endRow;
      sC = _selection!.endCol;
      eR = _selection!.startRow;
      eC = _selection!.startCol;
    }

    for (int r = sR; r <= eR; r++) {
      if (r < 0 || r >= _state.grid.length) continue;
      final row = _state.grid[r];
      int startC = (r == sR) ? sC : 0;
      int endC = (r == eR) ? eC : cols - 1;

      String rowStr = '';
      for (int c = startC; c <= endC; c++) {
        if (c < 0 || c >= row.length) {
          rowStr += ' ';
          continue;
        }
        final char = row[c].char;
        rowStr += char.isEmpty ? ' ' : char;
      }

      buffer.write(rowStr);
      if (r < eR) {
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  void sendInput(String input) {
    if (_disposed) {
      return;
    }
    if (_terminalId == null) {
      _pendingInput.add(input);
      return;
    }
    unawaited(_sendInputString(input));
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    final terminalId = _terminalId;
    if (terminalId != null) {
      unawaited(
        RustTerminalBridge.instance()
            .then((bridge) => bridge.dispose(terminalId))
            .catchError((_) {}),
      );
    }
    super.dispose();
  }
}

class _TerminalTabModel {
  _TerminalTabModel({
    required this.id,
    required this.shellName,
    this.workingDirectory,
  }) : controller = TerminalController(workingDirectory: workingDirectory);

  final String id;
  final String shellName;
  final String? workingDirectory;
  final TerminalController controller;

  String get label {
    final dir = workingDirectory;
    if (dir == null || dir.isEmpty) {
      return shellName;
    }
    final parts = dir
        .split(Platform.pathSeparator)
        .where((part) => part.isNotEmpty);
    final baseName = parts.isEmpty ? null : parts.last;
    if (baseName == null || baseName.isEmpty) {
      return shellName;
    }
    return '$shellName ($baseName)';
  }

  void dispose() => controller.dispose();
}

class _TerminalTabsController extends ChangeNotifier {
  _TerminalTabsController({String? initialDirectory}) {
    addTab(workingDirectory: initialDirectory);
  }

  final List<_TerminalTabModel> _tabs = <_TerminalTabModel>[];
  int _activeIndex = 0;

  List<_TerminalTabModel> get tabs => List.unmodifiable(_tabs);
  int get activeIndex => _activeIndex;
  _TerminalTabModel? get activeTab =>
      _tabs.isEmpty ? null : _tabs[_activeIndex.clamp(0, _tabs.length - 1)];

  void addTab({String? workingDirectory}) {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    final shellName = shell.split('/').last;
    _tabs.add(
      _TerminalTabModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        shellName: shellName,
        workingDirectory: workingDirectory,
      ),
    );
    _activeIndex = _tabs.length - 1;
    notifyListeners();
  }

  void removeTab(int index) {
    if (_tabs.isEmpty || index < 0 || index >= _tabs.length) {
      return;
    }
    _tabs[index].dispose();
    _tabs.removeAt(index);
    if (_tabs.isEmpty) {
      addTab();
      return;
    }
    _activeIndex = _activeIndex.clamp(0, _tabs.length - 1);
    notifyListeners();
  }

  void switchTab(int index) {
    if (index < 0 || index >= _tabs.length) {
      return;
    }
    _activeIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final tab in _tabs) {
      tab.dispose();
    }
    super.dispose();
  }
}

class TerminalView extends StatefulWidget {
  const TerminalView({super.key, required this.controller});

  final TerminalController controller;

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  Size _charSize = const Size(8.4, 16.0);
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measureCharSize();
  }

  void _measureCharSize() {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'x',
        style: TextStyle(
          fontSize: 13,
          fontFamilyFallback: ['Menlo', 'Consolas', 'Courier New', 'monospace'],
          fontWeight: FontWeight.normal,
          height: 1,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    if (tp.width > 0 && tp.height > 0) {
      if (_charSize.width != tp.width || _charSize.height != tp.height) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _charSize = Size(tp.width, tp.height);
            });
          }
        });
      }
    }
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return;
    }

    final key = event.logicalKey;
    String? input;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final copyShortcut = Platform.isMacOS
        ? (isMeta && key == LogicalKeyboardKey.keyC)
        : (isCtrl && key == LogicalKeyboardKey.keyC);

    if (copyShortcut) {
      final text = widget.controller.getSelectedText();
      if (text.isNotEmpty) {
        Clipboard.setData(ClipboardData(text: text));
        widget.controller.setSelection(null);
        return;
      }
      // On non-macOS, Ctrl+C with no selection should send SIGINT (\x03)
      if (!Platform.isMacOS && isCtrl && key == LogicalKeyboardKey.keyC) {
        input = '\x03';
      }
    }

    if (input == null) {
      if (key == LogicalKeyboardKey.enter) {
        input = '\r';
      } else if (key == LogicalKeyboardKey.backspace) {
        input = '\x7f';
      } else if (key == LogicalKeyboardKey.tab) {
        input = '\t';
      } else if (key == LogicalKeyboardKey.escape) {
        input = '\x1b';
      } else if (key == LogicalKeyboardKey.arrowUp) {
        input = '\x1b[A';
      } else if (key == LogicalKeyboardKey.arrowDown) {
        input = '\x1b[B';
      } else if (key == LogicalKeyboardKey.arrowRight) {
        input = '\x1b[C';
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        input = '\x1b[D';
      } else if (event.character != null && event.character!.isNotEmpty) {
        if (HardwareKeyboard.instance.isControlPressed) {
          final code = event.character!.codeUnitAt(0);
          if (code >= 97 && code <= 122) {
            input = String.fromCharCode(code - 96);
          }
        } else {
          input = event.character;
        }
      }
    }

    if (input != null) {
      widget.controller.sendInput(input);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final termBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        _onKey(event);
        return KeyEventResult.handled;
      },
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
          widget.controller.setSelection(null);
        },
        // Only allow selection with primary button (left click)
        onPanStart: (details) {
          _focusNode.requestFocus();
          final row = (details.localPosition.dy / _charSize.height)
              .floor()
              .clamp(0, widget.controller.rows - 1);
          final col = (details.localPosition.dx / _charSize.width)
              .floor()
              .clamp(0, widget.controller.cols - 1);
          widget.controller.setSelection(
            TerminalSelection(
              startRow: row,
              startCol: col,
              endRow: row,
              endCol: col,
            ),
          );
        },
        onPanUpdate: (details) {
          final row = (details.localPosition.dy / _charSize.height)
              .floor()
              .clamp(0, widget.controller.rows - 1);
          final col = (details.localPosition.dx / _charSize.width)
              .floor()
              .clamp(0, widget.controller.cols - 1);
          final current = widget.controller.selection;
          if (current != null) {
            widget.controller.setSelection(
              TerminalSelection(
                startRow: current.startRow,
                startCol: current.startCol,
                endRow: row,
                endCol: col,
              ),
            );
          }
        },
        child: Container(
          color: termBg,
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              return ListenableBuilder(
                listenable: _focusNode,
                builder: (context, _) {
                  final state = widget.controller.state;
                  final selection = widget.controller.selection;
                  final statusMessage = state.errorMessage ?? state.exitMessage;
                  return Stack(
                    children: [
                      CustomPaint(
                        painter: _TerminalPainter(
                          state: state,
                          selection: selection,
                          hasFocus: _focusNode.hasFocus,
                          charW: _charSize.width,
                          charH: _charSize.height,
                          isDark: isDark,
                        ),
                        size: Size(
                          widget.controller.cols * _charSize.width,
                          widget.controller.rows * _charSize.height,
                        ),
                      ),
                      if (statusMessage != null)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                statusMessage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TerminalPainter extends CustomPainter {
  _TerminalPainter({
    required this.state,
    this.selection,
    required this.hasFocus,
    required this.charW,
    required this.charH,
    required this.isDark,
  });

  final TerminalScreenState state;
  final TerminalSelection? selection;
  final bool hasFocus;
  final bool isDark;
  final double charW;
  final double charH;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..style = PaintingStyle.fill;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    // Higher contrast default colors
    final defaultFg = isDark
        ? const Color(0xFFE5E5E5)
        : const Color(0xFF111111);
    final cursorColor = isDark
        ? const Color(0xFFE5E5E5)
        : const Color(0xFF111111);
    final cursorTextColor = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF5F5F5);
    final selectionBg = isDark
        ? const Color(0xFF264F78)
        : const Color(0xFFADD6FF);

    for (var r = 0; r < state.grid.length; r++) {
      final row = state.grid[r];
      for (var c = 0; c < row.length; c++) {
        final cell = row[c];
        final x = c * charW;
        final y = r * charH;
        Color? bg = cell.bgColor;

        final isSelected = selection?.contains(r, c) ?? false;
        if (isSelected) {
          bg = selectionBg;
        }

        final isCursor =
            state.cursorVisible && r == state.cursorRow && c == state.cursorCol;
        if (isCursor && !isSelected) {
          bg = hasFocus ? cursorColor : cursorColor.withValues(alpha: 0.5);
        }

        if (bg != null) {
          bgPaint.color = bg;
          canvas.drawRect(Rect.fromLTWH(x, y, charW, charH), bgPaint);
        }

        final ch = cell.char;
        if (ch.isNotEmpty && ch != ' ') {
          var fg = cell.fgColor ?? defaultFg;
          if (isCursor && !isSelected) {
            fg = cursorTextColor;
          }
          tp.text = TextSpan(
            text: ch,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontFamilyFallback: const [
                'Menlo',
                'Consolas',
                'Courier New',
                'monospace',
              ],
              fontWeight: cell.bold ? FontWeight.bold : FontWeight.normal,
              height: 1,
              letterSpacing: 0,
            ),
          );
          tp.layout();
          tp.paint(canvas, Offset(x, y + (charH - tp.height) / 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TerminalPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.selection != selection ||
        oldDelegate.hasFocus != hasFocus ||
        oldDelegate.isDark != isDark ||
        oldDelegate.charW != charW ||
        oldDelegate.charH != charH;
  }
}

class GooxTerminalPanel extends StatefulWidget {
  const GooxTerminalPanel({super.key, this.workingDirectory});

  final String? workingDirectory;

  @override
  State<GooxTerminalPanel> createState() => _GooxTerminalPanelState();
}

class _GooxTerminalPanelState extends State<GooxTerminalPanel> {
  late final _TerminalTabsController _tabsController;

  @override
  void initState() {
    super.initState();
    _tabsController = _TerminalTabsController(
      initialDirectory: widget.workingDirectory,
    );
  }

  @override
  void dispose() {
    _tabsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _tabsController,
      builder: (context, _) {
        final tabs = _tabsController.tabs;
        final activeIndex = _tabsController.activeIndex;
        final activeTab = _tabsController.activeTab;

        return Column(
          children: [
            Container(
              height: 33,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'TERMINAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 18,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tabs.length,
                      itemBuilder: (context, index) => _TerminalTabChip(
                        label: tabs[index].label,
                        isActive: index == activeIndex,
                        onTap: () => _tabsController.switchTab(index),
                        onClose: tabs.length > 1
                            ? () => _tabsController.removeTab(index)
                            : null,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      onTap: () => _tabsController.addTab(
                        workingDirectory: widget.workingDirectory,
                      ),
                      child: SizedBox(
                        width: 32,
                        height: 33,
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      onTap: () => GooxLayout.togglePanel(context, 'terminal'),
                      child: SizedBox(
                        width: 32,
                        height: 33,
                        child: Icon(
                          Icons.remove_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: activeTab == null
                  ? const SizedBox.shrink()
                  : IndexedStack(
                      index: activeIndex,
                      children: tabs
                          .map(
                            (tab) => TerminalView(controller: tab.controller),
                          )
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TerminalTabChip extends StatelessWidget {
  const _TerminalTabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onClose,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 33,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.surface : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: isActive ? colorScheme.primary : Colors.transparent,
              width: 1.5,
            ),
            right: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.terminal_rounded,
              size: 13,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (onClose != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
