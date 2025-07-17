import 'package:drift/drift.dart';
import '../../../core/models/database.dart';
import '../../../core/services/database_service.dart';
import '../../../core/widgets/paginated_list_view.dart';
import 'client_model.dart';
import '../../../core/cache/cached_repository.dart';
import '../../../core/cache/cache_manager.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ClientDao extends CachedRepository {
  final AppDatabase _db = DatabaseService.instance.database;

  // Watch all clients (reactive stream) - kept for backward compatibility
  Stream<List<ClientModel>> watchAllClients() {
    return _db.select(_db.clients).watch().map(
      (rows) => rows.map((row) => _clientFromRow(row)).toList(),
    );
  }

  // New paginated method for better performance
  Future<PaginatedResult<ClientModel>> getPaginatedClients({
    int page = 1,
    int limit = 50,
    String? searchTerm,
    List<String>? tags,
    String? company,
    DateTimeRange? dateRange,
    String sortBy = 'name',
    bool sortAscending = true,
  }) async {
    final cacheKey = CacheKeys.clientsPaginated(page, limit, searchTerm);

    return await getCached(
      cacheKey,
      () async {
        final offset = (page - 1) * limit;
        
        // Build base query
        var query = _db.select(_db.clients);
        
        // Add search filter if provided
        if (searchTerm != null && searchTerm.isNotEmpty) {
          query = query..where((c) => 
            c.firstName.contains(searchTerm) |
            c.lastName.contains(searchTerm) |
            c.email.contains(searchTerm) |
            c.company.contains(searchTerm)
          );
        }

        // Add company filter if provided
        if (company != null && company.isNotEmpty) {
          query = query..where((c) => c.company.equals(company));
        }

        // Add date range filter if provided
        if (dateRange != null) {
          query = query..where((c) => 
            c.createdAt.isBiggerOrEqualValue(dateRange.start) &
            c.createdAt.isSmallerOrEqualValue(dateRange.end)
          );
        }

        // Add tag filter if provided (this will require a join with ClientTags table)
        if (tags != null && tags.isNotEmpty) {
          // Join with ClientTags table to filter by tags
          final tagQuery = _db.select(_db.clients).join([
            leftOuterJoin(_db.clientTags, _db.clientTags.clientId.equalsExp(_db.clients.id)),
            leftOuterJoin(_db.tags, _db.tags.id.equalsExp(_db.clientTags.tagId)),
          ]);

          // Apply existing filters to the joined query
          if (searchTerm != null && searchTerm.isNotEmpty) {
            tagQuery.where(
              _db.clients.firstName.contains(searchTerm) |
              _db.clients.lastName.contains(searchTerm) |
              _db.clients.email.contains(searchTerm) |
              _db.clients.company.contains(searchTerm)
            );
          }

          if (company != null && company.isNotEmpty) {
            tagQuery.where(_db.clients.company.equals(company));
          }

          if (dateRange != null) {
            tagQuery.where(
              _db.clients.createdAt.isBiggerOrEqualValue(dateRange.start) &
              _db.clients.createdAt.isSmallerOrEqualValue(dateRange.end)
            );
          }

          // Filter by tags
          tagQuery.where(_db.tags.name.isIn(tags));

          // Add ordering for joined query
          switch (sortBy.toLowerCase()) {
            case 'company':
              tagQuery.orderBy([OrderingTerm(
                expression: _db.clients.company,
                mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
              )]);
              break;
            case 'created':
              tagQuery.orderBy([OrderingTerm(
                expression: _db.clients.createdAt,
                mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
              )]);
              break;
            case 'updated':
              tagQuery.orderBy([OrderingTerm(
                expression: _db.clients.updatedAt,
                mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
              )]);
              break;
            default: // name
              tagQuery.orderBy([
                OrderingTerm(
                  expression: _db.clients.firstName,
                  mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
                ),
                OrderingTerm(
                  expression: _db.clients.lastName,
                  mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
                ),
              ]);
          }

          // Get results from joined query
          final joinedResults = await (tagQuery..limit(limit, offset: offset)).get();
          final clients = joinedResults.map((row) => _clientFromRow(row.readTable(_db.clients))).toList();

          // Get total count for joined query
          final countJoinQuery = _db.selectOnly(_db.clients).join([
            leftOuterJoin(_db.clientTags, _db.clientTags.clientId.equalsExp(_db.clients.id)),
            leftOuterJoin(_db.tags, _db.tags.id.equalsExp(_db.clientTags.tagId)),
          ]);
          countJoinQuery.addColumns([_db.clients.id.count()]);

          if (searchTerm != null && searchTerm.isNotEmpty) {
            countJoinQuery.where(
              _db.clients.firstName.contains(searchTerm) |
              _db.clients.lastName.contains(searchTerm) |
              _db.clients.email.contains(searchTerm) |
              _db.clients.company.contains(searchTerm)
            );
          }

          if (company != null && company.isNotEmpty) {
            countJoinQuery.where(_db.clients.company.equals(company));
          }

          if (dateRange != null) {
            countJoinQuery.where(
              _db.clients.createdAt.isBiggerOrEqualValue(dateRange.start) &
              _db.clients.createdAt.isSmallerOrEqualValue(dateRange.end)
            );
          }

          countJoinQuery.where(_db.tags.name.isIn(tags));

          final totalCount = await countJoinQuery.map((row) => row.read(_db.clients.id.count()) ?? 0).getSingle();

          return PaginatedResult<ClientModel>(
            items: clients,
            hasMore: offset + clients.length < totalCount,
            totalCount: totalCount,
          );
        }
        
        // Add ordering for regular query (no tags filter)
        switch (sortBy.toLowerCase()) {
          case 'company':
            query = query..orderBy([(c) => OrderingTerm(
              expression: c.company,
              mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
            )]);
            break;
          case 'created':
            query = query..orderBy([(c) => OrderingTerm(
              expression: c.createdAt,
              mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
            )]);
            break;
          case 'updated':
            query = query..orderBy([(c) => OrderingTerm(
              expression: c.updatedAt,
              mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
            )]);
            break;
          default: // name
            query = query..orderBy([
              (c) => OrderingTerm(
                expression: c.firstName,
                mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
              ),
              (c) => OrderingTerm(
                expression: c.lastName,
                mode: sortAscending ? OrderingMode.asc : OrderingMode.desc,
              ),
            ]);
        }
        
        // Get total count for pagination info
        final countQuery = _db.selectOnly(_db.clients)..addColumns([_db.clients.id.count()]);
        
        if (searchTerm != null && searchTerm.isNotEmpty) {
          countQuery.where(
            _db.clients.firstName.contains(searchTerm) |
            _db.clients.lastName.contains(searchTerm) |
            _db.clients.email.contains(searchTerm) |
            _db.clients.company.contains(searchTerm)
          );
        }

        if (company != null && company.isNotEmpty) {
          countQuery.where(_db.clients.company.equals(company));
        }

        if (dateRange != null) {
          countQuery.where(
            _db.clients.createdAt.isBiggerOrEqualValue(dateRange.start) &
            _db.clients.createdAt.isSmallerOrEqualValue(dateRange.end)
          );
        }
        
        final totalCount = await countQuery.map((row) => row.read(_db.clients.id.count()) ?? 0).getSingle();
        
        // Get paginated results
        final results = await (query..limit(limit, offset: offset)).get();
        
        return PaginatedResult<ClientModel>(
          items: results.map((row) => _clientFromRow(row)).toList(),
          hasMore: offset + results.length < totalCount,
          totalCount: totalCount,
        );
      },
      ttl: CacheManager.shortTtl, // Cache for 1 minute
    );
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

  // Insert new client
  Future<int> insertClient(ClientsCompanion client) async {
    final result = await _db.into(_db.clients).insert(client);
  
    // Invalidate paginated cache entries
    invalidateCache(CacheKeys.clientPrefix);
  
    return result;
  }

  // Update existing client
  Future<bool> updateClient(int id, ClientsCompanion client) async {
    final query = _db.update(_db.clients)..where((c) => c.id.equals(id));
    final updatedRows = await query.write(client.copyWith(
      updatedAt: Value(DateTime.now()),
    ));
  
    if (updatedRows > 0) {
      // Clear specific client cache and paginated results
      clearCacheEntry(CacheKeys.clientById(id));
      invalidateCache(CacheKeys.clientPrefix);
    }
  
    return updatedRows > 0;
  }

  // Delete client
  Future<bool> deleteClient(int id) async {
    final query = _db.delete(_db.clients)..where((c) => c.id.equals(id));
    final deletedRows = await query.go();
  
    if (deletedRows > 0) {
      // Clear specific client cache and paginated results
      clearCacheEntry(CacheKeys.clientById(id));
      invalidateCache(CacheKeys.clientPrefix);
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

  // Bulk delete clients
  Future<int> bulkDeleteClients(List<int> clientIds) async {
    if (clientIds.isEmpty) return 0;
    
    final query = _db.delete(_db.clients)
      ..where((c) => c.id.isIn(clientIds));
    
    final deletedRows = await query.go();
    
    if (deletedRows > 0) {
      // Clear cache for all affected clients
      for (final id in clientIds) {
        clearCacheEntry(CacheKeys.clientById(id));
      }
      invalidateCache(CacheKeys.clientPrefix);
    }
    
    return deletedRows;
  }

  // Bulk update clients (for tagging, company changes, etc.)
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
      // Clear cache for all affected clients
      for (final id in clientIds) {
        clearCacheEntry(CacheKeys.clientById(id));
      }
      invalidateCache(CacheKeys.clientPrefix);
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
}
