import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:path/path.dart' as path;

import 'raw_bridge/api.dart' as bridge_api;
import 'raw_bridge/extensions.dart' as bridge_types;
import 'raw_bridge/frb_generated.dart';

final class GooxRustBootstrap {
  static bool _initialized = false;

  static Future<void> ensureInitialized({String? workspaceRoot}) async {
    if (_initialized) {
      if (workspaceRoot != null && workspaceRoot.isNotEmpty) {
        await refreshWorkspaceExtensions(workspaceRoot: workspaceRoot);
      }
      return;
    }

    ExternalLibrary? externalLibrary;
    if (!kIsWeb) {
      final dylibPath = await _resolveOrBuildLibraryPath(
        workspaceRoot: workspaceRoot,
        forceRebuild: kDebugMode,
      );
      if (dylibPath != null) {
        externalLibrary = ExternalLibrary.open(dylibPath);
      }
    }

    await RustLib.init(externalLibrary: externalLibrary);
    _initialized = true;

    if (workspaceRoot != null && workspaceRoot.isNotEmpty) {
      await refreshWorkspaceExtensions(workspaceRoot: workspaceRoot);
    }
  }

  static Future<void> refreshWorkspaceExtensions({
    required String workspaceRoot,
  }) async {
    if (!_initialized) {
      await ensureInitialized(workspaceRoot: workspaceRoot);
      return;
    }

    await bridge_api.refreshWorkspaceExtensions(workspaceRoot: workspaceRoot);
  }

  static Future<bool> activateExtensionForFile({
    required String workspaceRoot,
    required String filePath,
  }) async {
    if (!_initialized) {
      await ensureInitialized(workspaceRoot: workspaceRoot);
    }

    return bridge_api.activateExtensionForFile(
      workspaceRoot: workspaceRoot,
      filePath: filePath,
    );
  }

  static Future<bridge_types.ExtensionInfo?> resolveExtensionForFile({
    required String workspaceRoot,
    required String filePath,
  }) async {
    if (!_initialized) {
      await ensureInitialized(workspaceRoot: workspaceRoot);
    }

    return bridge_api.extensionForFile(
      workspaceRoot: workspaceRoot,
      filePath: filePath,
    );
  }

  static Future<String?> validateSourceText({
    required String languageId,
    required String text,
  }) async {
    if (!_initialized) {
      await ensureInitialized();
    }

    return bridge_api.validateSourceText(languageId: languageId, text: text);
  }

  static Future<String?> _resolveOrBuildLibraryPath({
    String? workspaceRoot,
    bool forceRebuild = false,
  }) async {
    final root = workspaceRoot ?? _discoverWorkspaceRoot();
    if (root == null) {
      return null;
    }

    if (!forceRebuild) {
      final resolvedPath = _resolveLibraryPath(workspaceRoot: root);
      if (resolvedPath != null) {
        return resolvedPath;
      }
    }

    final buildResult = await Process.run('cargo', [
      'build',
      '-p',
      'goox_core',
      if (!kDebugMode) '--release',
    ], workingDirectory: root);
    if (buildResult.exitCode != 0) {
      debugPrint('Failed to build goox_core:\n${buildResult.stderr}');
      return null;
    }

    return _resolveLibraryPath(workspaceRoot: root);
  }

  static void initMock({required RustLibApi api}) {
    RustLib.initMock(api: api);
    _initialized = true;
  }

  static String? _resolveLibraryPath({String? workspaceRoot}) {
    final libraryFileName = _libraryFileName();
    if (libraryFileName == null) {
      return null;
    }

    final root = workspaceRoot ?? _discoverWorkspaceRoot();
    final candidateRoots = [
      root,
      Directory.current.absolute.path,
    ].whereType<String>();

    final visited = <String>{};
    for (final candidateRoot in candidateRoots) {
      if (!visited.add(candidateRoot)) {
        continue;
      }

      final candidatePaths = [
        path.join(candidateRoot, 'target', 'debug', libraryFileName),
        path.join(candidateRoot, 'target', 'release', libraryFileName),
        path.join(
          candidateRoot,
          'core',
          'engine',
          'target',
          'debug',
          libraryFileName,
        ),
        path.join(
          candidateRoot,
          'core',
          'engine',
          'target',
          'release',
          libraryFileName,
        ),
      ];

      for (final candidatePath in candidatePaths) {
        if (File(candidatePath).existsSync()) {
          return candidatePath;
        }
      }
    }

    return null;
  }

  static String? _discoverWorkspaceRoot() {
    final seeds = <String>[
      if (Platform.environment['PWD'] != null) Platform.environment['PWD']!,
      Directory.current.absolute.path,
    ];

    for (final seed in seeds) {
      final match = _walkUpForWorkspaceRoot(seed);
      if (match != null) {
        return match;
      }
    }

    return null;
  }

  static String? _walkUpForWorkspaceRoot(String startPath) {
    var current = Directory(startPath).absolute;
    while (true) {
      final hasCargo = File(path.join(current.path, 'Cargo.toml')).existsSync();
      final hasRules = File(
        path.join(current.path, 'flutter_rules.md'),
      ).existsSync();
      if (hasCargo && hasRules) {
        return current.path;
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        return null;
      }

      current = parent;
    }
  }

  static String? _libraryFileName() {
    if (Platform.isMacOS) {
      return 'libgoox_core.dylib';
    }

    if (Platform.isLinux) {
      return 'libgoox_core.so';
    }

    if (Platform.isWindows) {
      return 'goox_core.dll';
    }

    return null;
  }
}

Future<void> ensureGooxRustInitialized({String? workspaceRoot}) =>
    GooxRustBootstrap.ensureInitialized(workspaceRoot: workspaceRoot);
