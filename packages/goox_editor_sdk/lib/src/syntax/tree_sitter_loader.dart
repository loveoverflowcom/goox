import 'dart:ffi' as ffi;
import 'dart:io' show Platform, Directory;
import 'package:path/path.dart' as path;

/// Handles platform-specific loading of Tree-sitter native libraries
class TreeSitterLoader {
  /// Load Tree-sitter library for the current platform
  static ffi.DynamicLibrary loadTreeSitter() {
    if (Platform.isLinux) {
      return _loadLinux();
    } else if (Platform.isMacOS) {
      return _loadMacOS();
    } else if (Platform.isWindows) {
      return _loadWindows();
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported for Tree-sitter',
      );
    }
  }
  
  /// Load a Tree-sitter language grammar library
  static ffi.DynamicLibrary loadLanguage(String languageName) {
    final libraryName = _getLanguageLibraryName(languageName);
    
    if (Platform.isLinux) {
      return _tryLoadPaths([
        libraryName,
        '/usr/lib/$libraryName',
        '/usr/local/lib/$libraryName',
      ]);
    } else if (Platform.isMacOS) {
      return _tryLoadPaths([
        libraryName,
        '/usr/local/lib/$libraryName',
        '/opt/homebrew/lib/$libraryName',
      ]);
    } else if (Platform.isWindows) {
      return _tryLoadPaths([
        libraryName,
        path.join(Directory.current.path, libraryName),
      ]);
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported',
      );
    }
  }
  
  static ffi.DynamicLibrary _loadLinux() {
    return _tryLoadPaths([
      'libtree-sitter.so.0',
      'libtree-sitter.so',
      '/usr/lib/libtree-sitter.so',
      '/usr/local/lib/libtree-sitter.so',
    ]);
  }
  
  static ffi.DynamicLibrary _loadMacOS() {
    return _tryLoadPaths([
      'libtree-sitter.0.dylib',
      'libtree-sitter.dylib',
      '/usr/local/lib/libtree-sitter.dylib',
      '/opt/homebrew/lib/libtree-sitter.dylib',
    ]);
  }
  
  static ffi.DynamicLibrary _loadWindows() {
    return _tryLoadPaths([
      'tree-sitter.dll',
      path.join(Directory.current.path, 'tree-sitter.dll'),
    ]);
  }
  
  static ffi.DynamicLibrary _tryLoadPaths(List<String> paths) {
    for (final libPath in paths) {
      try {
        return ffi.DynamicLibrary.open(libPath);
      } catch (e) {
        // Try next path
        continue;
      }
    }
    
    throw UnsupportedError(
      'Could not load Tree-sitter library. Tried paths: ${paths.join(", ")}',
    );
  }
  
  static String _getLanguageLibraryName(String languageName) {
    if (Platform.isLinux) {
      return 'libtree-sitter-$languageName.so';
    } else if (Platform.isMacOS) {
      return 'libtree-sitter-$languageName.dylib';
    } else if (Platform.isWindows) {
      return 'tree-sitter-$languageName.dll';
    } else {
      throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
    }
  }
}
