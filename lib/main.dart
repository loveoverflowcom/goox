import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/editor_content/data.dart';
import 'package:goox/features/editor_layout/presentation.dart';
import 'package:goox/features/file_explorer/data.dart';
import 'package:goox/features/theme.dart';
import 'package:goox_ui/goox_ui.dart';
import 'package:native_splash_screen/native_splash_screen.dart' as nss;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Main application widget.
final class MyApp extends StatefulWidget {
  /// Creates the main app.
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Close splash screen after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nss.close(animation: nss.CloseAnimation.fade);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc(
            repository: ThemeRepositoryImpl(),
          )..add(const LoadThemePreferenceEvent()),
        ),
      ],
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<WorkspaceRepository>(
            create: (context) => WorkspaceRepositoryImpl(),
          ),
          RepositoryProvider<FileRepository>(
            create: (context) => FileRepositoryImpl(),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'Goox Editor',
              debugShowCheckedModeBanner: false,
              theme: themeState.themeData,
              home: const EditorLayoutView(
                workspacePath: '', // Empty path - user will open folder via UI
              ),
            );
          },
        ),
      ),
    );
  }
}
