import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/editor_content/data.dart';
import 'package:goox/features/editor_layout/presentation.dart';
import 'package:goox/features/file_explorer/data.dart';
import 'package:goox_ui/goox_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Delay to show native splash screen
  await Future<void>.delayed(const Duration(milliseconds: 1500));
  
  runApp(const MyApp());
}

/// Main application widget.
final class MyApp extends StatelessWidget {
  /// Creates the main app.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<WorkspaceRepository>(
          create: (context) => WorkspaceRepositoryImpl(),
        ),
        RepositoryProvider<FileRepository>(
          create: (context) => FileRepositoryImpl(),
        ),
      ],
      child: MaterialApp(
        title: 'Goox Editor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const EditorLayoutView(
          workspacePath: '', // Empty path - user will open folder via UI
        ),
      ),
    );
  }
}
