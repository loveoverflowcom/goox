import 'package:flutter/material.dart';

import '../features/editor/views/editor_demo_page.dart';
import '../theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goox Editor Architecture Demo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const EditorDemoPage(),
    );
  }
}
