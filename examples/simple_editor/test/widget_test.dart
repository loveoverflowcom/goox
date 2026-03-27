import 'package:flutter_test/flutter_test.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';
import 'package:goox_flutter_bridge/goox_flutter_bridge.dart' as bridge;
import 'package:simple_editor/main.dart';

void main() {
  testWidgets('renders simple editor playground', (tester) async {
    GooxEditorSdkBootstrap.initMock(api: MockRustLibApi());

    await tester.pumpWidget(const SimpleEditorApp());
    await tester.pump();

    expect(find.text('Simple Editor Playground'), findsOneWidget);
  });
}

class MockRustLibApi extends bridge.RustLibApi {
  @override
  Future<bridge.BufferPatchBatch> crateApiApplyTransaction({
    required bridge.BufferTransaction transaction,
  }) async => bridge.BufferPatchBatch(
    revision: BigInt.zero,
    label: 'mock',
    patches: const [],
  );

  @override
  Future<bridge.BufferPatchBatch> crateApiDeleteLine({
    required BigInt charIndex,
  }) async => bridge.BufferPatchBatch(
    revision: BigInt.zero,
    label: 'mock',
    patches: const [],
  );

  @override
  Future<bridge.CursorPos> crateApiGetCursorPosition({
    required BigInt charIndex,
  }) async => bridge.CursorPos(line: BigInt.one, column: BigInt.one);

  @override
  Future<bridge.BufferSnapshot> crateApiGetSnapshot() async =>
      bridge.BufferSnapshot(
        revision: BigInt.zero,
        lineCount: BigInt.one,
        charCount: BigInt.zero,
      );

  @override
  Future<bridge.ViewportSnapshot> crateApiGetViewport({
    required bridge.ViewportRequest request,
  }) async => bridge.ViewportSnapshot(
    revision: BigInt.zero,
    firstVisibleLine: BigInt.zero,
    totalLines: BigInt.one,
    lines: [bridge.ViewportLine(lineIndex: BigInt.zero, text: '')],
  );

  @override
  Future<void> crateApiInitApp() async {}

  @override
  Future<bridge.BufferPatchBatch> crateApiRedo() async =>
      bridge.BufferPatchBatch(
        revision: BigInt.zero,
        label: 'mock',
        patches: const [],
      );

  @override
  Future<void> crateApiSeedDocument({required String text}) async {}

  @override
  Future<bridge.BufferPatchBatch> crateApiUndo() async =>
      bridge.BufferPatchBatch(
        revision: BigInt.zero,
        label: 'mock',
        patches: const [],
      );
}
