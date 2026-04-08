/// Terminal XTerm - Pure Dart terminal emulator for Flutter
///
/// This library provides a complete terminal solution using xterm (terminal emulator)
/// and flutter_pty (PTY backend). It consolidates all terminal functionality into
/// a self-contained, reusable package.
///
/// ## Features
///
/// - Pure Dart implementation (no Rust FFI)
/// - Multiple terminal sessions with tab management
/// - Full xterm terminal emulation with ANSI color support
/// - Cross-platform PTY support (Linux, macOS, Windows)
/// - Customizable themes (dark/light)
/// - Automatic shell detection
/// - Session lifecycle management
/// - Keyboard shortcuts and input handling
///
/// ## Usage
///
/// ### Basic Usage - Terminal Panel
///
/// ```dart
/// import 'package:goox_terminal/goox_terminal.dart';
///
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         body: Column(
///           children: [
///             Expanded(child: EditorArea()),
///             TerminalPanel(
///               initialHeight: 300,
///               visible: true,
///               theme: TerminalTheme.dark(),
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
/// ### Manual Session Management
///
/// ```dart
/// final sessionManager = TerminalSessionManager.instance;
///
/// // Create a new terminal session
/// final controller = await sessionManager.createSession(
///   shellConfig: ShellConfig.bash(),
///   initialSize: PtySize.defaultSize,
/// );
///
/// // Write to terminal
/// await controller.write('echo "Hello World"\n');
///
/// // Listen to status changes
/// controller.statusStream.listen((status) {
///   print('Terminal status: $status');
/// });
///
/// // Resize terminal
/// await controller.resize(30, 100);
///
/// // Close session
/// await sessionManager.closeSession(controller.id);
/// ```
///
/// ### Shell Detection
///
/// ```dart
/// // Detect default shell for current platform
/// final defaultShell = await ShellDetector.detectDefaultShell();
/// print('Default shell: ${defaultShell.shellPath}');
///
/// // Find all available shells
/// final availableShells = await ShellDetector.detectAvailableShells();
/// for (final shell in availableShells) {
///   print('Available: ${shell.shellPath}');
/// }
/// ```
///
/// ### Custom Shell Configuration
///
/// ```dart
/// // Use factory methods
/// final bashConfig = ShellConfig.bash();
/// final zshConfig = ShellConfig.zsh();
/// final fishConfig = ShellConfig.fish();
/// final powershellConfig = ShellConfig.powershell();
/// final cmdConfig = ShellConfig.cmd();
///
/// // Custom configuration
/// final customConfig = ShellConfig(
///   shellPath: '/bin/zsh',
///   arguments: ['-l'],
///   environment: {'TERM': 'xterm-256color'},
///   workingDirectory: '/home/user/projects',
/// );
/// ```
///
/// ### Custom Themes
///
/// ```dart
/// // Use built-in themes
/// final darkTheme = TerminalTheme.dark();
/// final lightTheme = TerminalTheme.light();
///
/// // Customize theme
/// final customTheme = TerminalTheme.dark().copyWith(
///   background: Color(0xFF1A1A1A),
///   foreground: Color(0xFFE0E0E0),
/// );
/// ```
library goox_terminal;

// Main UI Component
export 'src/ui/terminal_panel.dart' show TerminalPanel;

// Session Management
export 'src/controllers/terminal_session_manager.dart'
    show TerminalSessionManager;

// Terminal Controller
export 'src/controllers/terminal_controller.dart' show TerminalController;

// Models
export 'src/models/terminal_status.dart' show TerminalStatus, TerminalStatusX;
export 'src/models/shell_config.dart' show ShellConfig;
export 'src/models/pty_size.dart' show PtySize;
export 'src/ui/terminal_theme.dart' show TerminalTheme;

// Services
export 'src/services/shell_detector.dart' show ShellDetector;

// Exceptions
export 'src/exceptions/pty_exception.dart' show ProcessSpawnException;
