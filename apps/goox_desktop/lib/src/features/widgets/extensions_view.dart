import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:goox_editor_sdk/goox_editor_sdk.dart';

import '../../state/app_state.dart';

class ExtensionsView extends StatefulWidget {
  const ExtensionsView({super.key});

  @override
  State<ExtensionsView> createState() => ExtensionsViewState();
}

class ExtensionsViewState extends State<ExtensionsView> {
  List<_ManagedExtension> _extensions = const [];
  bool _loadingExtensions = true;
  String? _statusMessage;
  String? _lastWorkspaceRoot = '__init__';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final workspaceRoot = context.watch<AppState>().rootPath;
    if (workspaceRoot != _lastWorkspaceRoot) {
      _lastWorkspaceRoot = workspaceRoot;
      unawaited(reloadExtensions());
    }
  }

  Future<void> reloadExtensions() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingExtensions = true;
      _statusMessage = null;
    });

    try {
      final workspaceRoot = context.read<AppState>().rootPath;
      final extensions = await _scanExtensions(workspaceRoot);
      if (!mounted) {
        return;
      }
      setState(() {
        _extensions = extensions;
        _loadingExtensions = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _extensions = const [];
        _loadingExtensions = false;
        _statusMessage = 'Failed to load extensions: $error';
      });
    }
  }

  Future<void> importExtension() async {
    final workspaceRoot = context.read<AppState>().rootPath;
    if (workspaceRoot == null || workspaceRoot.trim().isEmpty) {
      setState(() {
        _statusMessage = 'Open a workspace before importing an extension.';
      });
      return;
    }

    final sourcePath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Import Extension',
    );
    if (sourcePath == null) {
      return;
    }

    try {
      final validated = await _validateExtensionDirectory(Directory(sourcePath));
      final targetRoot = Directory(p.join(workspaceRoot, '.goox', 'extensions'));
      await targetRoot.create(recursive: true);
      final targetDir = Directory(p.join(targetRoot.path, validated.name));
      if (targetDir.existsSync()) {
        throw FileSystemException('Extension already exists', targetDir.path);
      }

      await _copyDirectory(Directory(sourcePath), targetDir);
      final disabledMarker = File(p.join(targetDir.path, '.goox.disabled'));
      if (disabledMarker.existsSync()) {
        await disabledMarker.delete();
      }

      await GooxEditorSdkBootstrap.refreshWorkspaceExtensions(
        workspaceRoot: workspaceRoot,
      );
      await reloadExtensions();
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Imported ${validated.name}.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Import failed: $error';
      });
    }
  }

  Future<void> _toggleExtension(
    _ManagedExtension extension,
    bool enabled,
  ) async {
    final marker = File(p.join(extension.path, '.goox.disabled'));
    final workspaceRoot = context.read<AppState>().rootPath;
    try {
      if (enabled) {
        if (marker.existsSync()) {
          await marker.delete();
        }
      } else {
        await marker.writeAsString('disabled');
      }

      if (workspaceRoot != null && workspaceRoot.trim().isNotEmpty) {
        await GooxEditorSdkBootstrap.refreshWorkspaceExtensions(
          workspaceRoot: workspaceRoot,
        );
      }
      await reloadExtensions();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Failed to update ${extension.name}: $error';
      });
    }
  }

  Future<List<_ManagedExtension>> _scanExtensions(String? workspaceRoot) async {
    final globalExtensionsDirectory = _globalExtensionsDirectory();
    final roots = <_ExtensionRoot>[
      if (workspaceRoot != null && workspaceRoot.trim().isNotEmpty)
        _ExtensionRoot(
          scope: 'workspace',
          directory: Directory(p.join(workspaceRoot, '.goox', 'extensions')),
        ),
      if (globalExtensionsDirectory != null)
        _ExtensionRoot(scope: 'global', directory: globalExtensionsDirectory),
    ];

    final extensions = <_ManagedExtension>[];
    for (final root in roots) {
      if (!root.directory.existsSync()) {
        continue;
      }

      for (final entry in root.directory.listSync()) {
        if (entry is! Directory) {
          continue;
        }

        final config = await _readExtensionConfig(entry);
        if (config == null) {
          continue;
        }

        extensions.add(
          config.copyWith(
            scope: root.scope,
            enabled: !File(p.join(entry.path, '.goox.disabled')).existsSync(),
          ),
        );
      }
    }

    extensions.sort((left, right) {
      final scopeCompare = left.scope.compareTo(right.scope);
      if (scopeCompare != 0) {
        return scopeCompare;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

    return extensions;
  }

  Future<_ManagedExtension?> _readExtensionConfig(Directory directory) async {
    final configFile = File(p.join(directory.path, 'config.json'));
    if (!configFile.existsSync()) {
      return null;
    }

    final raw = jsonDecode(await configFile.readAsString());
    if (raw is! Map<String, dynamic>) {
      return null;
    }

    final name = _asTrimmedString(raw['name']);
    final filetypes = _asStringList(raw['filetypes']);
    if (name == null || filetypes.isEmpty) {
      return null;
    }

    final entry = _asTrimmedString(raw['entry']);
    final languageId = _asTrimmedString(raw['language_id']);
    final lspExecutable = _asTrimmedString(raw['lsp_executable']);

    return _ManagedExtension(
      name: name,
      path: directory.path,
      scope: '',
      enabled: true,
      entry: entry,
      filetypes: filetypes,
      languageId: languageId,
      lspExecutable: lspExecutable,
    );
  }

  Future<_ManagedExtension> _validateExtensionDirectory(Directory directory) async {
    final config = await _readExtensionConfig(directory);
    if (config == null) {
      throw const FormatException('config.json is missing or invalid');
    }

    if (config.entry != null) {
      final entryPath = File(p.join(directory.path, config.entry!));
      if (!entryPath.existsSync()) {
        throw FileSystemException('Extension entry not found', entryPath.path);
      }
    }

    return config;
  }

  Directory? _globalExtensionsDirectory() {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null || home.trim().isEmpty) {
      return null;
    }

    return Directory(p.join(home, '.goox', 'extensions'));
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    for (final entity in source.listSync(recursive: false, followLinks: false)) {
      final relative = p.basename(entity.path);
      final destination = p.join(target.path, relative);
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destination));
      } else if (entity is File) {
        await File(entity.path).copy(destination);
      }
    }
  }

  String? _asTrimmedString(dynamic value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (_statusMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              _statusMessage!,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (_loadingExtensions)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_extensions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No extension folders found.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ..._extensions.map(
            (extension) => SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              value: extension.enabled,
              onChanged: (value) => unawaited(_toggleExtension(extension, value)),
              title: Text(
                extension.name,
                style: const TextStyle(fontSize: 12),
              ),
              subtitle: Text(
                [
                  extension.scope,
                  extension.enabled ? 'enabled' : 'disabled',
                  extension.filetypes.join(', '),
                  if (extension.languageId != null)
                    'language=${extension.languageId}',
                  if (extension.lspExecutable != null)
                    'lsp=${extension.lspExecutable}',
                ].join(' · '),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExtensionRoot {
  const _ExtensionRoot({required this.scope, required this.directory});

  final String scope;
  final Directory directory;
}

class _ManagedExtension {
  const _ManagedExtension({
    required this.name,
    required this.path,
    required this.scope,
    required this.enabled,
    required this.filetypes,
    this.entry,
    this.languageId,
    this.lspExecutable,
  });

  final String name;
  final String path;
  final String scope;
  final bool enabled;
  final String? entry;
  final List<String> filetypes;
  final String? languageId;
  final String? lspExecutable;

  _ManagedExtension copyWith({
    String? name,
    String? path,
    String? scope,
    bool? enabled,
    String? entry,
    List<String>? filetypes,
    String? languageId,
    String? lspExecutable,
  }) {
    return _ManagedExtension(
      name: name ?? this.name,
      path: path ?? this.path,
      scope: scope ?? this.scope,
      enabled: enabled ?? this.enabled,
      entry: entry ?? this.entry,
      filetypes: filetypes ?? this.filetypes,
      languageId: languageId ?? this.languageId,
      lspExecutable: lspExecutable ?? this.lspExecutable,
    );
  }
}
