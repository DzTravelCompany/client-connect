import 'package:client_connect/src/core/models/database.dart';
import 'package:client_connect/src/features/clients/logic/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/tag_dao.dart';
import '../data/tag_model.dart';


// Tag DAO provider
final tagDaoProvider = Provider<TagDao>((ref) => TagDao());

// All tags stream provider
final allTagsProvider = StreamProvider<List<TagModel>>((ref) {
  final dao = ref.watch(tagDaoProvider);
  return dao.watchAllTags();
});

// Search tags provider
final searchTagsProvider = StreamProvider.family<List<TagModel>, String>((ref, searchTerm) {
  final dao = ref.watch(tagDaoProvider);
  return dao.searchTags(searchTerm);
});

// Tag by ID provider
final tagByIdProvider = FutureProvider.family<TagModel?, int>((ref, id) {
  final dao = ref.watch(tagDaoProvider);
  return dao.getTagById(id);
});

// Tags for client provider
final tagsForClientProvider = StreamProvider.family<List<TagModel>, int>((ref, clientId) {
  final dao = ref.watch(tagDaoProvider);
  return dao.watchTagsForClient(clientId);
});

// Client tags provider
final clientTagsProvider = StreamProvider.family<List<TagModel>, int>((ref, clientId) {
  final tagDao = ref.watch(tagDaoProvider);
  return tagDao.watchTagsForClient(clientId);
});

// Clients with tags provider
final clientsWithTagsProvider = StreamProvider.family<List<ClientWithTags>, List<int>?>((ref, tagIds) {
  final dao = ref.watch(tagDaoProvider);
  return dao.watchClientsWithTags(tagIds: tagIds);
});

// All clients with tags provider
final allClientsWithTagsProvider = StreamProvider<List<ClientWithTags>>((ref) {
  final dao = ref.watch(tagDaoProvider);
  return dao.watchAllClientsWithTags();
});

// Tag usage statistics provider
final tagUsageStatsProvider = FutureProvider<Map<int, int>>((ref) {
  final dao = ref.watch(tagDaoProvider);
  return dao.getTagUsageStats();
});

// Tag form state provider
final tagFormProvider = StateNotifierProvider<TagFormNotifier, TagFormState>((ref) {
  return TagFormNotifier(ref.watch(tagDaoProvider), ref);
});

// Tag management state provider
final tagManagementProvider = StateNotifierProvider<TagManagementNotifier, TagManagementState>((ref) {
  return TagManagementNotifier(ref.watch(tagDaoProvider), ref);
});

// Tag form state
class TagFormState {
  final bool isLoading;
  final String? error;
  final bool isSaved;

  const TagFormState({
    this.isLoading = false,
    this.error,
    this.isSaved = false,
  });

  TagFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSaved,
  }) {
    return TagFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

// Tag management state
class TagManagementState {
  final List<int> selectedClients;
  final List<int> selectedTags;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const TagManagementState({
    this.selectedClients = const [],
    this.selectedTags = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  TagManagementState copyWith({
    List<int>? selectedClients,
    List<int>? selectedTags,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return TagManagementState(
      selectedClients: selectedClients ?? this.selectedClients,
      selectedTags: selectedTags ?? this.selectedTags,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

// Tag form notifier
class TagFormNotifier extends StateNotifier<TagFormState> {
  final TagDao _dao;
  final Ref _ref;

  TagFormNotifier(this._dao, this._ref) : super(const TagFormState());

  Future<void> saveTag(TagModel tag) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      if (tag.id == 0) {
        // New tag
        await _dao.insertTag(TagsCompanion.insert(
          name: tag.name,
          color: tag.color,
          description: Value(tag.description),
        ));
      } else {
        // Update existing tag
        await _dao.updateTag(tag.id, TagsCompanion(
          name: Value(tag.name),
          color: Value(tag.color),
          description: Value(tag.description),
        ));
      }
      
      // Invalidate all tag-related providers
      _ref.invalidate(allTagsProvider);
      _ref.invalidate(tagUsageStatsProvider);
      if (tag.id != 0) {
        _ref.invalidate(tagByIdProvider(tag.id));
      }
      
      state = state.copyWith(isLoading: false, isSaved: true);
      
      // Reset saved state after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(isSaved: false);
        }
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void resetState() {
    state = const TagFormState();
  }
}

// Tag management notifier
class TagManagementNotifier extends StateNotifier<TagManagementState> {
  final TagDao _dao;
  final Ref _ref;

  TagManagementNotifier(this._dao, this._ref) : super(const TagManagementState());

  void selectClient(int clientId) {
    final selected = List<int>.from(state.selectedClients);
    if (selected.contains(clientId)) {
      selected.remove(clientId);
    } else {
      selected.add(clientId);
    }
    state = state.copyWith(selectedClients: selected);
  }

  void selectAllClients(List<int> clientIds) {
    state = state.copyWith(selectedClients: clientIds);
  }

  void clearSelectedClients() {
    state = state.copyWith(selectedClients: []);
  }

  void selectTag(int tagId) {
    final selected = List<int>.from(state.selectedTags);
    if (selected.contains(tagId)) {
      selected.remove(tagId);
    } else {
      selected.add(tagId);
    }
    state = state.copyWith(selectedTags: selected);
  }

  void clearSelectedTags() {
    state = state.copyWith(selectedTags: []);
  }

  Future<void> addTagsToSelectedClients() async {
    if (state.selectedClients.isEmpty || state.selectedTags.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      for (final tagId in state.selectedTags) {
        await _dao.addTagToMultipleClients(state.selectedClients, tagId);
      }

      // Invalidate all relevant providers
      _invalidateTagRelatedProviders();

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Tags added to ${state.selectedClients.length} clients',
        selectedClients: [],
        selectedTags: [],
      );

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(successMessage: null);
        }
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeTagsFromSelectedClients() async {
    if (state.selectedClients.isEmpty || state.selectedTags.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      for (final tagId in state.selectedTags) {
        await _dao.removeTagFromMultipleClients(state.selectedClients, tagId);
      }

      // Invalidate all relevant providers
      _invalidateTagRelatedProviders();

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Tags removed from ${state.selectedClients.length} clients',
        selectedClients: [],
        selectedTags: [],
      );

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(successMessage: null);
        }
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _invalidateTagRelatedProviders() {
    // Invalidate tag providers
    _ref.invalidate(allTagsProvider);
    _ref.invalidate(tagUsageStatsProvider);
    _ref.invalidate(allClientsWithTagsProvider);
    
    // Invalidate client providers that might show tags
    _ref.invalidate(allClientsProvider);
    
    // Invalidate specific client tag providers for affected clients
    for (final clientId in state.selectedClients) {
      _ref.invalidate(tagsForClientProvider(clientId));
      _ref.invalidate(clientTagsProvider(clientId));
    }
    
    // Invalidate clients with tags provider for affected tags
    for (final tagId in state.selectedTags) {
      _ref.invalidate(clientsWithTagsProvider([tagId]));
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}