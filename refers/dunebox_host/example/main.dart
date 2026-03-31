import 'package:flutter/material.dart';
import 'package:dunebox_host/dunebox_host.dart';

void main() {
  runApp(const DuneBoxApp());
}

class DuneBoxApp extends StatelessWidget {
  const DuneBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DuneBox Host',
      theme: ThemeData.dark(),
      home: const DuneBoxHostScreen(),
    );
  }
}

class DuneBoxHostScreen extends StatefulWidget {
  const DuneBoxHostScreen({super.key});

  @override
  State<DuneBoxHostScreen> createState() => _DuneBoxHostScreenState();
}

class _DuneBoxHostScreenState extends State<DuneBoxHostScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ObjectRegistry _registry;
  late BinaryDecoder _decoder;
  late WasmBridge _wasmBridge;
  late DuneBoxPainter _painter;
  
  String? _loadError;
  bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    
    // Setup animation controller for 60 FPS
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(days: 365), // Effectively infinite
    )..addListener(() {
      // Trigger repaint on every frame
      setState(() {});
    });
    
    // Initialize components
    _registry = ObjectRegistry();
    _decoder = BinaryDecoder(_registry);
    
    // Note: WasmBridge is a stub - actual Wasm runtime integration needed
    _wasmBridge = WasmBridge();
    
    // Create painter
    _painter = DuneBoxPainter(
      wasmBridge: _wasmBridge,
      decoder: _decoder,
      registry: _registry,
      debugMode: _debugMode,
    );
    
    // Setup callbacks
    _setupWasmBridge();
    
    // Start animation loop
    _animationController.repeat();
  }
  
  void _setupWasmBridge() {
    // Note: This is a demonstration of the architecture
    // In a real implementation, you would:
    // 1. Load a .wasm file
    // 2. Setup host imports
    // 3. Call guest update() each frame
    
    // For now, we'll just show a message that Wasm runtime is needed
    _loadError = 'Wasm runtime not yet integrated.\n\n'
        'This is a stub implementation demonstrating the architecture.\n\n'
        'To complete the integration:\n'
        '1. Integrate with package:wasm or dart:wasm\n'
        '2. Load a Dart guest module compiled to .wasm\n'
        '3. Setup host imports (send_commands, log)\n'
        '4. Call guest update() each frame';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _wasmBridge.dispose();
    _registry.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DuneBox Host - Flutter'),
        actions: [
          IconButton(
            icon: Icon(_debugMode ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () {
              setState(() {
                _debugMode = !_debugMode;
                _painter = DuneBoxPainter(
                  wasmBridge: _wasmBridge,
                  decoder: _decoder,
                  registry: _registry,
                  debugMode: _debugMode,
                );
              });
            },
            tooltip: 'Toggle debug mode',
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 320,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
          child: _loadError != null
              ? _buildErrorView()
              : CustomPaint(
                  painter: _painter,
                  size: const Size(320, 240),
                ),
        ),
      ),
      floatingActionButton: _loadError != null
          ? null
          : FloatingActionButton(
              onPressed: () {
                // Reset state
                _registry.clear();
                setState(() {});
              },
              tooltip: 'Reset',
              child: const Icon(Icons.refresh),
            ),
    );
  }
  
  Widget _buildErrorView() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _loadError!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
