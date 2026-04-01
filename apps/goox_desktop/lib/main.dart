import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';
import 'package:provider/provider.dart';

import 'src/app/app.dart';
import 'src/state/app_state.dart';
import 'src/state/persistence.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final persistenceService = PersistenceService();
  await persistenceService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(persistenceService)),
      ],
      child: const GooxDesktop(),
    ),
  );

  unawaited(
    GooxEditorSdkBootstrap.ensureInitialized().catchError((error, stackTrace) {
      debugPrint('Failed to initialize Goox core: $error');
    }),
  );
}
