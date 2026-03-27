import 'package:flutter_test/flutter_test.dart';
import 'package:goox_flutter_bridge/goox_flutter_bridge.dart';

void main() {
  test('raw bridge data types remain constructible', () {
    final snapshot = BufferSnapshot(
      revision: BigInt.one,
      lineCount: BigInt.one,
      charCount: BigInt.from(4),
    );

    expect(snapshot.revision, BigInt.one);
    expect(snapshot.charCount, BigInt.from(4));
  });
}
