import 'dart:collection';
import 'dart:ui' as ui;

/// LRU page cache for RGBA-decoded [ui.Image] objects.
///
/// Stores at most [maxSize] images. When the cache is full and a new page is
/// added, the page whose index is farthest from [currentPage] is evicted and
/// its [ui.Image] is disposed to release GPU texture memory.
///
/// Requirements: 6.2, 6.3, 6.4
class PageCache {
  PageCache({this.maxSize = 5});

  final int maxSize;

  // LinkedHashMap preserves insertion order — used to track LRU access order.
  final LinkedHashMap<int, ui.Image> _cache = LinkedHashMap();

  /// Return the cached image for [pageIndex], or null if not cached.
  ui.Image? get(int pageIndex) {
    final image = _cache.remove(pageIndex);
    if (image != null) {
      // Re-insert at end to mark as most-recently-used
      _cache[pageIndex] = image;
    }
    return image;
  }

  /// Store [image] for [pageIndex]. Evicts if over capacity.
  void put(int pageIndex, ui.Image image) {
    // Remove existing entry first (to update LRU order)
    _cache.remove(pageIndex)?.dispose();
    _cache[pageIndex] = image;
  }

  /// Evict the page whose index is farthest from [currentPage].
  ///
  /// Called after [put] to keep cache size ≤ [maxSize].
  void evictFarthestFrom(int currentPage) {
    if (_cache.length <= maxSize) return;

    int? farthestKey;
    int maxDistance = -1;

    for (final key in _cache.keys) {
      final distance = (key - currentPage).abs();
      if (distance > maxDistance) {
        maxDistance = distance;
        farthestKey = key;
      }
    }

    if (farthestKey != null) {
      _cache.remove(farthestKey)?.dispose();
    }
  }

  /// Dispose all cached images and clear the cache.
  ///
  /// Must be called when the ERP session is closed (Requirement 6.4).
  void clear() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }

  /// Number of pages currently in cache.
  int get length => _cache.length;

  /// Whether [pageIndex] is currently cached.
  bool contains(int pageIndex) => _cache.containsKey(pageIndex);
}
