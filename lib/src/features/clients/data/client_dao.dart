import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/models/database.dart';
import '../../../core/services/database_service.dart';
import '../../../core/widgets/paginated_list_view.dart';
import 'client_model.dart';
import '../../../core/cache/cached_repository.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/realtime/realtime_sync_service.dart';
import '../../../core/realtime/event_bus.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ClientDao extends CachedRepository {
  final AppDatabase _db = DatabaseService.instance.database;
  final RealtimeSyncService _syncService = RealtimeSyncService();

  // Watch all clients (reactive stream) - kept for backward compatibility
  Stream<List<ClientModel>> watchAllClients() {
    return _db.select(_db.clients).watch().map(
      (rows) => rows.map((row) => _clientFromRow(row)).toList(),
    );
  }

  // New paginated method for better performance
  Stream<PaginatedResult<ClientModel>> watchPaginatedClients({
    int page = 1,
    int limit = 50,
    String? searchTerm,
    List<String>? tags,
    String? company,
    DateTimeRange? dateRange,
    String sortBy = 'name',
    bool sortAscending = true,
  }) {
    final offset = (page - 1) * limit;

    // Build base query
    var query = _db.select(_db.clients);

    // Add search filter if provided
    if (searchTerm != null && searchTerm.isNotEmpty) {
      query = query
        ..where((c) =>
            c.firstName.contains(searchTerm) |
            c.lastName.contains(searchTerm) |
            c.email.contains(searchTerm) |
            c.company.contains(searchTerm));
    }

    // Add company filter if provided
    if (company != null && company.isNotEmpty) {
      query = query..where((c) => c.company.equals(company));
    }

    // Add date range filter if provided
    if (dateRange != null) {
      query = query
        ..where((c) =>
            c.createdAt.isBiggerOrEqualValue(dateRange.start) &
            c.createdAt.isSmallerOrEqualValue(dateRange.end));
    }

    // Add ordering
    switch (sortBy.toLowerCase()) {
      case 'company':
        query = query
          ..orderBy([(c) => OrderingTerm(expression: c.company, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc)]);
        break;
      case 'created':
        query = query
          ..orderBy([(c) => OrderingTerm(expression: c.createdAt, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc)]);
        break;
      case 'updated':
        query = query
          ..orderBy([(c) => OrderingTerm(expression: c.updatedAt, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc)]);
        break;
      default: // name
        query = query
          ..orderBy([
            (c) => OrderingTerm(expression: c.firstName, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc),
            (c) => OrderingTerm(expression: c.lastName, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc),
          ]);
    }

    final countQuery = _db.selectOnly(_db.clients)
      ..addColumns([_db.clients.id.count()]);
    if (searchTerm != null && searchTerm.isNotEmpty) {
      countQuery.where(_db.clients.firstName.contains(searchTerm) |
          _db.clients.lastName.contains(searchTerm) |
          _db.clients.email.contains(searchTerm) |
          _db.clients.company.contains(searchTerm));
    }
    if (company != null && company.isNotEmpty) {
      countQuery.where(_db.clients.company.equals(company));
    }
    if (dateRange != null) {
      countQuery.where(_db.clients.createdAt.isBiggerOrEqualValue(dateRange.start) &
          _db.clients.createdAt.isSmallerOrEqualValue(dateRange.end));
    }

    final resultsStream = (query..limit(limit, offset: offset)).watch();
    final countStream = countQuery.map((row) => row.read(_db.clients.id.count()) ?? 0).watchSingle();

    return Rx.combineLatest2(resultsStream, countStream, (clients, totalCount) {
      return PaginatedResult<ClientModel>(
        items: clients.map((row) => _clientFromRow(row)).toList(),
        hasMore: offset + clients.length < totalCount,
        totalCount: totalCount,
      );
    });
  }

  // Get client by ID
  Future<ClientModel?> getClientById(int id) async {
    final cacheKey = CacheKeys.clientById(id);
  
    return await getCached(
      cacheKey,
      () async {
        final query = _db.select(_db.clients)..where((c) => c.id.equals(id));
        final row = await query.getSingleOrNull();
        return row != null ? _clientFromRow(row) : null;
      },
      ttl: CacheManager.defaultTtl, // Cache for 5 minutes
    );
  }

  // Watch client by ID
  Stream<ClientModel?> watchClientById(int id) {
    final query = _db.select(_db.clients)..where((c) => c.id.equals(id));
    return query.watchSingleOrNull().map((row) => row != null ? _clientFromRow(row) : null);
  }

  // Insert new client - ENHANCED WITH EVENT EMISSION
  Future<int> insertClient(ClientsCompanion client) async {
    final result = await _db.into(_db.clients).insert(client);
  
    // Emit real-time event
    _syncService.emitEvent(ClientEvent(
      type: ClientEventType.created,
      clientId: result,
      timestamp: DateTime.now(),
      source: 'ClientDao.insertClient',
      metadata: {
        'firstName': client.firstName.value,
        'lastName': client.lastName.value,
        'email': client.email.value,
      },
    ));

    // Invalidate paginated cache entries
    invalidateCache(CacheKeys.clientPrefix);
    invalidateCache(CacheKeys.clientCompanies);
  
    return result;
  }

  // Update existing client - ENHANCED WITH EVENT EMISSION
  Future<bool> updateClient(int id, ClientsCompanion client) async {
    final query = _db.update(_db.clients)..where((c) => c.id.equals(id));
    final updatedRows = await query.write(client.copyWith(
      updatedAt: Value(DateTime.now()),
    ));
  
    if (updatedRows > 0) {
      // Emit real-time event
      _syncService.emitEvent(ClientEvent(
        type: ClientEventType.updated,
        clientId: id,
        timestamp: DateTime.now(),
        source: 'ClientDao.updateClient',
        metadata: {
          'updatedFields': _getUpdatedFields(client),
        },
      ));

      // Clear specific client cache and paginated results
      clearCacheEntry(CacheKeys.clientById(id));
      invalidateCache(CacheKeys.clientPrefix);
      invalidateCache(CacheKeys.clientCompanies);
    }
  
    return updatedRows > 0;
  }

  // Delete client - ENHANCED WITH EVENT EMISSION
  Future<bool> deleteClient(int id) async {
    // Get client data before deletion for event metadata
    final clientData = await getClientById(id);
    
    final query = _db.delete(_db.clients)..where((c) => c.id.equals(id));
    final deletedRows = await query.go();
  
    if (deletedRows > 0) {
      // Emit real-time event
      _syncService.emitEvent(ClientEvent(
        type: ClientEventType.deleted,
        clientId: id,
        timestamp: DateTime.now(),
        source: 'ClientDao.deleteClient',
        metadata: {
          'deletedClient': clientData != null ? {
            'firstName': clientData.firstName,
            'lastName': clientData.lastName,
            'email': clientData.email,
          } : null,
        },
      ));

      // Clear specific client cache and paginated results
      clearCacheEntry(CacheKeys.clientById(id));
      invalidateCache(CacheKeys.clientPrefix);
      invalidateCache(CacheKeys.clientCompanies);
    }
  
    return deletedRows > 0;
  }

  // Search clients by name or email - kept for backward compatibility
  Stream<List<ClientModel>> searchClients(String searchTerm) {
    final query = _db.select(_db.clients)
      ..where((c) => 
        c.firstName.contains(searchTerm) |
        c.lastName.contains(searchTerm) |
        c.email.contains(searchTerm)
      );
    
    return query.watch().map(
      (rows) => rows.map((row) => _clientFromRow(row)).toList(),
    );
  }

  Future<List<String>> getAllCompanies() async {
    final cacheKey = CacheKeys.clientCompanies;
    
    return await getCached(
      cacheKey,
      () async {
        final query = _db.selectOnly(_db.clients)
          ..addColumns([_db.clients.company])
          ..where(_db.clients.company.isNotNull() & _db.clients.company.isNotValue(''))
          ..groupBy([_db.clients.company])
          ..orderBy([OrderingTerm.asc(_db.clients.company)]);
        
        final results = await query.get();
        return results
            .map((row) => row.read(_db.clients.company) ?? '')
            .where((company) => company.isNotEmpty)
            .toList();
      },
      ttl: CacheManager.defaultTtl, // Cache for 5 minutes
    );
  }

  // Bulk delete clients - ENHANCED WITH EVENT EMISSION
  Future<int> bulkDeleteClients(List<int> clientIds) async {
    if (clientIds.isEmpty) return 0;
    
    // Get client data before deletion for event metadata
    final clientsData = await getClientsByIds(clientIds);
    
    final query = _db.delete(_db.clients)
      ..where((c) => c.id.isIn(clientIds));
    
    final deletedRows = await query.go();
    
    if (deletedRows > 0) {
      // Emit real-time event
      _syncService.emitEvent(ClientEvent(
        type: ClientEventType.bulkDeleted,
        timestamp: DateTime.now(),
        source: 'ClientDao.bulkDeleteClients',
        metadata: {
          'deletedCount': deletedRows,
          'clientIds': clientIds,
          'deletedClients': clientsData.map((c) => {
            'id': c.id,
            'firstName': c.firstName,
            'lastName': c.lastName,
            'email': c.email,
          }).toList(),
        },
      ));

      // Clear cache for all affected clients
      for (final id in clientIds) {
        clearCacheEntry(CacheKeys.clientById(id));
      }
      invalidateCache(CacheKeys.clientPrefix);
      invalidateCache(CacheKeys.clientCompanies);
    }
    
    return deletedRows;
  }

  // Bulk update clients - ENHANCED WITH EVENT EMISSION
  Future<int> bulkUpdateClients(
    List<int> clientIds,
    ClientsCompanion updates,
  ) async {
    if (clientIds.isEmpty) return 0;
    
    final query = _db.update(_db.clients)
      ..where((c) => c.id.isIn(clientIds));
    
    final updatedRows = await query.write(updates.copyWith(
      updatedAt: Value(DateTime.now()),
    ));
    
    if (updatedRows > 0) {
      // Emit real-time event
      _syncService.emitEvent(ClientEvent(
        type: ClientEventType.bulkUpdated,
        timestamp: DateTime.now(),
        source: 'ClientDao.bulkUpdateClients',
        metadata: {
          'updatedCount': updatedRows,
          'clientIds': clientIds,
          'updatedFields': _getUpdatedFields(updates),
        },
      ));

      // Clear cache for all affected clients
      for (final id in clientIds) {
        clearCacheEntry(CacheKeys.clientById(id));
      }
      invalidateCache(CacheKeys.clientPrefix);
      invalidateCache(CacheKeys.clientCompanies);
    }
    
    return updatedRows;
  }

  // Get clients by IDs (for bulk operations)
  Future<List<ClientModel>> getClientsByIds(List<int> clientIds) async {
    if (clientIds.isEmpty) return [];
    
    final query = _db.select(_db.clients)
      ..where((c) => c.id.isIn(clientIds));
    
    final results = await query.get();
    return results.map((row) => _clientFromRow(row)).toList();
  }

  // Helper method to extract updated fields from ClientsCompanion
  Map<String, dynamic> _getUpdatedFields(ClientsCompanion companion) {
    final fields = <String, dynamic>{};
    
    if (companion.firstName.present) fields['firstName'] = companion.firstName.value;
    if (companion.lastName.present) fields['lastName'] = companion.lastName.value;
    if (companion.email.present) fields['email'] = companion.email.value;
    if (companion.phone.present) fields['phone'] = companion.phone.value;
    if (companion.company.present) fields['company'] = companion.company.value;
    if (companion.jobTitle.present) fields['jobTitle'] = companion.jobTitle.value;
    if (companion.address.present) fields['address'] = companion.address.value;
    if (companion.notes.present) fields['notes'] = companion.notes.value;
    
    return fields;
  }

  // Helper method to convert database row to ClientModel
  ClientModel _clientFromRow(Client row) {
    return ClientModel(
      id: row.id,
      firstName: row.firstName,
      lastName: row.lastName,
      email: row.email,
      phone: row.phone,
      company: row.company,
      jobTitle: row.jobTitle,
      address: row.address,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

   // New method to get client tags for a specific client
  Future<List<String>> getClientTags(int clientId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(_db.clientTags, _db.clientTags.tagId.equalsExp(_db.tags.id)),
    ])..where(_db.clientTags.clientId.equals(clientId));
    
    final results = await query.get();
    return results.map((result) => result.readTable(_db.tags).name).toList();
  }

  // New method to get clients by tag names
  Future<List<ClientModel>> getClientsByTags(List<String> tagNames) async {
    if (tagNames.isEmpty) return [];
    
    final query = _db.select(_db.clients).join([
      innerJoin(_db.clientTags, _db.clientTags.clientId.equalsExp(_db.clients.id)),
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.clientTags.tagId)),
    ])..where(_db.tags.name.isIn(tagNames))
      ..groupBy([_db.clients.id]);
    
    final results = await query.get();
    return results.map((result) => _clientFromRow(result.readTable(_db.clients))).toList();
  }
}