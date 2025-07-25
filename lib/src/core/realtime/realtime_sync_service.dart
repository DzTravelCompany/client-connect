import 'dart:async';
import 'dart:ui';
import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/campaigns/logic/campaign_providers.dart';
import 'package:client_connect/src/features/clients/logic/client_providers.dart';
import 'package:client_connect/src/features/dashboard/logic/dashboard_providers.dart';
import 'package:client_connect/src/features/tags/logic/tag_providers.dart';
import 'package:client_connect/src/features/templates/logic/template_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache/cache_manager.dart';
import '../services/database_service.dart';
import 'event_bus.dart';

/// Real-time synchronization service that coordinates updates across the app
class RealtimeSyncService {
  static final RealtimeSyncService _instance = RealtimeSyncService._internal();
  factory RealtimeSyncService() => _instance;
  RealtimeSyncService._internal();

  final EventBus _eventBus = EventBus();
  final CacheManager _cacheManager = CacheManager();
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  
  bool _isInitialized = false;
  ProviderContainer? _providerContainer;

  /// Initialize the real-time sync service
  Future<void> initialize(ProviderContainer container) async {
    if (_isInitialized) return;

    _providerContainer = container;
    
    // Set up event listeners
    _setupEventListeners();
    
    // Set up database change listeners
    _setupDatabaseListeners();
    
    // Set up cache invalidation listeners
    _setupCacheListeners();
    
    // Set up isolate communication
    _setupIsolateListeners();
    
    _isInitialized = true;
    
    logger.i('RealtimeSyncService initialized');
    
    // Emit system startup event
    _eventBus.emit(SystemEvent(
      type: SystemEventType.startup,
      timestamp: DateTime.now(),
      source: 'RealtimeSyncService',
    ));
  }

  /// Set up event listeners for different event types
  void _setupEventListeners() {
    // Client events
    _subscriptions['client_events'] = _eventBus.on<ClientEvent>().listen((event) {
      _handleClientEvent(event);
    });

    // Campaign events
    _subscriptions['campaign_events'] = _eventBus.on<CampaignEvent>().listen((event) {
      _handleCampaignEvent(event);
    });

    // Template events
    _subscriptions['template_events'] = _eventBus.on<TemplateEvent>().listen((event) {
      _handleTemplateEvent(event);
    });

    // Tag events
    _subscriptions['tag_events'] = _eventBus.on<TagEvent>().listen((event) {
      _handleTagEvent(event);
    });

    // Database events
    _subscriptions['database_events'] = _eventBus.on<DatabaseEvent>().listen((event) {
      _handleDatabaseEvent(event);
    });
  }

