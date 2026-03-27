import 'dart:convert';
import 'dart:io';
import 'app_settings.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// The generator will create objectbox.g.dart in the lib directory.
import '../../objectbox.g.dart';

@Entity()
class RecentFolder {
  @Id()
  int id = 0;

  @Unique()
  String path;

  @Property(type: PropertyType.date)
  DateTime lastOpenedAt;

  RecentFolder({
    this.id = 0,
    required this.path,
    required this.lastOpenedAt,
  });
}



class PersistenceService {
  late final Store store;
  late final Box<RecentFolder> recentFolderBox;
  
  late final File _settingsFile;
  AppSettings _cachedSettings = const AppSettings();

  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'goox_desktop', 'objectbox');
    final settingsPath = p.join(docsDir.path, 'goox_desktop', 'settings.json');
    _settingsFile = File(settingsPath);

    // Ensure the directory exists before opening the store
    final dir = Directory(dbPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    
    store = await openStore(directory: dbPath);
    recentFolderBox = store.box<RecentFolder>();

    // Load settings from JSON
    if (_settingsFile.existsSync()) {
      try {
        final content = _settingsFile.readAsStringSync();
        _cachedSettings = AppSettings.fromJson(jsonDecode(content));
      } catch (e) {
        // Fallback to defaults if file is corrupted
      }
    } else {
      // Create default settings file
      _saveSettingsSync(_cachedSettings);
    }
  }

  AppSettings getSettings() => _cachedSettings;

  void saveSettings(AppSettings settings) {
    _cachedSettings = settings;
    _saveSettingsSync(settings);
  }

  void _saveSettingsSync(AppSettings settings) {
    _settingsFile.writeAsStringSync(jsonEncode(settings.toJson()));
  }

  List<RecentFolder> getRecentFolders({int limit = 100}) {
    final query = recentFolderBox
        .query()
        .order(RecentFolder_.lastOpenedAt, flags: Order.descending)
        .build();
    query.limit = limit;
    final results = query.find();
    query.close();
    return results;
  }

  void addOrUpdateRecentFolder(String path) {
    // Check if it exists
    final query = recentFolderBox.query(RecentFolder_.path.equals(path)).build();
    final existing = query.findFirst();
    query.close();

    if (existing != null) {
      existing.lastOpenedAt = DateTime.now();
      recentFolderBox.put(existing);
    } else {
      recentFolderBox.put(RecentFolder(path: path, lastOpenedAt: DateTime.now()));
    }

    _enforceRecentFoldersLimit(100);
  }

  void _enforceRecentFoldersLimit(int limit) {
    final count = recentFolderBox.count();
    if (count > limit) {
      // Find the oldest entries to delete
      final query = recentFolderBox
          .query()
          .order(RecentFolder_.lastOpenedAt) // Ascending, oldest first
          .build();
      query.limit = count - limit;
      final oldestIds = query.findIds();
      query.close();

      if (oldestIds.isNotEmpty) {
        recentFolderBox.removeMany(oldestIds);
      }
    }
  }

  void dispose() {
    store.close();
  }
}
