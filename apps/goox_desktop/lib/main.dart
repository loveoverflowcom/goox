import 'package:flutter/material.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';
import 'package:provider/provider.dart';

import 'src/app/app.dart';
import 'src/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GooxEditorSdkBootstrap.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState())],
      child: const GooxDesktop(),
    ),
  );
}
