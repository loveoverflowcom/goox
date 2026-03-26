import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:goox/src/state/app_state.dart';
import 'package:goox/src/app/app.dart';
import 'package:goox/src/features/editor/services/rust_core_bridge/frb_generated.dart';
import 'package:goox/src/features/editor/services/rust_core_bridge/api.dart';
import 'package:goox/src/features/editor/services/rust_core_bridge/lib.dart';

void main() {
  testWidgets('renders architecture demo shell', (WidgetTester tester) async {
    // Initialize mock Rust environment
    RustLib.initMock(api: MockRustLibApi());
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    
    expect(find.text('EXPLORER'), findsWidgets);
  });
}

class MockRustLibApi extends RustLibApi {
  @override
  Future<void> crateApiInitApp() async {}
  @override
  Future<void> crateApiSeedDocument({required String text}) async {}
  @override
  Future<BufferSnapshot> crateApiGetSnapshot() async => 
      BufferSnapshot(revision: BigInt.zero, lineCount: BigInt.one, charCount: BigInt.zero);
  @override
  Future<ViewportSnapshot> crateApiGetViewport({required ViewportRequest request}) async =>
      ViewportSnapshot(revision: BigInt.zero, firstVisibleLine: BigInt.zero, totalLines: BigInt.one, lines: [ViewportLine(lineIndex: BigInt.zero, text: '')]);
  @override
  Future<CursorPos> crateApiGetCursorPosition({required BigInt charIndex}) async =>
      CursorPos(line: BigInt.one, column: BigInt.one);
  @override
  Future<BufferPatchBatch> crateApiApplyTransaction({required BufferTransaction transaction}) async =>
      throw UnimplementedError();
  @override
  Future<BufferPatchBatch> crateApiRedo() async => throw UnimplementedError();
  @override
  Future<BufferPatchBatch> crateApiUndo() async => throw UnimplementedError();
  @override
  Future<BufferPatchBatch> crateApiDeleteLine({required BigInt charIndex}) async =>
      throw UnimplementedError();
}
