import 'dart:async';
import 'dart:collection';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, CacheEntry> _cache = HashMap<String, CacheEntry>();
  final Map<String, Timer> _timers = HashMap<String, Timer>();
  
  // Default TTL values
  static const Duration defaultTtl = Duration(minutes: 5);
  static const Duration shortTtl = Duration(minutes: 1);
  static const Duration longTtl = Duration(hours: 1);

  /// Get cached value by key
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      entry.lastAccessed = DateTime.now();
      return entry.value as T;
    }
    
    // Clean up expired entry
    if (entry != null) {
      _removeEntry(key);
    }
    
    return null;
  }

  /// Set cached value with optional TTL
  void set<T>(String key, T value, {Duration? ttl}) {
    final duration = ttl ?? defaultTtl;
    final expiresAt = DateTime.now().add(duration);
    
    // Remove existing entry and timer
    _removeEntry(key);
    
    // Create new cache entry
    _cache[key] = CacheEntry(
      value: value,
      expiresAt: expiresAt,
      lastAccessed: DateTime.now(),
    );
    
    // Set expiration timer
    _timers[key] = Timer(duration, () => _removeEntry(key));
  }

  /// Get or set cached value using a factory function
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() factory, {
    Duration? ttl,
  }) async {
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }
    
    final value = await factory();
    set(key, value, ttl: ttl);
    return value;
  }

  /// Remove specific cache entry
  void remove(String key) {
    _removeEntry(key);
  }

  /// Clear all cache entries
  void clear() {
    final keys = _cache.keys.toList();
    for (final key in keys) {
      _removeEntry(key);
    }
  }

  /// Clear cache entries matching pattern
  void clearPattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys.where((key) => regex.hasMatch(key)).toList();
    
    for (final key in keysToRemove) {
      _removeEntry(key);
    }
  }

  /// Get cache statistics
  CacheStats getStats() {
    int expiredCount = 0;
    int totalSize = 0;
    
    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expiredCount++;
      }
      totalSize += _estimateSize(entry.value);
    }
    
    return CacheStats(
      totalEntries: _cache.length,
      expiredEntries: expiredCount,
      estimatedSizeBytes: totalSize,
    );
  }

  /// Clean up expired entries
  void cleanup() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _removeEntry(key);
    }
  }

  void _removeEntry(String key) {
    _cache.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  int _estimateSize(dynamic value) {
    // Simple size estimation - can be improved
    if (value is String) return value.length * 2;
    if (value is List) return value.length * 8;
    if (value is Map) return value.length * 16;
    return 8; // Default size for primitives
  }
}

class CacheEntry {
  final dynamic value;
  final DateTime expiresAt;
  DateTime lastAccessed;

  CacheEntry({
    required this.value,
    required this.expiresAt,
    required this.lastAccessed,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final int estimatedSizeBytes;

  const CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.estimatedSizeBytes,
  });

  @override
  String toString() {
    return 'CacheStats(entries: $totalEntries, expired: $expiredEntries, size: ${estimatedSizeBytes}B)';
  }
}

// Cache key constants
class CacheKeys {
  static const String clientPrefix = 'client_';
  static const String templatePrefix = 'template_';
  static const String campaignPrefix = 'campaign_';
  static const String analyticsPrefix = 'analytics_';
  
  static String clientById(int id) => '${clientPrefix}by_id_$id';
  static String clientsPaginated(int page, int limit, String? search) => 
      '${clientPrefix}paginated_${page}_${limit}_${search ?? 'all'}';
  static String templateById(int id) => '${templatePrefix}by_id_$id';
  static String campaignById(int id) => '${campaignPrefix}by_id_$id';
  static String analyticsData(String type, DateTime date) => 
      '$analyticsPrefix${type}_${date.toIso8601String().split('T')[0]}';
  static String get clientCompanies => '${clientPrefix}_companies';
}