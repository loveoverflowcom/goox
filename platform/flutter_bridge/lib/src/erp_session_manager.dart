import 'dart:typed_data';

import 'raw_bridge/api.dart' as bridge_api;

final class ErpException implements Exception {
  const ErpException(this.message);

  final String message;

  @override
  String toString() => 'ErpException: $message';
}

final class ErpSessionManager {
  ErpSessionManager._();

  static final ErpSessionManager instance = ErpSessionManager._();

  Future<int> openSession({
    required String workspaceRoot,
    required String filePath,
  }) => bridge_api.erpOpenSession(
    workspaceRoot: workspaceRoot,
    filePath: filePath,
  );

  Future<int> getPageCount(int sessionId) =>
      bridge_api.erpGetPageCount(sessionId: sessionId);

  Future<Uint8List> renderPage({
    required int sessionId,
    required int pageIndex,
    required int width,
    required int height,
  }) => bridge_api.erpRenderPage(
    sessionId: sessionId,
    pageIndex: pageIndex,
    width: width,
    height: height,
  );

  Future<String> renderPageFrame({
    required int sessionId,
    required int pageIndex,
    required int width,
    required int height,
  }) => bridge_api.erpRenderPageArtifact(
    sessionId: sessionId,
    pageIndex: pageIndex,
    width: width,
    height: height,
  );

  Future<List<String>> drainEvents(int sessionId) =>
      bridge_api.erpDrainEvents(sessionId: sessionId);

  Future<void> closeSession(int sessionId) =>
      bridge_api.erpCloseSession(sessionId: sessionId);

  Future<String?> getMetadata(int sessionId) =>
      bridge_api.erpGetMetadata(sessionId: sessionId);

  Future<Uint8List> readArtifact({
    required int sessionId,
    required int artifactId,
  }) => bridge_api.erpReadArtifact(
    sessionId: sessionId,
    artifactId: BigInt.from(artifactId),
  );
}
