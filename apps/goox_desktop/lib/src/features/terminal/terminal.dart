import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Data Models ──────────────────────────────────────────────────────────────

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

  const TerminalScreenState({
    required this.grid,
    required this.cursorRow,
    required this.cursorCol,
  });
}

// ── ANSI Parser ──────────────────────────────────────────────────────────────

class _AnsiParser {
  final int cols;
  final int rows;

  final List<List<TerminalCell>> _grid;
  int _cursorRow = 0;
  int _cursorCol = 0;
  Color? _fgColor;
  Color? _bgColor;
  bool _bold = false;

  final StringBuffer _escBuffer = StringBuffer();
  bool _inEscape = false;
  bool _inCsi = false;

  _AnsiParser({required this.cols, required this.rows})
      : _grid = List.generate(
          rows,
          (_) => List.generate(cols, (_) => const TerminalCell()),
        );

  TerminalScreenState get state => TerminalScreenState(
        grid: _grid
            .map((row) => List<TerminalCell>.from(row))
            .toList(growable: false),
        cursorRow: _cursorRow,
        cursorCol: _cursorCol,
      );

  void process(List<int> bytes) {
    final decoded = utf8.decode(bytes, allowMalformed: true);
    for (int i = 0; i < decoded.length; i++) {
      final ch = decoded[i];
      final code = ch.codeUnitAt(0);

      if (_inEscape) {
        if (_inCsi) {
          _escBuffer.write(ch);
          if (code >= 0x40 && code <= 0x7E) {
            _processCsi(_escBuffer.toString());
            _escBuffer.clear();
            _inEscape = false;
            _inCsi = false;
          }
        } else {
          if (ch == '[') {
            _inCsi = true;
            _escBuffer.clear();
          } else if (ch == ']') {
            // OSC - skip until BEL or ST
            _inEscape = false;
          } else {
            _inEscape = false;
          }
        }
      } else if (code == 0x1B) {
        _inEscape = true;
        _inCsi = false;
        _escBuffer.clear();
      } else {
        _processChar(ch, code);
      }
    }
  }

  void _processChar(String ch, int code) {
    switch (code) {
      case 0x0A:
        _lineFeed();
        break;
      case 0x0D:
        _cursorCol = 0;
        break;
      case 0x08:
        if (_cursorCol > 0) _cursorCol--;
        break;
      case 0x07:
        break;
      default:
        if (code >= 0x20) {
          _putChar(ch);
        }
    }
  }

  void _putChar(String ch) {
    if (_cursorRow >= rows || _cursorCol >= cols) return;
    _grid[_cursorRow][_cursorCol] = TerminalCell(
      char: ch,
      fgColor: _bold && _fgColor == null ? const Color(0xFFFFFFFF) : _fgColor,
      bgColor: _bgColor,
      bold: _bold,
    );
    _cursorCol++;
    if (_cursorCol >= cols) {
      _cursorCol = 0;
      _lineFeed();
    }
  }

  void _lineFeed() {
    if (_cursorRow + 1 >= rows) {
      _grid.removeAt(0);
      _grid.add(List.generate(cols, (_) => const TerminalCell()));
    } else {
      _cursorRow++;
    }
  }

  void _processCsi(String seq) {
    if (seq.isEmpty) return;
    final action = seq[seq.length - 1];
    final paramStr = seq.substring(0, seq.length - 1);
    // Handle private mode sequences (starting with ?)
    final cleaned = paramStr.startsWith('?') ? paramStr.substring(1) : paramStr;
    final params = cleaned
        .split(';')
        .map((s) => int.tryParse(s) ?? 0)
        .toList();

    switch (action) {
      case 'H':
      case 'f':
        final row = (params.isNotEmpty ? params[0] : 1);
        final col = (params.length > 1 ? params[1] : 1);
        _cursorRow = (row - 1).clamp(0, rows - 1);
        _cursorCol = (col - 1).clamp(0, cols - 1);
        break;
      case 'A':
        _cursorRow =
            (_cursorRow - (params.isNotEmpty ? params[0] : 1)).clamp(0, rows - 1);
        break;
      case 'B':
        _cursorRow =
            (_cursorRow + (params.isNotEmpty ? params[0] : 1)).clamp(0, rows - 1);
        break;
      case 'C':
        _cursorCol =
            (_cursorCol + (params.isNotEmpty ? params[0] : 1)).clamp(0, cols - 1);
        break;
      case 'D':
        _cursorCol =
            (_cursorCol - (params.isNotEmpty ? params[0] : 1)).clamp(0, cols - 1);
        break;
      case 'G':
        // Cursor horizontally absolute
        _cursorCol = ((params.isNotEmpty ? params[0] : 1) - 1).clamp(0, cols - 1);
        break;
      case 'J':
        _eraseInDisplay(params.isNotEmpty ? params[0] : 0);
        break;
      case 'K':
        _eraseInLine(params.isNotEmpty ? params[0] : 0);
        break;
      case 'm':
        if (params.isEmpty || (params.length == 1 && params[0] == 0)) {
          _applySgr([0]);
        } else {
          _applySgr(params);
        }
        break;
      // Ignore mode-setting sequences (h/l)
      case 'h':
      case 'l':
        break;
    }
  }

