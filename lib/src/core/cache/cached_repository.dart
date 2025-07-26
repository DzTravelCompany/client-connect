import 'cache_manager.dart';

/// Base class for repositories that want caching capabilities
abstract class CachedRepository {
  final CacheManager _cache = CacheManager();

  /// Get cached data or fetch from source
  Future<T> getCached<T>(
    String key,
    Future<T> Function() fetchFunction, {
    Duration? ttl,
  }) async {
    return await _cache.getOrSet(key, fetchFunction, ttl: ttl);
  }

  /// Invalidate cache entries matching pattern
  void invalidateCache(String pattern) {
    _cache.clearPattern(pattern);
  }

  /// Clear specific cache entry
  void clearCacheEntry(String key) {
    _cache.remove(key);
  }

  /// Clear all cache for this repository
  void clearAllCache() {
    _cache.clear();
  }
}