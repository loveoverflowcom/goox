import 'package:flutter/material.dart';
import 'package:goox_terminal/goox_terminal.dart';
import 'package:goox_terminal/src/goox_terminal_session_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goox Terminal Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GooxTerminalController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goox Terminal Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _controller?.write('echo "Hello from Goox Terminal!"\n');
            },
            tooltip: 'Send test command',
          ),
        ],
      ),
      // Test with direct session view instead of wrapper
      body: const GooxTerminalSessionView(),
    );
  }
}
