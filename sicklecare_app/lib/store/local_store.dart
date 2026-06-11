import 'package:hive/hive.dart';

class LocalStore {
  static Box get cache => Hive.box('app_cache');

  static T? get<T>(String key) {
    final v = cache.get(key);
    if (v is T) return v;
    return null;
  }

  static Future<void> set<T>(String key, T value) => cache.put(key, value);
  static Future<void> remove(String key) => cache.delete(key);
}
