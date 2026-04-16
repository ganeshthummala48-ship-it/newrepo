import 'package:hive_flutter/hive_flutter.dart';

/// Simple key-value cache backed by Hive.
/// All cached entries include a timestamp so stale data can be detected.
class CacheService {
  static const String _boxName = 'cacheBox';
  static const Duration _stale = Duration(hours: 6);

  static Box get _box => Hive.box(_boxName);

  // ─── Write ───────────────────────────────────────────────────────────────
  static void save(String key, dynamic value) {
    _box.put(key, {'data': value, 'ts': DateTime.now().millisecondsSinceEpoch});
  }

  // ─── Read ────────────────────────────────────────────────────────────────
  static dynamic load(String key) {
    final entry = _box.get(key);
    if (entry == null) return null;
    return entry['data'];
  }

  /// Returns the age label, e.g. "3h ago", or null if no cache.
  static String? ageLabel(String key) {
    final entry = _box.get(key);
    if (entry == null) return null;
    final ts = entry['ts'] as int?;
    if (ts == null) return null;
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ts),
    );
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  /// Returns true if cached data exists and is not stale.
  static bool isFresh(String key) {
    final entry = _box.get(key);
    if (entry == null) return false;
    final ts = entry['ts'] as int?;
    if (ts == null) return false;
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <
        _stale;
  }

  static void clear(String key) => _box.delete(key);
}