  void _eraseInLine(int mode) {
    switch (mode) {
      case 0:
        for (int c = _cursorCol; c < cols; c++) {
          _grid[_cursorRow][c] = const TerminalCell();
        }
        break;
      case 1:
        for (int c = 0; c <= _cursorCol && c < cols; c++) {
          _grid[_cursorRow][c] = const TerminalCell();
        }
        break;
      case 2:
        for (int c = 0; c < cols; c++) {
          _grid[_cursorRow][c] = const TerminalCell();
        }
        break;
    }
  }

  void _eraseInDisplay(int mode) {
    switch (mode) {
      case 0:
        _eraseInLine(0);
        for (int r = _cursorRow + 1; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            _grid[r][c] = const TerminalCell();
          }
        }
        break;
      case 1:
        for (int r = 0; r < _cursorRow; r++) {
          for (int c = 0; c < cols; c++) {
            _grid[r][c] = const TerminalCell();
          }
        }
        _eraseInLine(1);
        break;
      case 2:
      case 3:
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            _grid[r][c] = const TerminalCell();
          }
        }
        break;
    }
  }

  void _applySgr(List<int> params) {
    for (int i = 0; i < params.length; i++) {
      final p = params[i];
      if (p == 0) {
        _fgColor = null;
        _bgColor = null;
        _bold = false;
      } else if (p == 1) {
        _bold = true;
      } else if (p == 22) {
        _bold = false;
      } else if (p >= 30 && p <= 37) {
        _fgColor = _ansiColor(p - 30, false);
      } else if (p == 39) {
        _fgColor = null;
      } else if (p >= 40 && p <= 47) {
        _bgColor = _ansiColor(p - 40, false);
      } else if (p == 49) {
        _bgColor = null;
      } else if (p >= 90 && p <= 97) {
        _fgColor = _ansiColor(p - 90, true);
      } else if (p >= 100 && p <= 107) {
        _bgColor = _ansiColor(p - 100, true);
      }
    }
  }

  static Color _ansiColor(int idx, bool bright) {
    const normal = [
      Color(0xFF000000), // black
      Color(0xFFCC0000), // red
      Color(0xFF00CC00), // green
      Color(0xFFCCCC00), // yellow
      Color(0xFF0000CC), // blue
      Color(0xFFCC00CC), // magenta
      Color(0xFF00CCCC), // cyan
      Color(0xFFCCCCCC), // white
    ];
    const brightColors = [
      Color(0xFF666666), // bright black
      Color(0xFFFF5555), // bright red
      Color(0xFF55FF55), // bright green
      Color(0xFFFFFF55), // bright yellow
      Color(0xFF5555FF), // bright blue
      Color(0xFFFF55FF), // bright magenta
      Color(0xFF55FFFF), // bright cyan
      Color(0xFFFFFFFF), // bright white
    ];
    final list = bright ? brightColors : normal;
    return list[idx.clamp(0, 7)];
  }
}

// ── TerminalSession ──────────────────────────────────────────────────────────
// Uses dart:io Process with an interactive-mode shell invoked via `script`
// (macOS/Linux) so that the shell emits a prompt immediately.

class TerminalSession {
  final int cols;
  final int rows;
  final String? workingDirectory;

  Process? _process;
  final _AnsiParser _parser;
  bool _started = false;

  final _screenController = StreamController<TerminalScreenState>.broadcast();
  Stream<TerminalScreenState> get screenUpdates => _screenController.stream;

  // Immediately returns an empty (but non-null) grid on first access.
  TerminalScreenState get currentState => _parser.state;

