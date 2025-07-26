import 'dart:async';
import 'package:client_connect/constants.dart';

import '../realtime/event_bus.dart';
import '../realtime/realtime_sync_service.dart';
import 'cache_manager.dart';

/// Enhanced cache manager with real-time invalidation
class EnhancedCacheManager {
  static final EnhancedCacheManager _instance = EnhancedCacheManager._internal();
  factory EnhancedCacheManager() => _instance;
  EnhancedCacheManager._internal();

  final CacheManager _cacheManager = CacheManager();
  final RealtimeSyncService _syncService = RealtimeSyncService();
  final Map<String, Set<String>> _keyDependencies = {};
  final Map<String, Timer> _autoRefreshTimers = {};

  void set<T>(String key, T value, {Duration? ttl}) {
    _cacheManager.set(key, value, ttl: ttl);
    
    // Emit cache event
    _syncService.emitEvent(CacheEvent(
      type: CacheEventType.hit,
      cacheKey: key,
      timestamp: DateTime.now(),
      source: 'EnhancedCacheManager',
    ));
  }

  T? get<T>(String key) {
    final value = _cacheManager.get<T>(key);
    
    // Emit cache event
    _syncService.emitEvent(CacheEvent(
      type: value != null ? CacheEventType.hit : CacheEventType.miss,
      cacheKey: key,
      timestamp: DateTime.now(),
      source: 'EnhancedCacheManager',
    ));
    
    return value;
  }

  void remove(String key) {
    _cacheManager.remove(key);
    
    // Cancel auto-refresh timer if exists
    _autoRefreshTimers[key]?.cancel();
    _autoRefreshTimers.remove(key);
    
    // Emit cache event
    _syncService.emitEvent(CacheEvent(
      type: CacheEventType.invalidated,
      cacheKey: key,
      timestamp: DateTime.now(),
      source: 'EnhancedCacheManager',
    ));
    
    // Invalidate dependent keys
    _invalidateDependentKeys(key);
  }

  void clearPattern(String pattern) {
    _cacheManager.clearPattern(pattern);
    
    // Emit cache event
    _syncService.emitEvent(CacheEvent(
      type: CacheEventType.invalidated,
      cacheKey: pattern,
      timestamp: DateTime.now(),
      source: 'EnhancedCacheManager',
    ));
  }

  void clear() {
    _cacheManager.clear();
    
    // Cancel all auto-refresh timers
    for (final timer in _autoRefreshTimers.values) {
      timer.cancel();
    }
    _autoRefreshTimers.clear();
    _keyDependencies.clear();
    
    // Emit cache event
    _syncService.emitEvent(CacheEvent(
      type: CacheEventType.cleared,
      timestamp: DateTime.now(),
      source: 'EnhancedCacheManager',
    ));
  }

  // Delegate getStats method
  CacheStats getStats() => _cacheManager.getStats();

  /// Set cache with auto-refresh capability
  void setWithAutoRefresh<T>(
    String key,
    T value,
    Future<T> Function() refreshFunction, {
    Duration? ttl,
    Duration refreshInterval = const Duration(minutes: 5),
  }) {
    set(key, value, ttl: ttl);
    
    // Cancel existing timer
    _autoRefreshTimers[key]?.cancel();
    
    // Set up auto-refresh timer
    _autoRefreshTimers[key] = Timer.periodic(refreshInterval, (timer) async {
      try {
        final newValue = await refreshFunction();
        set(key, newValue, ttl: ttl);
      } catch (e) {
        // Log error but don't cancel timer
        logger.i('Auto-refresh failed for key $key: $e');
      }
    });
  }

  /// Set dependencies between cache keys
  void setDependency(String key, String dependentKey) {
    _keyDependencies.putIfAbsent(key, () => <String>{}).add(dependentKey);
  }

  /// Set multiple dependencies
  void setDependencies(String key, List<String> dependentKeys) {
    _keyDependencies.putIfAbsent(key, () => <String>{}).addAll(dependentKeys);
  }

  /// Invalidate dependent keys when a key is removed
  void _invalidateDependentKeys(String key) {
    final dependentKeys = _keyDependencies[key];
    if (dependentKeys != null) {
      for (final dependentKey in dependentKeys) {
        remove(dependentKey);
      }
    }
  }

  /// Get cache with dependency tracking
  Future<T> getOrSetWithDependencies<T>(
    String key,
    Future<T> Function() factory, {
    Duration? ttl,
    List<String>? dependencies,
  }) async {
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }
    
    final value = await factory();
    set(key, value, ttl: ttl);
    
    // Set up dependencies
    if (dependencies != null) {
      for (final dependency in dependencies) {
        setDependency(dependency, key);
      }
    }
    
    return value;
  }

  /// Invalidate cache based on event patterns
  void invalidateByEventPattern(AppEvent event) {
    switch (event.runtimeType) {
      case ClientEvent _:
        final clientEvent = event as ClientEvent;
        if (clientEvent.clientId != null) {
          remove('client_by_id_${clientEvent.clientId}');
        }
        clearPattern('client_');
        break;
      case CampaignEvent _:
        final campaignEvent = event as CampaignEvent;
        remove('campaign_by_id_${campaignEvent.campaignId}');
        clearPattern('campaign_');
        break;
      case TemplateEvent _:
        final templateEvent = event as TemplateEvent;
        if (templateEvent.templateId != null) {
          remove('template_by_id_${templateEvent.templateId}');
        }
        clearPattern('template_');
        break;
    }
  }

  /// Get enhanced cache statistics
  EnhancedCacheStats getEnhancedStats() {
    final baseStats = getStats();
    return EnhancedCacheStats(
      totalEntries: baseStats.totalEntries,
      expiredEntries: baseStats.expiredEntries,
      estimatedSizeBytes: baseStats.estimatedSizeBytes,
      autoRefreshKeys: _autoRefreshTimers.length,
      dependencyMappings: _keyDependencies.length,
      totalDependencies: _keyDependencies.values
          .fold(0, (sum, deps) => sum + deps.length),
    );
  }
}

/// Enhanced cache statistics
class EnhancedCacheStats extends CacheStats {
  final int autoRefreshKeys;
  final int dependencyMappings;
  final int totalDependencies;

  const EnhancedCacheStats({
    required super.totalEntries,
    required super.expiredEntries,
    required super.estimatedSizeBytes,
    required this.autoRefreshKeys,
    required this.dependencyMappings,
    required this.totalDependencies,
  });

  @override
  String toString() {
    return 'EnhancedCacheStats(entries: $totalEntries, expired: $expiredEntries, '
           'size: ${estimatedSizeBytes}B, autoRefresh: $autoRefreshKeys, '
           'dependencies: $dependencyMappings/$totalDependencies)';
  }
}