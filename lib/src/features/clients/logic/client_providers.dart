import 'package:client_connect/constants.dart';
import 'package:client_connect/src/core/models/database.dart';
import 'package:client_connect/src/core/widgets/paginated_list_view.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:client_connect/src/features/campaigns/logic/campaign_providers.dart';
import 'package:client_connect/src/features/clients/data/client_activity_dao.dart';
import 'package:client_connect/src/features/clients/data/client_activity_model.dart';
import 'package:client_connect/src/features/clients/logic/client_activity_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/client_dao.dart';
import '../data/client_model.dart';
import 'package:drift/drift.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../../core/realtime/reactive_providers.dart';
import '../../../core/realtime/event_bus.dart';


// Client DAO provider
final clientDaoProvider = Provider<ClientDao>((ref) => ClientDao());

// Real-time client provider without circular event emission
final allClientsProvider = StreamProvider<List<ClientModel>>((ref) {
  final dao = ref.watch(clientDaoProvider);
  
  // Just return the stream without emitting events that cause circular dependencies
  return dao.watchAllClients();
});

// Search clients provider
final searchClientsProvider = StreamProvider.family<List<ClientModel>, String>((ref, searchTerm) {
  final dao = ref.watch(clientDaoProvider);
  return dao.searchClients(searchTerm);
});

final clientRefreshTriggerProvider = StateProvider<int>((ref) => 0);

final paginatedClientsProvider = StreamProvider.autoDispose.family<PaginatedResult<ClientModel>, PaginatedClientsParams>((ref, params) {
  final dao = ref.watch(clientDaoProvider);
  ref.watch(clientRefreshTriggerProvider);
  return dao.watchPaginatedClients(
    page: params.page,
    limit: params.limit,
    searchTerm: params.searchTerm,
    tags: params.tags,
    company: params.company,
    dateRange: params.dateRange,
    sortBy: params.sortBy,
    sortAscending: params.sortAscending,
  );
});

// Client by ID provider
final clientByIdProvider = StreamProvider.family<ClientModel?, int>((ref, id) {
  final dao = ref.watch(clientDaoProvider);
  return dao.watchClientById(id);
});

// Client form state provider
final clientFormProvider = StateNotifierProvider<ClientFormNotifier, ClientFormState>((ref) {
  return ClientFormNotifier(ref.watch(clientDaoProvider), ref);
});

// Client companies provider - gets all unique companies from clients
final clientCompaniesProvider = FutureProvider<List<String>>((ref) async {
  final dao = ref.watch(clientDaoProvider);
  ref.watch(clientRefreshTriggerProvider);
  return await dao.getAllCompanies();
});

// Client campaigns provider - gets campaigns for a specific client
final clientCampaignsProvider = FutureProvider.family<List<CampaignModel>, int>((ref, clientId) async {
  final dao = ref.watch(campaignDaoProvider);
  return await dao.getCampaignsByClientId(clientId);
});

// Bulk operations notifier
final clientBulkOperationsProvider = StateNotifierProvider<ClientBulkOperationsNotifier, ClientBulkOperationsState>((ref) {
  return ClientBulkOperationsNotifier(ref.watch(clientDaoProvider), ref.watch(clientActivityDaoProvider));
});

// Filter persistence provider
final clientFilterPersistenceProvider = StateNotifierProvider<ClientFilterPersistenceNotifier, ClientFilterPersistenceState>((ref) {
  return ClientFilterPersistenceNotifier();
});

// Client form state
class ClientFormState {
  final bool isLoading;
  final String? error;
  final bool isSaved;

  const ClientFormState({
    this.isLoading = false,
    this.error,
    this.isSaved = false,
  });

  ClientFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSaved,
  }) {
    return ClientFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

// Enhanced client form notifier with real-time events
class ClientFormNotifier extends StateNotifier<ClientFormState> with RealtimeProviderMixin<ClientFormState> {
  final ClientDao _dao;
  final Ref _ref;

  ClientFormNotifier(this._dao, this._ref) : super(const ClientFormState()) {
    initializeEventListeners();
  }
  
  void initializeEventListeners() {
    // Listen to client events from other sources
    listenToEvents<ClientEvent>((event) {
      if (event.type == ClientEventType.updated || 
          event.type == ClientEventType.created ||
          event.type == ClientEventType.deleted ||
          event.type == ClientEventType.bulkDeleted ||
          event.type == ClientEventType.bulkUpdated) {
        // Trigger refresh by incrementing the counter
        _triggerRefresh();
      }
    });
  }

  void _triggerRefresh() {
    final currentValue = _ref.read(clientRefreshTriggerProvider);
    _ref.read(clientRefreshTriggerProvider.notifier).state = currentValue + 1;
  }

  Future<int?> saveClient(ClientModel client) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      int clientId;
      
      if (client.id == 0) {
        // Creating new client
        clientId = await _dao.insertClient(ClientsCompanion.insert(
          firstName: client.firstName,
          lastName: client.lastName,
          email: Value(client.email),
          phone: Value(client.phone),
          company: Value(client.company),
          jobTitle: Value(client.jobTitle),
          address: Value(client.address),
          notes: Value(client.notes),
        ));
        
        // Emit real-time event after successful creation
        emitEvent(ClientEvent(
          type: ClientEventType.created,
          clientId: clientId,
          timestamp: DateTime.now(),
          source: 'ClientFormNotifier',
          metadata: {'client_name': client.fullName},
        ));
      } else {
        // Updating existing client
        clientId = client.id;
        await _dao.updateClient(client.id, ClientsCompanion(
          firstName: Value(client.firstName),
          lastName: Value(client.lastName),
          email: Value(client.email),
          phone: Value(client.phone),
          company: Value(client.company),
          jobTitle: Value(client.jobTitle),
          address: Value(client.address),
          notes: Value(client.notes),
        ));
        
        // Emit real-time event after successful update
        emitEvent(ClientEvent(
          type: ClientEventType.updated,
          clientId: client.id,
          timestamp: DateTime.now(),
          source: 'ClientFormNotifier',
          metadata: {'client_name': client.fullName},
        ));
      }
      
      state = state.copyWith(isLoading: false, isSaved: true);
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(isSaved: false);
        }
      });
      
      return clientId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void resetState() {
    state = const ClientFormState();
  }
}

