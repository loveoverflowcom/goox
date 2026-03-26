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

  AppState() {
    _initWorkspace();
  }

  void _initWorkspace() {
    // Using the current directory by default for testing
    openDirectory(Directory.current.path);
  }

  void openDirectory(String path) {
    _rootPath = path;
    _loadDirectory();
    _watchDirectory();
    // Default open the root folder
    _expandedFolders.add(path);
    notifyListeners();
  }

  Future<void> pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      openDirectory(result);
    }
  }

  void _loadDirectory() {
    if (_rootPath == null) return;
    final dir = Directory(_rootPath!);
    if (dir.existsSync()) {
      _files = dir.listSync().where((e) {
        final name = p.basename(e.path);
        return !name.startsWith('.') && name != 'target' && name != 'build'; // Basic ignore rules
      }).toList()
        ..sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
        });
    }
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
    }).toList()
        ..sort((a, b) {
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
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

  // Creates a new file
  Future<void> createNewFile(String parentDir) async {
    if (!_expandedFolders.contains(parentDir)) {
      _expandedFolders.add(parentDir);
    }
    int counter = 1;
    String newPath = p.join(parentDir, 'new_file.txt');
    while (File(newPath).existsSync()) {
      newPath = p.join(parentDir, 'new_file_$counter.txt');
      counter++;
    }
    await File(newPath).create();
    openFile(newPath); // Auto open
  }

  // Creates a new folder
  Future<void> createNewFolder(String parentDir) async {
    if (!_expandedFolders.contains(parentDir)) {
      _expandedFolders.add(parentDir);
    }
    int counter = 1;
    String newPath = p.join(parentDir, 'new_folder');
    while (Directory(newPath).existsSync()) {
      newPath = p.join(parentDir, 'new_folder_$counter');
      counter++;
    }
    await Directory(newPath).create();
  }

  @override
  void dispose() {
    _directoryWatcher?.cancel();
    super.dispose();
  }
}
