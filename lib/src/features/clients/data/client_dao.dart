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
    String? jobTitle, // Added jobTitle parameter
    DateTimeRange? dateRange,
    String sortBy = 'name',
    bool sortAscending = true,
  }) {
    return _buildPaginatedClientsQuery(
      page: page,
      limit: limit,
      searchTerm: searchTerm,
      tags: tags,
      company: company,
      jobTitle: jobTitle, // Pass jobTitle parameter
      dateRange: dateRange,
      sortBy: sortBy,
      sortAscending: sortAscending,
    );
  }

  Stream<PaginatedResult<ClientModel>> _buildPaginatedClientsQuery({
    required int page,
    required int limit,
    String? searchTerm,
    List<String>? tags,
    String? company,
    String? jobTitle, // Added jobTitle parameter
    DateTimeRange? dateRange,
    String sortBy = 'name',
    bool sortAscending = true,
  }) {
    final offset = (page - 1) * limit;

    // Build base query - use join if tags are specified
    late final JoinedSelectStatement query;
    late final Stream<int> countStream;

    if (tags != null && tags.isNotEmpty) {
      // Query with tag filtering - use joins
      query = _db.select(_db.clients).join([
        innerJoin(_db.clientTags, _db.clientTags.clientId.equalsExp(_db.clients.id)),
        innerJoin(_db.tags, _db.tags.id.equalsExp(_db.clientTags.tagId)),
      ]);

      // Create a separate count query that counts distinct client IDs
      final distinctCountQuery = _db.selectOnly(_db.clients).join([
        innerJoin(_db.clientTags, _db.clientTags.clientId.equalsExp(_db.clients.id)),
        innerJoin(_db.tags, _db.tags.id.equalsExp(_db.clientTags.tagId)),
      ]);
      distinctCountQuery.addColumns([_db.clients.id.count(distinct: true)]);

      // Add tag name filter
      query.where(_db.tags.name.isIn(tags));
      distinctCountQuery.where(_db.tags.name.isIn(tags));

      // Group by client ID to avoid duplicates when client has multiple matching tags
      query.groupBy([_db.clients.id]);
      // Don't group the count query - we want the total distinct count

      // Add search filter if provided
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final searchCondition = _db.clients.firstName.contains(searchTerm) |
            _db.clients.lastName.contains(searchTerm) |
            _db.clients.email.contains(searchTerm) |
            _db.clients.company.contains(searchTerm);
        
        query.where(searchCondition);
        distinctCountQuery.where(searchCondition);
      }

      // Add company filter if provided
      if (company != null && company.isNotEmpty) {
        query.where(_db.clients.company.equals(company));
        distinctCountQuery.where(_db.clients.company.equals(company));
      }

      if (jobTitle != null && jobTitle.isNotEmpty) {
        query.where(_db.clients.jobTitle.equals(jobTitle));
        distinctCountQuery.where(_db.clients.jobTitle.equals(jobTitle));
      }

      // Add date range filter if provided
      if (dateRange != null) {
        final dateCondition = _db.clients.createdAt.isBiggerOrEqualValue(dateRange.start) &
            _db.clients.createdAt.isSmallerOrEqualValue(dateRange.end);
        
        query.where(dateCondition);
        distinctCountQuery.where(dateCondition);
      }

      // Create count stream that properly handles the single result
      countStream = distinctCountQuery.map((row) => row.read(_db.clients.id.count(distinct: true)) ?? 0).watchSingle();
    } else {
      // Query without tag filtering - simple select
      query = _db.select(_db.clients).join([]);
      final countQuery = _db.selectOnly(_db.clients).join([]);
      countQuery.addColumns([_db.clients.id.count()]);

      // Add search filter if provided
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final searchCondition = _db.clients.firstName.contains(searchTerm) |
            _db.clients.lastName.contains(searchTerm) |
            _db.clients.email.contains(searchTerm) |
            _db.clients.company.contains(searchTerm);
        
        query.where(searchCondition);
        countQuery.where(searchCondition);
      }

      // Add company filter if provided
      if (company != null && company.isNotEmpty) {
        query.where(_db.clients.company.equals(company));
        countQuery.where(_db.clients.company.equals(company));
      }

      if (jobTitle != null && jobTitle.isNotEmpty) {
        query.where(_db.clients.jobTitle.equals(jobTitle));
        countQuery.where(_db.clients.jobTitle.equals(jobTitle));
      }

      // Add date range filter if provided
      if (dateRange != null) {
        final dateCondition = _db.clients.createdAt.isBiggerOrEqualValue(dateRange.start) &
            _db.clients.createdAt.isSmallerOrEqualValue(dateRange.end);
        
        query.where(dateCondition);
        countQuery.where(dateCondition);
      }

      countStream = countQuery.map((row) => row.read(_db.clients.id.count()) ?? 0).watchSingle();
    }

    // Add ordering
    switch (sortBy.toLowerCase()) {
      case 'company':
        query.orderBy([OrderingTerm(expression: _db.clients.company, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc)]);
        break;
      case 'created':
        query.orderBy([OrderingTerm(expression: _db.clients.createdAt, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc)]);
        break;
      case 'updated':
        query.orderBy([OrderingTerm(expression: _db.clients.updatedAt, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc)]);
        break;
      case 'jobtitle':
        query.orderBy([OrderingTerm(expression: _db.clients.jobTitle, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc)]);
        break;
      default: // name
        query.orderBy([
          OrderingTerm(expression: _db.clients.firstName, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc),
          OrderingTerm(expression: _db.clients.lastName, mode: sortAscending ? OrderingMode.asc : OrderingMode.desc),
        ]);
    }

    // Apply pagination
    query.limit(limit, offset: offset);

    final resultsStream = query.watch();

    return Rx.combineLatest2(resultsStream, countStream, (results, totalCount) {
      final clients = results.map((row) => _clientFromRow(row.readTable(_db.clients))).toList();
      
      return PaginatedResult<ClientModel>(
        items: clients,
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
    invalidateCache(CacheKeys.clientJobTitles); // Invalidate job titles cache
  
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
      invalidateCache(CacheKeys.clientJobTitles); // Invalidate job titles cache
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
      invalidateCache(CacheKeys.clientJobTitles); // Invalidate job titles cache
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

  Future<List<String>> getAllJobTitles() async {
    final cacheKey = CacheKeys.clientJobTitles;
    
    return await getCached(
      cacheKey,
      () async {
        final query = _db.selectOnly(_db.clients)
          ..addColumns([_db.clients.jobTitle])
          ..where(_db.clients.jobTitle.isNotNull() & _db.clients.jobTitle.isNotValue(''))
          ..groupBy([_db.clients.jobTitle])
          ..orderBy([OrderingTerm.asc(_db.clients.jobTitle)]);
        
        final results = await query.get();
        return results
            .map((row) => row.read(_db.clients.jobTitle) ?? '')
            .where((jobTitle) => jobTitle.isNotEmpty)
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
      invalidateCache(CacheKeys.clientJobTitles); // Invalidate job titles cache
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
      invalidateCache(CacheKeys.clientJobTitles); // Invalidate job titles cache
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