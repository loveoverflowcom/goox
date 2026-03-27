import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/editor/views/editor_demo_page.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'Goox Editor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: state.themeMode,
      home: const EditorDemoPage(),
    );
  }
}
