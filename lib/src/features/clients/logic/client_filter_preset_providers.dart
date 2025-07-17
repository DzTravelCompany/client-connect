import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/client_filter_preset_dao.dart';
import '../data/client_filter_preset_model.dart';

// Filter preset DAO provider
final clientFilterPresetDaoProvider = Provider<ClientFilterPresetDao>((ref) => ClientFilterPresetDao());

// All filter presets provider
final clientFilterPresetsProvider = FutureProvider<List<ClientFilterPreset>>((ref) async {
  final dao = ref.watch(clientFilterPresetDaoProvider);
  return await dao.getAllPresets();
});

// Filter preset notifier for CRUD operations
final clientFilterPresetNotifierProvider = StateNotifierProvider<ClientFilterPresetNotifier, AsyncValue<void>>((ref) {
  return ClientFilterPresetNotifier(ref.watch(clientFilterPresetDaoProvider));
});

class ClientFilterPresetNotifier extends StateNotifier<AsyncValue<void>> {
  final ClientFilterPresetDao _dao;

  ClientFilterPresetNotifier(this._dao) : super(const AsyncValue.data(null));

  Future<void> savePreset(ClientFilterPreset preset) async {
    state = const AsyncValue.loading();
    
    try {
      if (preset.id == 0) {
        await _dao.savePreset(preset);
      } else {
        await _dao.updatePreset(preset);
      }
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deletePreset(int presetId) async {
    state = const AsyncValue.loading();
    
    try {
      await _dao.deletePreset(presetId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}