import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          builder: (context) => GooxTerminalPanel(
            workingDirectory: workingDirectory,
          ),
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

  const TerminalScreenState({
    required this.grid,
    required this.cursorRow,
    required this.cursorCol,
  });
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
      sR = endRow; sC = endCol;
      eR = startRow; eC = startCol;
    }
    if (row < sR || row > eR) return false;
    if (row == sR && row == eR) return col >= sC && col <= eC;
    if (row == sR) return col >= sC;
    if (row == eR) return col <= eC;
    return true;
  }
}

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
    for (var i = 0; i < decoded.length; i++) {
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
        if (_cursorCol > 0) {
          _cursorCol--;
        }
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
    if (_cursorRow >= rows || _cursorCol >= cols) {
      return;
    }
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
    if (seq.isEmpty) {
      return;
    }
    final action = seq[seq.length - 1];
    final paramStr = seq.substring(0, seq.length - 1);
    final cleaned = paramStr.startsWith('?') ? paramStr.substring(1) : paramStr;
    final params = cleaned
        .split(';')
        .map((s) => int.tryParse(s) ?? 0)
        .toList();

    switch (action) {
      case 'H':
      case 'f':
        final row = params.isNotEmpty ? params[0] : 1;
        final col = params.length > 1 ? params[1] : 1;
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
      case 'h':
      case 'l':
        break;
    }
  }

  void _eraseInLine(int mode) {
    switch (mode) {
      case 0:
        for (var c = _cursorCol; c < cols; c++) {
          _grid[_cursorRow][c] = const TerminalCell();
        }
        break;
      case 1:
        for (var c = 0; c <= _cursorCol && c < cols; c++) {
          _grid[_cursorRow][c] = const TerminalCell();
        }
        break;
      case 2:
        for (var c = 0; c < cols; c++) {
          _grid[_cursorRow][c] = const TerminalCell();
        }
        break;
    }
  }

  void _eraseInDisplay(int mode) {
    switch (mode) {
      case 0:
        _eraseInLine(0);
        for (var r = _cursorRow + 1; r < rows; r++) {
          for (var c = 0; c < cols; c++) {
            _grid[r][c] = const TerminalCell();
          }
        }
        break;
      case 1:
        for (var r = 0; r < _cursorRow; r++) {
          for (var c = 0; c < cols; c++) {
            _grid[r][c] = const TerminalCell();
          }
        }
        _eraseInLine(1);
        break;
      case 2:
      case 3:
        for (var r = 0; r < rows; r++) {
          for (var c = 0; c < cols; c++) {
            _grid[r][c] = const TerminalCell();
          }
        }
        break;
    }
  }

  void _applySgr(List<int> params) {
    for (var i = 0; i < params.length; i++) {
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
      Color(0xFF000000),
      Color(0xFFCC0000),
      Color(0xFF00CC00),
      Color(0xFFCCCC00),
      Color(0xFF0000CC),
      Color(0xFFCC00CC),
      Color(0xFF00CCCC),
      Color(0xFFCCCCCC),
    ];
    const brightColors = [
      Color(0xFF666666),
      Color(0xFFFF5555),
      Color(0xFF55FF55),
      Color(0xFFFFFF55),
      Color(0xFF5555FF),
      Color(0xFFFF55FF),
      Color(0xFF55FFFF),
      Color(0xFFFFFFFF),
    ];
    final list = bright ? brightColors : normal;
    return list[idx.clamp(0, 7)];
  }
}

class TerminalSession {
  TerminalSession({
    this.cols = 80,
    this.rows = 24,
    this.workingDirectory,
  }) : _parser = _AnsiParser(cols: cols, rows: rows) {
    _start();
  }

  final int cols;
  final int rows;
  final String? workingDirectory;
  Process? _process;
  final _AnsiParser _parser;
  bool _started = false;
  final _screenController = StreamController<TerminalScreenState>.broadcast();

  Stream<TerminalScreenState> get screenUpdates => _screenController.stream;
  TerminalScreenState get currentState => _parser.state;

  Future<void> _start() async {
    if (_started) {
      return;
    }
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

      if (Platform.isMacOS || Platform.isLinux) {
        _process = await Process.start(
          'script',
          ['-q', '/dev/null', shell, '-i'],
          workingDirectory: workingDirectory,
          environment: env,
          runInShell: false,
        );
      } else {
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
    } catch (error) {
      debugPrint('[Terminal] Failed to start: $error');
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

class TerminalController extends ChangeNotifier {
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
    _state = _session.currentState;
    _subscription = _session.screenUpdates.listen((nextState) {
      _state = nextState;
      notifyListeners();
    });
  }

  final String? workingDirectory;
  final int cols;
  final int rows;
  late final TerminalSession _session;
  StreamSubscription<TerminalScreenState>? _subscription;
  TerminalScreenState _state;
  TerminalSelection? _selection;

  TerminalScreenState get state => _state;
  TerminalSelection? get selection => _selection;

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

  void sendInput(String input) => _session.sendInput(input);

  @override
  void dispose() {
    _subscription?.cancel();
    _session.dispose();
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
    final parts = dir.split(Platform.pathSeparator).where((part) => part.isNotEmpty);
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
          final row = (details.localPosition.dy / _charSize.height).floor().clamp(0, widget.controller.rows - 1);
          final col = (details.localPosition.dx / _charSize.width).floor().clamp(0, widget.controller.cols - 1);
          widget.controller.setSelection(TerminalSelection(
            startRow: row,
            startCol: col,
            endRow: row,
            endCol: col,
          ));
        },
        onPanUpdate: (details) {
          final row = (details.localPosition.dy / _charSize.height).floor().clamp(0, widget.controller.rows - 1);
          final col = (details.localPosition.dx / _charSize.width).floor().clamp(0, widget.controller.cols - 1);
          final current = widget.controller.selection;
          if (current != null) {
            widget.controller.setSelection(TerminalSelection(
              startRow: current.startRow,
              startCol: current.startCol,
              endRow: row,
              endCol: col,
            ));
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
                  return CustomPaint(
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
    final defaultFg =
        isDark ? const Color(0xFFE5E5E5) : const Color(0xFF111111);
    final cursorColor = isDark ? const Color(0xFFE5E5E5) : const Color(0xFF111111);
    final cursorTextColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final selectionBg = isDark ? const Color(0xFF264F78) : const Color(0xFFADD6FF);

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
        
        final isCursor = r == state.cursorRow && c == state.cursorCol;
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
              fontFamilyFallback: const ['Menlo', 'Consolas', 'Courier New', 'monospace'],
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
                          .map((tab) => TerminalView(controller: tab.controller))
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
