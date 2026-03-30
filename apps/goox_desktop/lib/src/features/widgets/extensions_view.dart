import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' show getApplicationSupportDirectory;
import 'package:provider/provider.dart';

import 'package:goox_editor_sdk/goox_editor_sdk.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    if (!mounted) return;

    setState(() {
      _loadingExtensions = true;
      _statusMessage = null;
    });

    try {
      final extensions = await _scanExtensions();
      if (!mounted) return;
      setState(() {
        _extensions = extensions;
        _loadingExtensions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _extensions = const [];
        _loadingExtensions = false;
        _statusMessage = 'Failed to load extensions: $error';
      });
    }
  }

  Future<void> importExtension() async {
    final sourcePath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Import Extension',
    );
    if (sourcePath == null) return;

    try {
      final validated = await _validateExtensionDirectory(Directory(sourcePath));
      final globalDir = await _ensureGlobalExtensionsDirectory();
      final targetDir = Directory(p.join(globalDir.path, validated.name));
      if (targetDir.existsSync()) {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'An extension named "${validated.name}" already exists.';
        });
        return;
      }

      await _copyDirectory(Directory(sourcePath), targetDir);
      final disabledMarker = File(p.join(targetDir.path, '.goox.disabled'));
      if (disabledMarker.existsSync()) {
        await disabledMarker.delete();
      }

      // Capture workspaceRoot before await
      if (!mounted) return;
      final workspaceRoot = context.read<AppState>().rootPath;
      if (workspaceRoot != null && workspaceRoot.trim().isNotEmpty) {
        await GooxEditorSdkBootstrap.refreshWorkspaceExtensions(
          workspaceRoot: workspaceRoot,
        );
      }
      await reloadExtensions();
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Imported ${validated.name}.';
      });
    } catch (error) {
      if (!mounted) return;
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
    // Capture workspaceRoot before any await
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
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Failed to update ${extension.name}: $error';
      });
      await reloadExtensions();
    }
  }

  Future<void> _deleteExtension(_ManagedExtension extension) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Extension'),
        content: Text(
          'Permanently delete "${extension.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Directory(extension.path).delete(recursive: true);
      await reloadExtensions();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Failed to delete ${extension.name}: $error';
      });
    }
  }

  Future<List<_ManagedExtension>> _scanExtensions() async {
    final globalDir = await _ensureGlobalExtensionsDirectory();
    final extensions = <_ManagedExtension>[];

    for (final entry in globalDir.listSync()) {
      if (entry is! Directory) continue;

      final config = await _readExtensionConfig(entry);
      if (config == null) continue;

      extensions.add(
        config.copyWith(
          enabled: !File(p.join(entry.path, '.goox.disabled')).existsSync(),
        ),
      );
    }

    extensions.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return extensions;
  }

  Future<_ManagedExtension?> _readExtensionConfig(Directory directory) async {
    final configFile = File(p.join(directory.path, 'config.json'));
    if (!configFile.existsSync()) return null;

    final raw = jsonDecode(await configFile.readAsString());
    if (raw is! Map<String, dynamic>) return null;

    final name = _asTrimmedString(raw['name']);
    final filetypes = _asStringList(raw['filetypes']);
    if (name == null || filetypes.isEmpty) return null;

    final entry = _asTrimmedString(raw['entry']);
    final languageId = _asTrimmedString(raw['language_id']);
    final lspExecutable = _asTrimmedString(raw['lsp_executable']);
    final logoPath = _resolveLogoPath(directory.path, raw['logo']);

    return _ManagedExtension(
      name: name,
      path: directory.path,
      enabled: true,
      entry: entry,
      filetypes: filetypes,
      languageId: languageId,
      lspExecutable: lspExecutable,
      logoPath: logoPath,
    );
  }

  /// Resolves and validates the logo path from config.
  /// Returns null if absent, invalid, or file doesn't exist.
  String? _resolveLogoPath(String extensionDir, dynamic rawLogo) {
    final logo = _asTrimmedString(rawLogo);
    if (logo == null) return null;

    // Reject absolute paths and path traversal
    if (p.isAbsolute(logo) || logo.contains('..')) return null;

    // Only allow supported extensions
    final ext = p.extension(logo).toLowerCase();
    if (!{'.svg', '.png', '.jpg', '.jpeg'}.contains(ext)) return null;

    final resolved = p.join(extensionDir, logo);
    if (!File(resolved).existsSync()) return null;

    return resolved;
  }

  Future<_ManagedExtension> _validateExtensionDirectory(
    Directory directory,
  ) async {
    final config = await _readExtensionConfig(directory);
    if (config == null) {
      throw const FormatException(
        'config.json is missing or invalid (requires "name" and "filetypes")',
      );
    }

    if (config.entry != null) {
      final entryPath = File(p.join(directory.path, config.entry!));
      if (!entryPath.existsSync()) {
        throw FileSystemException('Extension entry not found', entryPath.path);
      }
    }

    return config;
  }

  /// Returns the global extensions directory, creating it if needed.
  /// Canonical path via getApplicationSupportDirectory():
  ///   macOS:   ~/Library/Application Support/dev.goox.goox/extensions
  ///   Windows: %APPDATA%\dev.goox.goox\extensions
  ///   Linux:   ~/.local/share/dev.goox.goox/extensions
  /// This is the single source of truth — matches Rust's global_extensions_dirs().
  Future<Directory> _ensureGlobalExtensionsDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appSupport.path, 'extensions'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    for (final entity in source.listSync(
      recursive: false,
      followLinks: false,
    )) {
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
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
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
              'No extensions installed.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ..._extensions.map(
            (extension) => _ExtensionTile(
              extension: extension,
              onToggle: (value) =>
                  unawaited(_toggleExtension(extension, value)),
              onDelete: () => unawaited(_deleteExtension(extension)),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Extension tile widget
// ---------------------------------------------------------------------------

class _ExtensionTile extends StatelessWidget {
  const _ExtensionTile({
    required this.extension,
    required this.onToggle,
    required this.onDelete,
  });

  final _ManagedExtension extension;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          _ExtensionLogo(logoPath: extension.logoPath),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extension.name,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  [
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
              ],
            ),
          ),
          Switch(
            value: extension.enabled,
            onChanged: onToggle,
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Delete extension',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo widget — renders image or placeholder
// ---------------------------------------------------------------------------

class _ExtensionLogo extends StatelessWidget {
  const _ExtensionLogo({this.logoPath});

  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (logoPath != null) {
      final ext = p.extension(logoPath!).toLowerCase();
      if (ext == '.svg') {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SvgPicture.file(
            File(logoPath!),
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => _placeholder(colorScheme),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(logoPath!),
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(colorScheme),
        ),
      );
    }

    return _placeholder(colorScheme);
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.extension_outlined,
        size: 18,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _ManagedExtension {
  const _ManagedExtension({
    required this.name,
    required this.path,
    required this.enabled,
    required this.filetypes,
    this.entry,
    this.languageId,
    this.lspExecutable,
    this.logoPath,
  });

  final String name;
  final String path;
  final bool enabled;
  final String? entry;
  final List<String> filetypes;
  final String? languageId;
  final String? lspExecutable;
  final String? logoPath;

  _ManagedExtension copyWith({
    String? name,
    String? path,
    bool? enabled,
    String? entry,
    List<String>? filetypes,
    String? languageId,
    String? lspExecutable,
    String? logoPath,
  }) {
    return _ManagedExtension(
      name: name ?? this.name,
      path: path ?? this.path,
      enabled: enabled ?? this.enabled,
      entry: entry ?? this.entry,
      filetypes: filetypes ?? this.filetypes,
      languageId: languageId ?? this.languageId,
      lspExecutable: lspExecutable ?? this.lspExecutable,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}
