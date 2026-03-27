import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/editor/views/editor_page.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class GooxDesktop extends StatefulWidget {
  const GooxDesktop({super.key});

  @override
  State<GooxDesktop> createState() => _GooxDesktopState();
}

class _GooxDesktopState extends State<GooxDesktop> {
  bool _showStartupSplash = true;
  Timer? _startupTimer;

  @override
  void initState() {
    super.initState();
    _startupTimer = Timer(const Duration(milliseconds: 850), () {
      if (mounted) {
        setState(() {
          _showStartupSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'Goox Editor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: state.themeMode,
      home: _showStartupSplash
          ? const _DesktopStartupSplash()
          : const EditorPage(),
    );
  }
}

class _DesktopStartupSplash extends StatelessWidget {
  const _DesktopStartupSplash();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF2C6A84),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 164,
              height: 164,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'launch_assets/goox_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Goox Desktop',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparing your workspace...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
