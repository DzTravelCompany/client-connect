import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/client_activity_dao.dart';
import '../data/client_activity_model.dart';

// Client Activity DAO provider
final clientActivityDaoProvider = Provider<ClientActivityDao>((ref) => ClientActivityDao());

// Client activities provider for a specific client
final clientActivitiesProvider = FutureProvider.family<List<ClientActivityModel>, int>((ref, clientId) async {
  final dao = ref.watch(clientActivityDaoProvider);
  return await dao.getClientActivities(clientId);
});

// Recent activities provider (across all clients)
final recentActivitiesProvider = FutureProvider<List<ClientActivityModel>>((ref) async {
  final dao = ref.watch(clientActivityDaoProvider);
  return await dao.getRecentActivities();
});

// Activity notifier for adding new activities
final clientActivityNotifierProvider = StateNotifierProvider<ClientActivityNotifier, AsyncValue<void>>((ref) {
  return ClientActivityNotifier(ref.watch(clientActivityDaoProvider));
});

class ClientActivityNotifier extends StateNotifier<AsyncValue<void>> {
  final ClientActivityDao _dao;

  ClientActivityNotifier(this._dao) : super(const AsyncValue.data(null));

  Future<void> addActivity({
    required int clientId,
    required ClientActivityType activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _dao.addActivity(
        clientId: clientId,
        activityType: activityType,
        description: description,
        metadata: metadata,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
