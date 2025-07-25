import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Centralized event bus for real-time updates across the application
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final Map<Type, StreamController<dynamic>> _controllers = {};
  final Map<Type, List<StreamSubscription>> _subscriptions = {};
  final Queue<AppEvent> _eventHistory = Queue<AppEvent>();
  static const int _maxHistorySize = 1000;

  /// Emit an event to all listeners
  void emit<T extends AppEvent>(T event) {
    if (kDebugMode) {
      print('EventBus: Emitting ${T.toString()}: ${event.toString()}');
    }

    // Add to history
    _eventHistory.add(event);
    if (_eventHistory.length > _maxHistorySize) {
      _eventHistory.removeFirst();
    }

    // Get or create controller for this event type
    final controller = _controllers.putIfAbsent(
      T,
      () => StreamController<T>.broadcast(),
    ) as StreamController<T>;

    // Emit the event
    if (!controller.isClosed) {
      controller.add(event);
    }

    // Also emit to base AppEvent listeners
    if (T != AppEvent) {
      final baseController = _controllers.putIfAbsent(
        AppEvent,
        () => StreamController<AppEvent>.broadcast(),
      ) as StreamController<AppEvent>;

      if (!baseController.isClosed) {
        baseController.add(event);
      }
    }
  }

  /// Listen to events of a specific type
  Stream<T> on<T extends AppEvent>() {
    final controller = _controllers.putIfAbsent(
      T,
      () => StreamController<T>.broadcast(),
    ) as StreamController<T>;

    return controller.stream;
  }

  /// Listen to all events
  Stream<AppEvent> get allEvents {
    final controller = _controllers.putIfAbsent(
      AppEvent,
      () => StreamController<AppEvent>.broadcast(),
    ) as StreamController<AppEvent>;

    return controller.stream;
  }

  /// Get recent events of a specific type
  List<T> getRecentEvents<T extends AppEvent>({int limit = 50}) {
    return _eventHistory
        .whereType<T>()
        .cast<T>()
        .take(limit)
        .toList()
        .reversed
        .toList();
  }

  /// Clear event history
  void clearHistory() {
    _eventHistory.clear();
  }

  /// Dispose all controllers and subscriptions
  void dispose() {
    for (final subscriptions in _subscriptions.values) {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    }
    _subscriptions.clear();

    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _eventHistory.clear();
  }

  /// Get statistics about the event bus
  EventBusStats getStats() {
    return EventBusStats(
      activeControllers: _controllers.length,
      totalSubscriptions: _subscriptions.values
          .fold(0, (sum, subs) => sum + subs.length),
      eventHistorySize: _eventHistory.length,
      eventTypes: _controllers.keys.map((type) => type.toString()).toList(),
    );
  }
}

/// Base class for all application events
abstract class AppEvent {
  final DateTime timestamp;
  final String source;
  final Map<String, dynamic>? metadata;

  const AppEvent({
    required this.timestamp,
    required this.source,
    this.metadata,
  });

  @override
  String toString() {
    return '$runtimeType(source: $source, timestamp: $timestamp)';
  }
}

/// Client-related events
class ClientEvent extends AppEvent {
  final int? clientId;
  final ClientEventType type;

  const ClientEvent({
    required this.type,
    this.clientId,
    required super.timestamp,
    required super.source,
    super.metadata,
  });
}

enum ClientEventType {
  created,
  updated,
  deleted,
  bulkUpdated,
  bulkDeleted,
}

/// Campaign-related events
class CampaignEvent extends AppEvent {
  final int campaignId;
  final CampaignEventType type;

  const CampaignEvent({
    required this.campaignId,
    required this.type,
    required super.timestamp,
    required super.source,
    super.metadata,
  });
}

enum CampaignEventType {
  created,
  updated,
  started,
  paused,
  resumed,
  completed,
  failed,
  cancelled,
  deleted,
  progressUpdated,
  messageStatusChanged,
}

class TagEvent extends AppEvent {
  final TagEventType type;
  final int? tagId;

  const TagEvent({
    required this.type,
    this.tagId,
    required super.timestamp,
    required super.source,
    super.metadata,
  });
}

enum TagEventType { created, updated, deleted, assigned, unassigned }

/// Template-related events
class TemplateEvent extends AppEvent {
  final int? templateId;
  final TemplateEventType type;

  const TemplateEvent({
    required this.type,
    this.templateId,
    required super.timestamp,
    required super.source,
    super.metadata,
  });
}

enum TemplateEventType {
  created,
  updated,
  deleted,
  duplicated,
  bulkDeleted,
}

/// Database-related events
class DatabaseEvent extends AppEvent {
  final String tableName;
  final DatabaseEventType type;
  final List<int>? affectedIds;

  const DatabaseEvent({
    required this.tableName,
    required this.type,
    this.affectedIds,
    required super.timestamp,
    required super.source,
    super.metadata,
  });
}

enum DatabaseEventType {
  insert,
  update,
  delete,
  bulkInsert,
  bulkUpdate,
  bulkDelete,
}

/// Cache-related events
class CacheEvent extends AppEvent {
  final String? cacheKey;
  final CacheEventType type;

  const CacheEvent({
    required this.type,
    this.cacheKey,
    required super.timestamp,
    required super.source,
    super.metadata,
  });
}

enum CacheEventType {
  hit,
  miss,
  invalidated,
  cleared,
  expired,
}

/// Analytics-related events
class AnalyticsEvent extends AppEvent {
  final AnalyticsEventType type;

  const AnalyticsEvent({
    required this.type,
    required super.timestamp,
    required super.source,
    super.metadata,
  });
}

enum AnalyticsEventType {
  dataUpdated,
  reportGenerated,
  metricsCalculated,
}

/// System-related events
class SystemEvent extends AppEvent {
  final SystemEventType type;

  const SystemEvent({
    required this.type,
    required super.timestamp,
    required super.source,
    super.metadata,
  });
}

enum SystemEventType {
  startup,
  shutdown,
  error,
  warning,
  backgroundTaskStarted,
  backgroundTaskCompleted,
}

/// Event bus statistics
class EventBusStats {
  final int activeControllers;
  final int totalSubscriptions;
  final int eventHistorySize;
  final List<String> eventTypes;

  const EventBusStats({
    required this.activeControllers,
    required this.totalSubscriptions,
    required this.eventHistorySize,
    required this.eventTypes,
  });

  @override
  String toString() {
    return 'EventBusStats(controllers: $activeControllers, '
           'subscriptions: $totalSubscriptions, '
           'history: $eventHistorySize, '
           'types: ${eventTypes.length})';
  }
}