  /// Set up database change listeners using Drift's watch functionality
  void _setupDatabaseListeners() {
    final db = DatabaseService.instance.database;

    // Watch clients table - with debouncing to prevent excessive events
    _subscriptions['clients_watch'] = db.select(db.clients).watch().listen((clients) {
      _debounceEvent('clients_changed', () {
        logger.d('Clients table changed: ${clients.length} clients');
      
        if (_providerContainer != null) {
          Future.microtask(() {
            _providerContainer!.invalidate(allClientsProvider);
            _providerContainer!.invalidate(allClientsWithTagsProvider);
          });
        }
      }, delay: const Duration(milliseconds: 200));
    });

    // Watch tags table
    _subscriptions['tags_watch'] = db.select(db.tags).watch().listen((tags) {
      _debounceEvent('tags_changed', () {
        logger.d('Tags table changed: ${tags.length} tags');
      
        if (_providerContainer != null) {
          Future.microtask(() {
            _providerContainer!.invalidate(allTagsProvider);
            _providerContainer!.invalidate(tagUsageStatsProvider);
            _providerContainer!.invalidate(allClientsWithTagsProvider);
          });
        }
      }, delay: const Duration(milliseconds: 100));
    });

    // Watch campaigns table
    _subscriptions['campaigns_watch'] = db.select(db.campaigns).watch().listen((campaigns) {
      _debounceEvent('campaigns_changed', () {
        logger.d('Campaigns table changed: ${campaigns.length} campaigns');
      
        if (_providerContainer != null) {
          Future.microtask(() {
            _providerContainer!.invalidate(allCampaignsProvider);
            _providerContainer!.invalidate(dashboardMetricsProvider);
          });
        }
      }, delay: const Duration(milliseconds: 200));
    });

    // Watch templates table
    _subscriptions['templates_watch'] = db.select(db.templates).watch().listen((templates) {
      _debounceEvent('templates_changed', () {
        logger.d('Templates table changed: ${templates.length} templates');
      
        if (_providerContainer != null) {
          Future.microtask(() {
            _providerContainer!.invalidate(templatesProvider);
          });
        }
      }, delay: const Duration(milliseconds: 200));
    });

    // Watch message logs table
    _subscriptions['message_logs_watch'] = db.select(db.messageLogs).watch().listen((logs) {
      _debounceEvent('message_logs_changed', () {
        logger.d('Message logs changed: ${logs.length} logs');
      
        if (_providerContainer != null) {
          Future.microtask(() {
            _providerContainer!.invalidate(dashboardActivityProvider);
          });
        }
      }, delay: const Duration(milliseconds: 200));
    });

    // Watch client_tags table for tag assignments
    _subscriptions['client_tags_watch'] = db.select(db.clientTags).watch().listen((clientTags) {
      _debounceEvent('client_tags_changed', () {
        logger.d('Client tags changed: ${clientTags.length} assignments');
      
        if (_providerContainer != null) {
          Future.microtask(() {
            _providerContainer!.invalidate(allClientsWithTagsProvider);
            _providerContainer!.invalidate(tagUsageStatsProvider);
          
            // Invalidate specific client tag providers
            final affectedClients = clientTags.map((ct) => ct.clientId).toSet();
            for (final clientId in affectedClients) {
              _providerContainer!.invalidate(tagsForClientProvider(clientId));
              _providerContainer!.invalidate(clientTagsProvider(clientId));
            }
          });
        }
      }, delay: const Duration(milliseconds: 100));
    });
  }

  /// Set up cache invalidation listeners
  void _setupCacheListeners() {
    // Listen to cache events and invalidate related providers
    _subscriptions['cache_events'] = _eventBus.on<CacheEvent>().listen((event) {
      if (event.type == CacheEventType.invalidated && _providerContainer != null) {
        _invalidateRelatedProviders(event.cacheKey);
      }
    });
  }

  /// Set up isolate communication for background tasks
  void _setupIsolateListeners() {
    // This would be enhanced to listen to isolate messages
    // For now, we'll rely on the existing SendingEngine progress stream
  }

  /// Enhanced event handling with proper provider invalidation
  void _handleClientEvent(ClientEvent event) {
    logger.d('Handling client event: ${event.type}');
  
    // Debounce rapid client events
    _debounceEvent('client_event_${event.clientId ?? 'bulk'}', () {
      // Invalidate client-related cache entries
      switch (event.type) {
        case ClientEventType.created:
        case ClientEventType.updated:
          if (event.clientId != null) {
            _cacheManager.remove('client_by_id_${event.clientId}');
          }
          _cacheManager.clearPattern('client_');
          _cacheManager.remove('client_companies');
        
          // Invalidate specific providers with proper timing
          if (_providerContainer != null) {
            Future.microtask(() {
              _providerContainer!.invalidate(allClientsProvider);
              _providerContainer!.invalidate(clientCompaniesProvider);
              _providerContainer!.invalidate(allClientsWithTagsProvider);
              _providerContainer!.invalidate(dashboardMetricsProvider);
            
              if (event.clientId != null) {
                _providerContainer!.invalidate(clientByIdProvider(event.clientId!));
                _providerContainer!.invalidate(tagsForClientProvider(event.clientId!));
              }
            });
          }
          break;
        
        case ClientEventType.deleted:
          if (event.clientId != null) {
            _cacheManager.remove('client_by_id_${event.clientId}');
          }
          _cacheManager.clearPattern('client_');
          _cacheManager.remove('client_companies');
        
          if (_providerContainer != null) {
            Future.microtask(() {
              _providerContainer!.invalidate(allClientsProvider);
              _providerContainer!.invalidate(clientCompaniesProvider);
              _providerContainer!.invalidate(allClientsWithTagsProvider);
              _providerContainer!.invalidate(dashboardMetricsProvider);
            
              if (event.clientId != null) {
                _providerContainer!.invalidate(clientByIdProvider(event.clientId!));
              }
            });
          }
          break;
        
        case ClientEventType.bulkUpdated:
        case ClientEventType.bulkDeleted:
          _cacheManager.clearPattern('client_');
          _cacheManager.remove('client_companies');
        
          if (_providerContainer != null) {
            Future.microtask(() {
              _providerContainer!.invalidate(allClientsProvider);
              _providerContainer!.invalidate(clientCompaniesProvider);
              _providerContainer!.invalidate(allClientsWithTagsProvider);
              _providerContainer!.invalidate(dashboardMetricsProvider);
              _providerContainer!.invalidate(tagUsageStatsProvider);
            });
          }
          break;
      }

      // Emit cache invalidation event (but don't cause circular dependencies)
      _eventBus.emit(CacheEvent(
        type: CacheEventType.invalidated,
        cacheKey: 'client_*',
        timestamp: DateTime.now(),
        source: 'RealtimeSyncService',
      ));
    }, delay: const Duration(milliseconds: 100));
  }

