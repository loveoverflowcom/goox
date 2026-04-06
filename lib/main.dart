import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/editor_content/data.dart';
import 'package:goox/features/editor_layout/presentation.dart';
import 'package:goox/features/file_explorer/data.dart';
import 'package:goox/features/terminal.dart' show TerminalRepository, TerminalRepositoryImpl;
import 'package:goox/features/theme.dart';
import 'package:native_splash_screen/native_splash_screen.dart' as nss;

void main() async {
  runApp(const App());
}

/// Main application widget.
final class App extends StatefulWidget {
  /// Creates the main app.
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

final class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    // Close splash screen after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await nss.close(animation: nss.CloseAnimation.fade);
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
          RepositoryProvider<TerminalRepository>(
            create: (context) => TerminalRepositoryImpl(),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          buildWhen: (previous, current) =>
              previous.themeMode != current.themeMode,
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
