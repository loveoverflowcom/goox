import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goox/features/editor_content/data.dart';
import 'package:goox/features/editor_content/presentation.dart';
import 'package:goox_ui/goox_ui.dart';
import 'package:mocktail/mocktail.dart';

final class MockFileRepository extends Mock implements FileRepository {}

void main() {
  late MockFileRepository repository;
  late EditorContentBloc bloc;

  setUp(() {
    repository = MockFileRepository();
    bloc = EditorContentBloc(repository: repository);
  });

  tearDown(() async {
    await bloc.close();
  });

  Widget buildEditor() {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: [EditorThemeExtension.dark()],
      ),
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 320,
          child: BlocProvider.value(
            value: bloc,
            child: const TextEditorWidget(),
          ),
        ),
      ),
    );
  }

  testWidgets('renders long line lists without overflow', (tester) async {
    final content = List.generate(
      120,
      (index) => 'Line ${index + 1}',
    ).join('\n');
    final fileContent = FileContent(
      path: '/workspace/large.txt',
      content: content,
      encoding: 'utf-8',
      language: 'text',
      lastModified: DateTime(2026),
    );

    await tester.pumpWidget(buildEditor());
    bloc.emit(
      EditorContentState(
        fileContent: fileContent,
        originalContent: content,
        status: EditorContentStatus.loaded,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('moves the cursor to the last line on blank-space tap', (
    tester,
  ) async {
    final lines = List.generate(10, (index) => 'Line ${index + 1}');
    final content = lines.join('\n');
    final fileContent = FileContent(
      path: '/workspace/small.txt',
      content: content,
      encoding: 'utf-8',
      language: 'text',
      lastModified: DateTime(2026),
    );
    final expectedColumn = lines.last.length + 1;

    await tester.pumpWidget(buildEditor());
    bloc.emit(
      EditorContentState(
        fileContent: fileContent,
        originalContent: content,
        status: EditorContentStatus.loaded,
      ),
    );
    await tester.pump();

    expect(bloc.state.fileContent?.content, content);

    await tester.tapAt(const Offset(220, 250));
    await tester.pump();
    await tester.pump();

    expect(bloc.state.cursorPosition.line, 10);
    expect(bloc.state.cursorPosition.column, expectedColumn);
  });
}