  /// Handle tag-related events
  void _handleTagEvent(TagEvent event) {
    logger.d('Handling tag event: ${event.type} for tag ${event.tagId}');
    
    // Debounce rapid tag events
    _debounceEvent('tag_event_${event.tagId ?? 'general'}', () {
      // Invalidate tag-related cache entries
      if (event.tagId != null) {
        _cacheManager.remove('tag_by_id_${event.tagId}');
      }
      _cacheManager.clearPattern('tag_');
      
      // Emit cache invalidation event
      _eventBus.emit(CacheEvent(
        type: CacheEventType.invalidated,
        cacheKey: 'tag_*',
        timestamp: DateTime.now(),
        source: 'RealtimeSyncService',
      ));

      // Invalidate related providers
      if (_providerContainer != null) {
        Future.microtask(() {
          _providerContainer!.invalidate(allTagsProvider);
          _providerContainer!.invalidate(tagUsageStatsProvider);
          _providerContainer!.invalidate(allClientsWithTagsProvider);
          
          if (event.tagId != null) {
            _providerContainer!.invalidate(tagByIdProvider(event.tagId!));
          }
          
          // If tag was deleted, also refresh client views
          if (event.type == TagEventType.deleted) {
            _providerContainer!.invalidate(allClientsProvider);
          }
        });
      }
    }, delay: const Duration(milliseconds: 50)); // Faster response for tag events
  }

  /// Handle campaign-related events
  void _handleCampaignEvent(CampaignEvent event) {
    logger.d('Handling campaign event: ${event.type}');
    
    // Invalidate campaign-related cache entries
    _cacheManager.remove('campaign_by_id_${event.campaignId}');
    _cacheManager.clearPattern('campaign_');
    
    // Emit cache invalidation event
    _eventBus.emit(CacheEvent(
      type: CacheEventType.invalidated,
      cacheKey: 'campaign_*',
      timestamp: DateTime.now(),
      source: 'RealtimeSyncService',
    ));

    // Invalidate related providers
    if (_providerContainer != null) {
      _invalidateCampaignProviders(event.campaignId);
    }

    // Update analytics if campaign completed or failed
    if (event.type == CampaignEventType.completed || 
        event.type == CampaignEventType.failed) {
      _eventBus.emit(AnalyticsEvent(
        type: AnalyticsEventType.dataUpdated,
        timestamp: DateTime.now(),
        source: 'RealtimeSyncService',
        metadata: {'trigger': 'campaign_${event.type.name}'},
      ));
    }
  }

  /// Handle template-related events
  void _handleTemplateEvent(TemplateEvent event) {
    logger.d('Handling template event: ${event.type}');
    
    // Invalidate template-related cache entries
    if (event.templateId != null) {
      _cacheManager.remove('template_by_id_${event.templateId}');
    }
    _cacheManager.clearPattern('template_');
    
    // Emit cache invalidation event
    _eventBus.emit(CacheEvent(
      type: CacheEventType.invalidated,
      cacheKey: 'template_*',
      timestamp: DateTime.now(),
      source: 'RealtimeSyncService',
    ));

    // Invalidate related providers
    if (_providerContainer != null) {
      _invalidateTemplateProviders();
    }
  }

