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

  Future<void> closeSession(int sessionId) =>
      bridge_api.erpCloseSession(sessionId: sessionId);
}