// Bulk operations state
class ClientBulkOperationsState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ClientBulkOperationsState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ClientBulkOperationsState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ClientBulkOperationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Bulk operations notifier
class ClientBulkOperationsNotifier extends StateNotifier<ClientBulkOperationsState> {
  final ClientDao _clientDao;
  final ClientActivityDao _activityDao;

  ClientBulkOperationsNotifier(this._clientDao, this._activityDao) : super(const ClientBulkOperationsState());

  Future<void> bulkDeleteClients(List<int> clientIds) async {
    if (clientIds.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final deletedCount = await _clientDao.bulkDeleteClients(clientIds);
      
      // Log activity for each deleted client
      for (final clientId in clientIds) {
        await _activityDao.addActivity(
          clientId: clientId,
          activityType: ClientActivityType.updated,
          description: 'Client deleted',
        );
      }
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Successfully deleted $deletedCount clients',
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

  Future<void> bulkTagClients(List<int> clientIds, List<String> tagNames) async {
    if (clientIds.isEmpty || tagNames.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // This would require implementing tag assignment logic
      // For now, just log the activity
      for (final clientId in clientIds) {
        await _activityDao.addActivity(
          clientId: clientId,
          activityType: ClientActivityType.tagAdded,
          description: 'Tags added: ${tagNames.join(', ')}',
          metadata: {'tags': tagNames},
        );
      }
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Successfully tagged ${clientIds.length} clients',
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

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// Filter persistence state
class ClientFilterPersistenceState {
  final String? searchTerm;
  final List<String> selectedTags;
  final String? selectedCompany;
  final DateTimeRange? dateRange;
  final String sortBy;
  final bool sortAscending;

  const ClientFilterPersistenceState({
    this.searchTerm,
    this.selectedTags = const [],
    this.selectedCompany,
    this.dateRange,
    this.sortBy = 'name',
    this.sortAscending = true,
  });

  ClientFilterPersistenceState copyWith({
    String? searchTerm,
    List<String>? selectedTags,
    String? selectedCompany,
    DateTimeRange? dateRange,
    String? sortBy,
    bool? sortAscending,
  }) {
    return ClientFilterPersistenceState(
      searchTerm: searchTerm ?? this.searchTerm,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedCompany: selectedCompany ?? this.selectedCompany,
      dateRange: dateRange ?? this.dateRange,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

// Filter persistence notifier
class ClientFilterPersistenceNotifier extends StateNotifier<ClientFilterPersistenceState> {
  ClientFilterPersistenceNotifier() : super(const ClientFilterPersistenceState()) {
    _loadPersistedFilters();
  }

  void updateFilters({
    String? searchTerm,
    List<String>? selectedTags,
    String? selectedCompany,
    DateTimeRange? dateRange,
    String? sortBy,
    bool? sortAscending,
  }) {
    state = state.copyWith(
      searchTerm: searchTerm,
      selectedTags: selectedTags,
      selectedCompany: selectedCompany,
      dateRange: dateRange,
      sortBy: sortBy,
      sortAscending: sortAscending,
    );
    _persistFilters();
  }

  void clearFilters() {
    state = const ClientFilterPersistenceState();
    _persistFilters();
  }

  void _loadPersistedFilters() {
    // TODO: Implement loading from shared preferences or local storage
    // For now, this is a placeholder
    logger.i('TODO: Implement loading from shared preferences or local storage');
  }

  void _persistFilters() {
    // TODO: Implement saving to shared preferences or local storage
    // For now, this is a placeholder
    logger.i('TODO: Implement saving to shared preferences or local storage');
  }
}

// Parameters class for paginated clients
class PaginatedClientsParams {
  final int page;
  final int limit;
  final String? searchTerm;
  final List<String>? tags;
  final String? company;
  final DateTimeRange? dateRange;
  final String sortBy;
  final bool sortAscending;

  const PaginatedClientsParams({
    required this.page,
    required this.limit,
    this.searchTerm,
    this.tags,
    this.company,
    this.dateRange,
    this.sortBy = 'name',
    this.sortAscending = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginatedClientsParams &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          limit == other.limit &&
          searchTerm == other.searchTerm &&
          _listEquals(tags, other.tags) &&
          company == other.company &&
          dateRange == other.dateRange &&
          sortBy == other.sortBy &&
          sortAscending == other.sortAscending;

  @override
  int get hashCode => 
      page.hashCode ^ 
      limit.hashCode ^ 
      searchTerm.hashCode ^ 
      (tags?.join(',').hashCode ?? 0) ^
      company.hashCode ^ 
      dateRange.hashCode ^
      sortBy.hashCode ^
      sortAscending.hashCode;

  // Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}