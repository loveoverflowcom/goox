import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goox_terminal/goox_terminal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TerminalManagerApp());
}

/// Example app that manages multiple terminal sessions.
class TerminalManagerApp extends StatefulWidget {
  /// Creates the example app.
  const TerminalManagerApp({
    super.key,
    this.manager,
    this.initialize = initializeGooxTerminal,
    this.disposeTerminal = disposeGooxTerminal,
  });

  /// Optional manager override for tests.
  final PtyManager? manager;

  /// Initialization hook used by the production app.
  final Future<void> Function() initialize;

  /// Disposal hook used by the production app.
  final Future<void> Function() disposeTerminal;

  @override
  State<TerminalManagerApp> createState() => _TerminalManagerAppState();
}

class _TerminalManagerAppState extends State<TerminalManagerApp> {
  late final PtyManager _manager = widget.manager ?? PtyManager.instance;
  late Future<void> _bootstrapFuture;

  final List<PtySession> _sessions = <PtySession>[];

  bool _creatingSession = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = widget.initialize();
  }

  @override
  void dispose() {
    unawaited(_shutdown());
    super.dispose();
  }

  Future<void> _shutdown() async {
    try {
      await _manager.closeAllSessions();
    } catch (_) {
      // Best-effort cleanup while the widget tree is going away.
    }
    try {
      await widget.disposeTerminal();
    } catch (_) {
      // Same here: shutdown should not crash the example app on exit.
    }
  }

  void _retryInitialization() {
    setState(() {
      _statusMessage = null;
      _bootstrapFuture = widget.initialize();
    });
  }

  Future<void> _createSession() async {
    if (_creatingSession) {
      return;
    }

    setState(() {
      _creatingSession = true;
      _statusMessage = null;
    });

    try {
      final session = await _manager.createSessionHandle(
        PtyConfig.defaultShell(size: const PtySize(rows: 24, cols: 80)),
      );

      if (!mounted) {
        await session.close();
        return;
      }

      setState(() {
        _sessions.insert(0, session);
        _statusMessage = 'Created terminal ${_shortId(session.id)}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Failed to create terminal: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _creatingSession = false;
        });
      }
    }
  }

  Future<void> _closeSession(PtySession session) async {
    if (mounted) {
      setState(() {
        _sessions.remove(session);
      });
    }

    try {
      await session.close();
    } catch (error) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to close ${_shortId(session.id)}: $error';
        });
      }
    }
  }

  Future<void> _closeAllSessions() async {
    if (mounted) {
      setState(() {
        _sessions.clear();
      });
    }

    if (!mounted) {
      return;
    }

    try {
      await _manager.closeAllSessions();
    } catch (error) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to close all sessions: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00B4D8),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF08111D),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF08111D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: FutureBuilder<void>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _BootstrapView(
              title: 'Goox Terminal',
              message: 'Initializing Rust PTY bridge',
              details:
                  'flutter_rust_bridge connects Dart to the Rust PTY backend before the first session is created.',
              actionLabel: 'Retry',
              onAction: _retryInitialization,
            );
          }

          if (snapshot.hasError) {
            return _BootstrapView(
              title: 'Goox Terminal',
              message: 'Terminal backend failed to initialize',
              details: snapshot.error.toString(),
              actionLabel: 'Retry',
              onAction: _retryInitialization,
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Goox Terminal'),
              actions: [
                TextButton.icon(
                  onPressed: _creatingSession ? null : _createSession,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.add),
                  label: const Text('New terminal'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _sessions.isEmpty ? null : _closeAllSessions,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.close),
                  label: const Text('Close all'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF08111D),
                    Color(0xFF0D1B2A),
                    Color(0xFF132238),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Manage multiple terminal sessions from a single Flutter screen.',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Chip(
                            label: Text(
                              '${_sessions.length} open',
                              style: const TextStyle(color: Colors.white),
                            ),
                            side: BorderSide(color: _alpha(Colors.white, 0.12)),
                            backgroundColor: _alpha(
                              const Color(0xFF10263D),
                              0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_statusMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _StatusBanner(message: _statusMessage!),
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _sessions.isEmpty
                          ? _EmptyState(
                              isCreating: _creatingSession,
                              onCreate: _createSession,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: _sessions.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final session = _sessions[index];
                                return TerminalSessionCard(
                                  key: ValueKey(session.id),
                                  session: session,
                                  onClose: _closeSession,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TerminalSessionCard extends StatefulWidget {
  const TerminalSessionCard({
    super.key,
    required this.session,
    required this.onClose,
  });

  final PtySession session;
  final Future<void> Function(PtySession session) onClose;

  @override
  State<TerminalSessionCard> createState() => _TerminalSessionCardState();
}

class _TerminalSessionCardState extends State<TerminalSessionCard> {
  final TextEditingController _inputController = TextEditingController(
    text: 'echo "hello from Goox Terminal"',
  );

  bool _showOutput = true;
  bool _busy = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final command = text.endsWith('\n') ? text : '$text\n';
      await widget.session.write(command);
      if (!mounted) {
        return;
      }
      _inputController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send input: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _resize(PtySize size) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await widget.session.resize(size.rows, size.cols);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resize session: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final session = widget.session;
        final info = session.info;

        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: _alpha(const Color(0xFF0F1B2D), 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _alpha(Colors.white, 0.08)),
              boxShadow: [
                BoxShadow(
                  color: _alpha(Colors.black, 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _shortId(session.id),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${info.shell}  •  ${info.size.cols} x ${info.size.rows}  •  ${info.attached ? 'attached' : 'detached'}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatusChip(status: info.status),
                      IconButton(
                        tooltip: _showOutput ? 'Hide output' : 'Show output',
                        onPressed: () {
                          setState(() {
                            _showOutput = !_showOutput;
                          });
                        },
                        icon: Icon(
                          _showOutput
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        color: Colors.white,
                      ),
                      IconButton(
                        tooltip: 'Close terminal',
                        onPressed: _busy
                            ? null
                            : () => widget.onClose(widget.session),
                        icon: const Icon(Icons.close),
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        label: 'PID',
                        value: info.pid?.toString() ?? 'pending',
                      ),
                      _InfoChip(
                        label: 'Attached',
                        value: info.attached ? 'yes' : 'no',
                      ),
                      _InfoChip(label: 'Status', value: info.status.name),
                    ],
                  ),
                  if (_showOutput) ...[
                    const SizedBox(height: 14),
                    _TerminalOutputPanel(transcript: session.transcript),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () =>
                                    _resize(const PtySize(rows: 24, cols: 80)),
                          icon: const Icon(Icons.crop_16_9),
                          label: const Text('80 x 24'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () =>
                                    _resize(const PtySize(rows: 40, cols: 120)),
                          icon: const Icon(Icons.aspect_ratio),
                          label: const Text('120 x 40'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          enabled: !_busy,
                          onSubmitted: (_) => _send(),
                          textInputAction: TextInputAction.send,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type a shell command and press Send',
                            hintStyle: TextStyle(
                              color: _alpha(Colors.white, 0.45),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF06111F),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _alpha(Colors.white, 0.08),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _alpha(Colors.white, 0.08),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF00B4D8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _busy ? null : _send,
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: const Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BootstrapView extends StatelessWidget {
  const _BootstrapView({
    required this.title,
    required this.message,
    required this.details,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String details;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF08111D), Color(0xFF0D1B2A), Color(0xFF132238)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _alpha(const Color(0xFF0F1B2D), 0.96),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _alpha(Colors.white, 0.08)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          details,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white60),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: onAction,
                          icon: const Icon(Icons.refresh),
                          label: Text(actionLabel),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isCreating, required this.onCreate});

  final bool isCreating;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _alpha(const Color(0xFF0F1B2D), 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _alpha(Colors.white, 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.terminal,
                    size: 56,
                    color: Color(0xFF00B4D8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sessions yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a terminal to spawn the Rust PTY backend and start sending commands.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: isCreating ? null : onCreate,
                    icon: isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Create terminal'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _alpha(const Color(0xFF15324B), 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _alpha(const Color(0xFF00B4D8), 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF8FD3F4)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TerminalStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(status);
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      backgroundColor: colors.background,
      side: BorderSide(color: _alpha(colors.foreground, 0.3)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: const Color(0xFF06111F),
      side: BorderSide(color: _alpha(Colors.white, 0.08)),
      label: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _TerminalOutputPanel extends StatelessWidget {
  const _TerminalOutputPanel({required this.transcript});

  final String transcript;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140, maxHeight: 260),
      decoration: BoxDecoration(
        color: const Color(0xFF06111F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _alpha(Colors.white, 0.08)),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            transcript.isEmpty ? 'No output yet.' : transcript,
            style: const TextStyle(
              color: Color(0xFFD7E8FF),
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

Color _brightnessAdjusted(Color color, double opacity) {
  return color.withValues(alpha: opacity);
}

Color _alpha(Color color, double opacity) {
  return color.withValues(alpha: opacity);
}

({Color background, Color foreground}) _statusColors(TerminalStatus status) {
  switch (status) {
    case TerminalStatus.starting:
      return (
        background: _brightnessAdjusted(const Color(0xFF10263D), 0.9),
        foreground: const Color(0xFF8FD3F4),
      );
    case TerminalStatus.running:
      return (
        background: _brightnessAdjusted(const Color(0xFF173A2F), 0.9),
        foreground: const Color(0xFF87E8A8),
      );
    case TerminalStatus.exited:
      return (
        background: _brightnessAdjusted(const Color(0xFF3A2A10), 0.9),
        foreground: const Color(0xFFF4D58D),
      );
    case TerminalStatus.closed:
      return (
        background: _brightnessAdjusted(const Color(0xFF2E2F35), 0.9),
        foreground: const Color(0xFFB7C0D8),
      );
    case TerminalStatus.failed:
      return (
        background: _brightnessAdjusted(const Color(0xFF4A1F27), 0.9),
        foreground: const Color(0xFFFF8FA3),
      );
  }
}

String _shortId(String id) {
  if (id.length <= 8) {
    return id;
  }
  return id.substring(0, 8);
}
