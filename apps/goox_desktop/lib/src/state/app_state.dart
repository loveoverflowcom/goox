import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.system) {
      setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.system);
    }
  }

  // --- File Explorer State ---
  String? _rootPath;
  String? get rootPath => _rootPath;
  List<FileSystemEntity> _files = [];
  List<FileSystemEntity> get files => _files;

  final Set<String> _expandedFolders = {};
  Set<String> get expandedFolders => _expandedFolders;

  // Tabs state
  final List<String> _openFiles = [];
  List<String> get openFiles => _openFiles;

  String? _activeFile;
  String? get activeFile => _activeFile;

  final Set<String> _dirtyFiles = {};
  Set<String> get dirtyFiles => _dirtyFiles;

  // File watcher
  StreamSubscription<FileSystemEvent>? _directoryWatcher;

  AppState();

  void openDirectory(String path) {
    _rootPath = path;
    _expandedFolders
      ..clear()
      ..add(path);
    _openFiles.clear();
    _dirtyFiles.clear();
    _activeFile = null;
    _refreshWorkspace();
    _watchDirectory();
  }

  Future<void> pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      openDirectory(result);
    }
  }

  void _loadDirectory() {
    if (_rootPath == null) {
      _files = [];
      return;
    }
    final dir = Directory(_rootPath!);
    if (dir.existsSync()) {
      _files =
          dir.listSync().where((e) {
            final name = p.basename(e.path);
            return !name.startsWith('.') &&
                name != 'target' &&
                name != 'build'; // Basic ignore rules
          }).toList()..sort((a, b) {
            if (a is Directory && b is File) return -1;
            if (a is File && b is Directory) return 1;
            return p
                .basename(a.path)
                .toLowerCase()
                .compareTo(p.basename(b.path).toLowerCase());
          });
    } else {
      _files = [];
    }
  }

  void _refreshWorkspace() {
    _loadDirectory();
    notifyListeners();
  }

  void _watchDirectory() {
    _directoryWatcher?.cancel();
    if (_rootPath != null) {
      final dir = Directory(_rootPath!);
      if (dir.existsSync()) {
        _directoryWatcher = dir.watch(recursive: true).listen((event) {
          // Add a small delay to debounce
          Future.delayed(const Duration(milliseconds: 100), () {
            _loadDirectory();
            notifyListeners();
          });
        });
      }
    }
  }

  void toggleFolder(String path) {
    if (_expandedFolders.contains(path)) {
      _expandedFolders.remove(path);
    } else {
      _expandedFolders.add(path);
    }
    notifyListeners();
  }

  bool isFolderExpanded(String path) {
    return _expandedFolders.contains(path);
  }

  // Gets children for a specific folder path
  List<FileSystemEntity> getChildren(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];

    return dir.listSync().where((e) {
      final name = p.basename(e.path);
      return !name.startsWith('.') && name != 'target' && name != 'build';
    }).toList()..sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase());
    });
  }

  // --- Editor Tabs State ---
  void openFile(String path) {
    if (!_openFiles.contains(path)) {
      _openFiles.add(path);
    }
    _activeFile = path;
    notifyListeners();
  }

  void closeFile(String path) {
    _openFiles.remove(path);
    if (_activeFile == path) {
      if (_openFiles.isNotEmpty) {
        _activeFile = _openFiles.last;
      } else {
        _activeFile = null;
      }
    }
    _dirtyFiles.remove(path);
    notifyListeners();
  }

  void switchTab(String path) {
    if (_openFiles.contains(path)) {
      _activeFile = path;
      notifyListeners();
    }
  }

  void markFileDirty(String path, bool isDirty) {
    if (isDirty) {
      _dirtyFiles.add(path);
    } else {
      _dirtyFiles.remove(path);
    }
    notifyListeners();
  }

  bool isFileDirty(String path) {
    return _dirtyFiles.contains(path);
  }

  Future<void> createNewFile(String parentDir, String name) async {
    final sanitizedName = name.trim();
    if (sanitizedName.isEmpty) {
      return;
    }

    if (!_expandedFolders.contains(parentDir)) {
      _expandedFolders.add(parentDir);
    }

    final newPath = p.join(parentDir, sanitizedName);
    final file = File(newPath);
    if (file.existsSync() || Directory(newPath).existsSync()) {
      throw FileSystemException('Entry already exists', newPath);
    }

    await file.create(recursive: true);
    _refreshWorkspace();
    openFile(newPath);
  }

  Future<void> createNewFolder(String parentDir, String name) async {
    final sanitizedName = name.trim();
    if (sanitizedName.isEmpty) {
      return;
    }

    if (!_expandedFolders.contains(parentDir)) {
      _expandedFolders.add(parentDir);
    }

    final newPath = p.join(parentDir, sanitizedName);
    if (Directory(newPath).existsSync() || File(newPath).existsSync()) {
      throw FileSystemException('Entry already exists', newPath);
    }

    await Directory(newPath).create();
    _expandedFolders.add(newPath);
    _refreshWorkspace();
  }

  Future<void> renameEntry(String path, String newName) async {
    final sanitizedName = newName.trim();
    if (sanitizedName.isEmpty) {
      return;
    }

    final parentDir = p.dirname(path);
    final targetPath = p.join(parentDir, sanitizedName);
    if (path == targetPath) {
      return;
    }

    if (File(targetPath).existsSync() || Directory(targetPath).existsSync()) {
      throw FileSystemException('Entry already exists', targetPath);
    }

    final entityType = FileSystemEntity.typeSync(path);
    if (entityType == FileSystemEntityType.notFound) {
      throw FileSystemException('Entry not found', path);
    }

    if (entityType == FileSystemEntityType.directory) {
      await Directory(path).rename(targetPath);
      _remapExpandedFolderPaths(path, targetPath);
      _remapOpenPaths(path, targetPath);
    } else {
      await File(path).rename(targetPath);
      _remapOpenPaths(path, targetPath);
    }

    _refreshWorkspace();
  }

  Future<void> deleteEntry(String path) async {
    final entityType = FileSystemEntity.typeSync(path);
    if (entityType == FileSystemEntityType.notFound) {
      return;
    }

    if (entityType == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
      _expandedFolders.removeWhere(
        (folderPath) => folderPath == path || p.isWithin(path, folderPath),
      );
      _removeOpenPathsUnder(path);
    } else {
      await File(path).delete();
      _openFiles.remove(path);
      _dirtyFiles.remove(path);
      if (_activeFile == path) {
        _activeFile = _openFiles.isNotEmpty ? _openFiles.last : null;
      }
    }

    _refreshWorkspace();
  }

  void _remapExpandedFolderPaths(String sourcePath, String targetPath) {
    final remapped = _expandedFolders.map((folderPath) {
      if (folderPath == sourcePath) {
        return targetPath;
      }
      if (p.isWithin(sourcePath, folderPath)) {
        final relativePath = p.relative(folderPath, from: sourcePath);
        return p.join(targetPath, relativePath);
      }
      return folderPath;
    }).toSet();

    _expandedFolders
      ..clear()
      ..addAll(remapped);
  }

  void _remapOpenPaths(String sourcePath, String targetPath) {
    for (var index = 0; index < _openFiles.length; index++) {
      final filePath = _openFiles[index];
      if (filePath == sourcePath) {
        _openFiles[index] = targetPath;
      } else if (p.isWithin(sourcePath, filePath)) {
        final relativePath = p.relative(filePath, from: sourcePath);
        _openFiles[index] = p.join(targetPath, relativePath);
      }
    }

    final remappedDirtyFiles = _dirtyFiles.map((filePath) {
      if (filePath == sourcePath) {
        return targetPath;
      }
      if (p.isWithin(sourcePath, filePath)) {
        final relativePath = p.relative(filePath, from: sourcePath);
        return p.join(targetPath, relativePath);
      }
      return filePath;
    }).toSet();

    _dirtyFiles
      ..clear()
      ..addAll(remappedDirtyFiles);

    if (_activeFile == sourcePath) {
      _activeFile = targetPath;
    } else if (_activeFile != null && p.isWithin(sourcePath, _activeFile!)) {
      final relativePath = p.relative(_activeFile!, from: sourcePath);
      _activeFile = p.join(targetPath, relativePath);
    }
  }

  void _removeOpenPathsUnder(String folderPath) {
    _openFiles.removeWhere(
      (filePath) => filePath == folderPath || p.isWithin(folderPath, filePath),
    );
    _dirtyFiles.removeWhere(
      (filePath) => filePath == folderPath || p.isWithin(folderPath, filePath),
    );

    if (_activeFile == folderPath ||
        (_activeFile != null && p.isWithin(folderPath, _activeFile!))) {
      _activeFile = _openFiles.isNotEmpty ? _openFiles.last : null;
    }
  }

  @override
  void dispose() {
    _directoryWatcher?.cancel();
    super.dispose();
  }
}