  TerminalSession({
    this.cols = 80,
    this.rows = 24,
    this.workingDirectory,
  }) : _parser = _AnsiParser(cols: cols, rows: rows) {
    _start();
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    try {
      final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
      final env = {
        ...Platform.environment,
        'TERM': 'xterm-256color',
        'COLUMNS': '$cols',
        'LINES': '$rows',
        'LANG': 'en_US.UTF-8',
      };

      // On macOS/Linux, use the `script` utility to force a PTY-like
      // environment that makes the shell emit a prompt immediately.
      // `script -q /dev/null <shell>` creates a pseudo-terminal wrapper.
      if (Platform.isMacOS || Platform.isLinux) {
        _process = await Process.start(
          'script',
          ['-q', '/dev/null', shell, '-i'],
          workingDirectory: workingDirectory,
          environment: env,
          runInShell: false,
        );
      } else {
        // Windows / fallback
        _process = await Process.start(
          shell,
          ['-i'],
          workingDirectory: workingDirectory,
          environment: env,
          runInShell: false,
        );
      }

      _process!.stdout.listen(_onData);
      _process!.stderr.listen(_onData);
      _process!.exitCode.then((_) {
        if (!_screenController.isClosed) {
          _screenController.close();
        }
      });
    } catch (e) {
      debugPrint('[Terminal] Failed to start: $e');
    }
  }

  void _onData(List<int> bytes) {
    _parser.process(bytes);
    if (!_screenController.isClosed) {
      _screenController.add(_parser.state);
    }
  }

  void sendInput(String text) {
    _process?.stdin.add(utf8.encode(text));
  }

  void dispose() {
    _process?.kill();
    if (!_screenController.isClosed) {
      _screenController.close();
    }
  }
}

// ── TerminalController ───────────────────────────────────────────────────────

class TerminalController extends ChangeNotifier {
  final String? workingDirectory;
  final int cols;
  final int rows;

  late final TerminalSession _session;
  StreamSubscription<TerminalScreenState>? _subscription;

  // Starts as the empty grid — never null — so the view renders immediately.
  TerminalScreenState _state;

  TerminalScreenState get state => _state;

  TerminalController({this.workingDirectory, this.cols = 80, this.rows = 24})
      : _state = TerminalScreenState(
          grid: List.generate(
            24,
            (_) => List.generate(80, (_) => const TerminalCell()),
          ),
          cursorRow: 0,
          cursorCol: 0,
        ) {
    _session = TerminalSession(
      cols: cols,
      rows: rows,
      workingDirectory: workingDirectory,
    );
    // Immediately read the (empty) initial state from the session.
    _state = _session.currentState;
    _subscription = _session.screenUpdates.listen((s) {
      _state = s;
      notifyListeners();
    });
  }

  void sendInput(String input) => _session.sendInput(input);

  @override
  void dispose() {
    _subscription?.cancel();
    _session.dispose();
    super.dispose();
  }
}

// ── TerminalTab Model ─────────────────────────────────────────────────────────

class TerminalTab {
  final String id;
  final String shellName;
  final String? workingDirectory;
  final TerminalController controller;

  TerminalTab({
    required this.id,
    required this.shellName,
    this.workingDirectory,
  }) : controller = TerminalController(workingDirectory: workingDirectory);

  String get label {
    if (workingDirectory == null) return shellName;
    final dir = workingDirectory!;
    final parts = dir.split(Platform.pathSeparator);
    final baseName = parts.where((p) => p.isNotEmpty).lastOrNull;
    if (baseName == null || baseName.isEmpty) return shellName;
    return '$shellName ($baseName)';
  }

  void dispose() => controller.dispose();
}

// ── TerminalTabsController ────────────────────────────────────────────────────

class TerminalTabsController extends ChangeNotifier {
  final List<TerminalTab> _tabs = [];
  int _activeIndex = 0;

  List<TerminalTab> get tabs => List.unmodifiable(_tabs);
  TerminalTab? get activeTab =>
      _tabs.isEmpty ? null : _tabs[_activeIndex.clamp(0, _tabs.length - 1)];
  int get activeIndex => _activeIndex;

  TerminalTabsController({String? initialDirectory}) {
    addTab(workingDirectory: initialDirectory);
  }

  void addTab({String? workingDirectory}) {
    final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
    final shellName = shell.split('/').last;
    final tab = TerminalTab(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      shellName: shellName,
      workingDirectory: workingDirectory,
    );
    _tabs.add(tab);
    _activeIndex = _tabs.length - 1;
    notifyListeners();
  }

  void removeTab(int index) {
    if (_tabs.isEmpty || index < 0 || index >= _tabs.length) return;
    _tabs[index].dispose();
    _tabs.removeAt(index);
    if (_tabs.isEmpty) {
      addTab();
    } else {
      _activeIndex = _activeIndex.clamp(0, _tabs.length - 1);
      notifyListeners();
    }
  }

  void switchTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
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

// ── TerminalView ──────────────────────────────────────────────────────────────

class TerminalView extends StatefulWidget {
  final TerminalController controller;

  const TerminalView({super.key, required this.controller});

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final FocusNode _focusNode = FocusNode();

  static const double _charW = 8.4;
  static const double _charH = 16.0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final key = event.logicalKey;
    String? input;

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

