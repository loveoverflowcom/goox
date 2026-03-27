import 'package:flutter_test/flutter_test.dart';
import 'package:goox_desktop/src/app/app.dart';
import 'package:goox_desktop/src/state/app_state.dart';
import 'package:goox_editor_sdk/goox_editor_sdk.dart';
import 'package:goox_flutter_bridge/goox_flutter_bridge.dart' as bridge;
import 'package:provider/provider.dart';

void main() {
  testWidgets('renders desktop shell through SDK boundary', (tester) async {
    GooxEditorSdkBootstrap.initMock(api: MockRustLibApi());

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppState())],
        child: const GooxDesktop(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('EXPLORER'), findsWidgets);
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
