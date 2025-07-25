import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'event_bus.dart';
import 'realtime_sync_service.dart';

/// Enhanced provider that automatically refreshes based on events
class ReactiveProvider<T> {
  final FutureOr<T> Function(Ref ref) _provider;
  final List<Type> _eventTypes;
  final Duration _debounceTime;
  
  ReactiveProvider(
    this._provider,
    this._eventTypes, {
    Duration debounceTime = const Duration(milliseconds: 300),
  }) : _debounceTime = debounceTime;

  /// Create a Riverpod provider that reacts to events
  StreamProvider<T> createProvider() {
    return StreamProvider<T>((ref) {
      final syncService = RealtimeSyncService();
      
      // Create initial stream with the provider value
      final initialStream = Stream.fromFuture(
        Future.microtask(() async => await _provider(ref))
      );
      
      // Create event streams for each event type
      final eventStreams = _eventTypes.map((eventType) {
        return syncService.allEvents
            .where((event) => event.runtimeType == eventType)
            .debounceTime(_debounceTime)
            .asyncMap((_) async => await _provider(ref));
      });
      
      // Merge all streams
      return Rx.merge([initialStream, ...eventStreams]).distinct();
    });
  }
}

/// Mixin for providers that need real-time updates
mixin RealtimeProviderMixin<T> on StateNotifier<T> {
  final RealtimeSyncService _syncService = RealtimeSyncService();
  final List<StreamSubscription> _subscriptions = [];

  /// Listen to specific event types and update state
  void listenToEvents<E extends AppEvent>(
    void Function(E event) onEvent, {
    Duration debounce = const Duration(milliseconds: 300),
  }) {
    final subscription = _syncService
        .on<E>()
        .debounceTime(debounce)
        .listen(onEvent);
    
    _subscriptions.add(subscription);
  }

  /// Emit an event
  void emitEvent<E extends AppEvent>(E event) {
    _syncService.emitEvent(event);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}

/// Enhanced StateNotifier with real-time capabilities
abstract class RealtimeStateNotifier<T> extends StateNotifier<T> with RealtimeProviderMixin<T> {
  RealtimeStateNotifier(super.state);

  /// Override this to handle specific events
  void handleEvent(AppEvent event) {}

  /// Initialize event listeners
  void initializeEventListeners() {
    listenToEvents<AppEvent>((event) {
      handleEvent(event);
    });
  }
}

/// Provider for real-time event stream
final realtimeEventStreamProvider = StreamProvider<AppEvent>((ref) {
  return RealtimeSyncService().allEvents;
});

/// Provider for specific event types
final eventStreamProvider = StreamProvider.family<AppEvent, Type>((ref, eventType) {
  return RealtimeSyncService().allEvents
      .where((event) => event.runtimeType == eventType);
});

/// Provider for event bus statistics
final eventBusStatsProvider = StreamProvider<EventBusStats>((ref) {
  return Stream.periodic(const Duration(seconds: 5), (_) {
    return RealtimeSyncService().getEventBusStats();
  });
});

/// Provider for sync service statistics
final syncServiceStatsProvider = StreamProvider<RealtimeSyncStats>((ref) {
  return Stream.periodic(const Duration(seconds: 5), (_) {
    return RealtimeSyncService().getStats();
  });
});