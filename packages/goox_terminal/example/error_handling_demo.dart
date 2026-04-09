import 'package:flutter/material.dart';
import 'package:goox_terminal/src/controllers/terminal_controller.dart';
import 'package:goox_terminal/src/controllers/terminal_session_manager.dart';
import 'package:goox_terminal/src/exceptions/pty_exception.dart';
import 'package:goox_terminal/src/models/pty_size.dart';
import 'package:goox_terminal/src/models/shell_config.dart';
import 'package:goox_terminal/src/ui/terminal_panel.dart';
import 'package:goox_terminal/src/ui/terminal_theme.dart';

/// Demo application showing error handling in goox_terminal
///
/// This demonstrates:
/// 1. PtyCreationException when shell path is invalid
/// 2. StateError when writing to non-running terminal
/// 3. ArgumentError when resizing with invalid dimensions
/// 4. Error UI overlay with restart button
void main() {
  runApp(const ErrorHandlingDemoApp());
}

class ErrorHandlingDemoApp extends StatelessWidget {
  const ErrorHandlingDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terminal Error Handling Demo',
      theme: ThemeData.dark(),
      home: const ErrorHandlingDemoScreen(),
    );
  }
}

class ErrorHandlingDemoScreen extends StatefulWidget {
  const ErrorHandlingDemoScreen({super.key});

  @override
  State<ErrorHandlingDemoScreen> createState() =>
      _ErrorHandlingDemoScreenState();
}

class _ErrorHandlingDemoScreenState extends State<ErrorHandlingDemoScreen> {
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
  }

  Future<void> _testInvalidShell() async {
    _addLog('Testing invalid shell path...');
    try {
      final controller = TerminalController(
        id: 'test-invalid-shell',
        shellConfig: const ShellConfig(
          shellPath: '/nonexistent/shell',
          arguments: [],
          environment: {},
        ),
        initialSize: PtySize.defaultSize,
      );

      await controller.initialize();
      _addLog('ERROR: Should have thrown PtyCreationException');
    } on PtyCreationException catch (e) {
      _addLog('SUCCESS: Caught PtyCreationException: ${e.message}');
    } catch (e) {
      _addLog('ERROR: Unexpected exception: $e');
    }
  }

  Future<void> _testWriteToClosedTerminal() async {
    _addLog('Testing write to closed terminal...');
    try {
      final controller = TerminalController(
        id: 'test-write-closed',
        shellConfig: ShellConfig.bash(),
        initialSize: PtySize.defaultSize,
      );

      // Don't initialize - terminal is not running
      await controller.write('test');
      _addLog('ERROR: Should have thrown StateError');
    } on StateError catch (e) {
      _addLog('SUCCESS: Caught StateError: ${e.message}');
    } catch (e) {
      _addLog('ERROR: Unexpected exception: $e');
    }
  }

  Future<void> _testInvalidResize() async {
    _addLog('Testing invalid resize dimensions...');
    try {
      final controller = TerminalController(
        id: 'test-invalid-resize',
        shellConfig: ShellConfig.bash(),
        initialSize: PtySize.defaultSize,
      );

      await controller.initialize();

      // Try to resize with invalid dimensions
      await controller.resize(0, 80);
      _addLog('ERROR: Should have thrown ArgumentError');

      await controller.dispose();
    } on ArgumentError catch (e) {
      _addLog('SUCCESS: Caught ArgumentError: ${e.message}');
    } catch (e) {
      _addLog('ERROR: Unexpected exception: $e');
    }
  }

  Future<void> _testErrorStatusUI() async {
    _addLog('Testing error status UI...');
    _addLog(
        'Create a terminal and kill the process to see error overlay with restart button');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal Error Handling Demo'),
      ),
      body: Column(
        children: [
          // Control panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testInvalidShell,
                  child: const Text('Test Invalid Shell'),
                ),
                ElevatedButton(
                  onPressed: _testWriteToClosedTerminal,
                  child: const Text('Test Write to Closed'),
                ),
                ElevatedButton(
                  onPressed: _testInvalidResize,
                  child: const Text('Test Invalid Resize'),
                ),
                ElevatedButton(
                  onPressed: _testErrorStatusUI,
                  child: const Text('Test Error UI'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  child: const Text('Clear Logs'),
                ),
              ],
            ),
          ),

          // Log display
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  final isSuccess = log.contains('SUCCESS');
                  final isError = log.contains('ERROR');

                  return Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isSuccess
                          ? Colors.green
                          : isError
                              ? Colors.red
                              : Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),

          // Terminal panel
          Expanded(
            flex: 1,
            child: TerminalPanel(
              sessionManager: TerminalSessionManager.instance,
              theme: TerminalTheme.dark(),
              visible: true,
            ),
          ),
        ],
      ),
    );
  }
}
