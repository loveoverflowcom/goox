import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:provider/provider.dart';

import 'src/app/app.dart';
import 'src/features/editor/services/rust_core_bridge/frb_generated.dart';
import 'src/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ExternalLibrary? externalLibrary;
  if (Platform.isMacOS) {
    const dylibPath = '/Users/manhblue/Documents/personal/open_source/goox/target/debug/libgoox_core.dylib';
    if (File(dylibPath).existsSync()) {
      externalLibrary = ExternalLibrary.open(dylibPath);
    }
  }

  await RustLib.init(externalLibrary: externalLibrary);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const MyApp(),
    ),
  );
}