  /// Handle database-related events
  void _handleDatabaseEvent(DatabaseEvent event) {
    logger.d('Handling database event: ${event.tableName} - ${event.type}');
    
    // Emit analytics update for data changes
    _eventBus.emit(AnalyticsEvent(
      type: AnalyticsEventType.dataUpdated,
      timestamp: DateTime.now(),
      source: 'RealtimeSyncService',
      metadata: {
        'table': event.tableName,
        'operation': event.type.name,
      },
    ));
  }

  /// Debounce events to prevent excessive updates
  void _debounceEvent(String key, VoidCallback callback, {Duration delay = const Duration(milliseconds: 500)}) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, callback);
  }

  /// Invalidate providers related to a cache key
  void _invalidateRelatedProviders(String? cacheKey) {
    if (cacheKey == null || _providerContainer == null) return;

    // Use a more robust provider invalidation system
    if (cacheKey.startsWith('client_')) {
      _providerContainer!.invalidate(allClientsProvider);
      _providerContainer!.invalidate(clientCompaniesProvider);
      _providerContainer!.invalidate(allClientsWithTagsProvider);
    } else if (cacheKey.startsWith('campaign_')) {
      _providerContainer!.invalidate(allCampaignsProvider);
      _providerContainer!.invalidate(campaignHealthProvider);
    } else if (cacheKey.startsWith('template_')) {
      _providerContainer!.invalidate(templatesProvider);
    } else if (cacheKey.startsWith('tag_')) {
      _providerContainer!.invalidate(allTagsProvider);
      _providerContainer!.invalidate(tagUsageStatsProvider);
      _providerContainer!.invalidate(allClientsWithTagsProvider);
    }
    
    // Always invalidate dashboard metrics as they depend on all data
    _providerContainer!.invalidate(dashboardMetricsProvider);
    _providerContainer!.invalidate(dashboardActivityProvider);
  }

  /// Invalidate campaign-related providers
  void _invalidateCampaignProviders(int? campaignId) {
    logger.d('Invalidating campaign providers${campaignId != null ? ' for campaign $campaignId' : ''}');
  }

  /// Invalidate template-related providers
  void _invalidateTemplateProviders() {
    logger.d('Invalidating template providers');
  }

  /// Emit an event through the event bus
  void emitEvent<T extends AppEvent>(T event) {
    _eventBus.emit(event);
  }

  /// Listen to events of a specific type
  Stream<T> on<T extends AppEvent>() {
    return _eventBus.on<T>();
  }

  /// Get all events stream
  Stream<AppEvent> get allEvents => _eventBus.allEvents;

  /// Get event bus statistics
  EventBusStats getEventBusStats() {
    return _eventBus.getStats();
  }

  /// Get sync service statistics
  RealtimeSyncStats getStats() {
    return RealtimeSyncStats(
      isInitialized: _isInitialized,
      activeSubscriptions: _subscriptions.length,
      activeDebounceTimers: _debounceTimers.length,
      eventBusStats: _eventBus.getStats(),
    );
  }

  /// Dispose the service
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _eventBus.dispose();
    _isInitialized = false;
    
    logger.i('RealtimeSyncService disposed');
  }
}

/// Statistics for the real-time sync service
class RealtimeSyncStats {
  final bool isInitialized;
  final int activeSubscriptions;
  final int activeDebounceTimers;
  final EventBusStats eventBusStats;

  const RealtimeSyncStats({
    required this.isInitialized,
    required this.activeSubscriptions,
    required this.activeDebounceTimers,
    required this.eventBusStats,
  });

  @override
  String toString() {
    return 'RealtimeSyncStats(initialized: $isInitialized, '
           'subscriptions: $activeSubscriptions, '
           'timers: $activeDebounceTimers, '
           'eventBus: $eventBusStats)';
  }
}
