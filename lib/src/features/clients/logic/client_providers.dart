import 'package:client_connect/src/core/models/database.dart';
import 'package:client_connect/src/core/widgets/paginated_list_view.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:client_connect/src/features/campaigns/logic/campaign_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/client_dao.dart';
import '../data/client_model.dart';
import 'package:drift/drift.dart';


// Client DAO provider
final clientDaoProvider = Provider<ClientDao>((ref) => ClientDao());

// All clients stream provider
final allClientsProvider = StreamProvider<List<ClientModel>>((ref) {
  final dao = ref.watch(clientDaoProvider);
  return dao.watchAllClients();
});

// Search clients provider
final searchClientsProvider = StreamProvider.family<List<ClientModel>, String>((ref, searchTerm) {
  final dao = ref.watch(clientDaoProvider);
  return dao.searchClients(searchTerm);
});

final paginatedClientsProvider = Provider.family<Future<PaginatedResult<ClientModel>>, PaginatedClientsParams>((ref, params) {
  final dao = ref.watch(clientDaoProvider);
  return dao.getPaginatedClients(
    page: params.page,
    limit: params.limit,
    searchTerm: params.searchTerm,
  );
});


// Client by ID provider
final clientByIdProvider = FutureProvider.family<ClientModel?, int>((ref, id) {
  final dao = ref.watch(clientDaoProvider);
  return dao.getClientById(id);
});

// Client form state provider
final clientFormProvider = StateNotifierProvider<ClientFormNotifier, ClientFormState>((ref) {
  return ClientFormNotifier(ref.watch(clientDaoProvider));
});

// Client companies provider - gets all unique companies from clients
final clientCompaniesProvider = FutureProvider<List<String>>((ref) async {
  final dao = ref.watch(clientDaoProvider);
  return await dao.getAllCompanies();
});

// Client campaigns provider - gets campaigns for a specific client
final clientCampaignsProvider = FutureProvider.family<List<CampaignModel>, int>((ref, clientId) async {
  final dao = ref.watch(campaignDaoProvider);
  return await dao.getCampaignsByClientId(clientId);
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

// Client form notifier
class ClientFormNotifier extends StateNotifier<ClientFormState> {
  final ClientDao _dao;

  ClientFormNotifier(this._dao) : super(const ClientFormState());

  Future<void> saveClient(ClientModel client) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      if (client.id == 0) {
        // New client
        await _dao.insertClient(ClientsCompanion.insert(
          firstName: client.firstName,
          lastName: client.lastName,
          email: Value(client.email),
          phone: Value(client.phone),
          company: Value(client.company),
          jobTitle: Value(client.jobTitle),
          address: Value(client.address),
          notes: Value(client.notes),
        ));
      } else {
        // Update existing client
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
    state = const ClientFormState();
  }
}

// Parameters class for paginated clients
class PaginatedClientsParams {
  final int page;
  final int limit;
  final String? searchTerm;

  const PaginatedClientsParams({
    required this.page,
    required this.limit,
    this.searchTerm,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginatedClientsParams &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          limit == other.limit &&
          searchTerm == other.searchTerm;

  @override
  int get hashCode => page.hashCode ^ limit.hashCode ^ searchTerm.hashCode;
}