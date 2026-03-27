import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:path/path.dart' as path;

import 'raw_bridge/frb_generated.dart';

final class GooxRustBootstrap {
  static bool _initialized = false;

  static Future<void> ensureInitialized({String? workspaceRoot}) async {
    if (_initialized) {
      return;
    }

    ExternalLibrary? externalLibrary;
    if (!kIsWeb) {
      final dylibPath = await _resolveOrBuildLibraryPath(
        workspaceRoot: workspaceRoot,
      );
      if (dylibPath != null) {
        externalLibrary = ExternalLibrary.open(dylibPath);
      }
    }

    await RustLib.init(externalLibrary: externalLibrary);
    _initialized = true;
  }

  static Future<String?> _resolveOrBuildLibraryPath({
    String? workspaceRoot,
  }) async {
    final resolvedPath = _resolveLibraryPath(workspaceRoot: workspaceRoot);
    if (resolvedPath != null) {
      return resolvedPath;
    }

    final root = workspaceRoot ?? _discoverWorkspaceRoot();
    if (root == null) {
      return null;
    }

    final buildResult = await Process.run('cargo', [
      'build',
      '-p',
      'goox_core',
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
