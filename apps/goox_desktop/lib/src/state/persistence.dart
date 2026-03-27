import 'dart:io';
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

@Entity()
class WorkspaceSettings {
  @Id()
  int id = 0;

  String? lastFolderPath;
  String themeMode;

  WorkspaceSettings({
    this.id = 0,
    this.lastFolderPath,
    required this.themeMode,
  });
}

class PersistenceService {
  late final Store store;
  late final Box<RecentFolder> recentFolderBox;
  late final Box<WorkspaceSettings> settingsBox;

  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'goox_desktop', 'objectbox');
    
    // Ensure the directory exists before opening the store
    final dir = Directory(dbPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    
    store = await openStore(directory: dbPath);
    recentFolderBox = store.box<RecentFolder>();
    settingsBox = store.box<WorkspaceSettings>();
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