    if (input != null) {
      widget.controller.sendInput(input);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Theme-aware background: very dark surface in dark mode, slightly off-white in light
    final termBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        _onKey(event);
        return KeyEventResult.handled;
      },
      child: GestureDetector(
        onTap: _focusNode.requestFocus,
        child: Container(
          color: termBg,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              return ListenableBuilder(
                listenable: _focusNode,
                builder: (context, _) {
                  final state = widget.controller.state;
                  return CustomPaint(
                    painter: _TerminalPainter(
                      state: state,
                      hasFocus: _focusNode.hasFocus,
                      charW: _charW,
                      charH: _charH,
                      isDark: isDark,
                    ),
                    size: Size(
                      widget.controller.cols * _charW,
                      widget.controller.rows * _charH,
                    ),
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

// ── TerminalPainter ───────────────────────────────────────────────────────────

class _TerminalPainter extends CustomPainter {
  final TerminalScreenState state;
  final bool hasFocus;
  final bool isDark;
  final double charW;
  final double charH;

  _TerminalPainter({
    required this.state,
    required this.hasFocus,
    required this.charW,
    required this.charH,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..style = PaintingStyle.fill;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    // Default text color adapts to theme
    final defaultFg =
        isDark ? const Color(0xFFCCCCCC) : const Color(0xFF1A1A1A);
    final cursorColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final cursorTextColor = isDark ? Colors.black : Colors.white;

    for (int r = 0; r < state.grid.length; r++) {
      final row = state.grid[r];
      for (int c = 0; c < row.length; c++) {
        final cell = row[c];
        final x = c * charW;
        final y = r * charH;

        // Background
        Color? bg = cell.bgColor;
        final isCursor = r == state.cursorRow && c == state.cursorCol;
        if (isCursor) {
          bg = hasFocus
              ? cursorColor
              : cursorColor.withValues(alpha: 0.5);
        }
        if (bg != null) {
          bgPaint.color = bg;
          canvas.drawRect(Rect.fromLTWH(x, y, charW, charH), bgPaint);
        }

        // Foreground
        final ch = cell.char;
        if (ch.isNotEmpty && ch != ' ') {
          Color fg = cell.fgColor ?? defaultFg;
          if (isCursor) {
            fg = cursorTextColor;
          }

          tp.text = TextSpan(
            text: ch,
            style: TextStyle(
              color: fg,
              fontSize: 13.0,
              fontFamily: 'monospace',
              fontWeight: cell.bold ? FontWeight.bold : FontWeight.normal,
              height: 1.0,
            ),
          );
          tp.layout();
          tp.paint(canvas, Offset(x, y + 1));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TerminalPainter old) =>
      old.state != state || old.hasFocus != hasFocus || old.isDark != isDark;
}

// ── TerminalPanel (Multi-tab Shell) ──────────────────────────────────────────

class TerminalPanel extends StatefulWidget {
  final String? workingDirectory;

  const TerminalPanel({super.key, this.workingDirectory});

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  late final TerminalTabsController _tabsController;

  @override
  void initState() {
    super.initState();
    _tabsController =
        TerminalTabsController(initialDirectory: widget.workingDirectory);
  }

  @override
  void dispose() {
    _tabsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware terminal chrome colors
    final tabBarBg = isDark
        ? colorScheme.surfaceContainerLow
        : colorScheme.surfaceContainerLow;

    return ListenableBuilder(
      listenable: _tabsController,
      builder: (context, _) {
        final tabs = _tabsController.tabs;
        final activeIndex = _tabsController.activeIndex;
        final activeTab = _tabsController.activeTab;

        return Column(
          children: [
            // ── Tab bar ────────────────────────────────────────────
            Container(
              height: 33,
              decoration: BoxDecoration(
                color: tabBarBg,
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
                  // Panel label
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
                      itemBuilder: (context, i) => _TerminalTabChip(
                        label: tabs[i].label,
                        isActive: i == activeIndex,
                        onTap: () => _tabsController.switchTab(i),
                        onClose: tabs.length > 1
                            ? () => _tabsController.removeTab(i)
                            : null,
                      ),
                    ),
                  ),
                  // Add tab
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
                ],
              ),
            ),

            // ── Terminal content ──────────────────────────────────
            Expanded(
              child: activeTab == null
                  ? const SizedBox.shrink()
                  : IndexedStack(
                      index: activeIndex,
                      children: tabs
                          .map((tab) =>
                              TerminalView(controller: tab.controller))
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Tab chip widget ───────────────────────────────────────────────────────────

class _TerminalTabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  const _TerminalTabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 33,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.surface
                : Colors.transparent,
            border: Border(
              top: BorderSide(
                color: isActive
                    ? colorScheme.primary
                    : Colors.transparent,
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
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (onClose != null) ...[
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
