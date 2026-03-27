import 'package:flutter_test/flutter_test.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';

void main() {
  test('exports an empty editor state', () {
    final state = EditorViewState.empty();

    expect(state.totalLines, 1);
    expect(state.documentText, isEmpty);
    expect(state.cursor.line, 1);
    expect(state.cursor.column, 1);
  });
}
