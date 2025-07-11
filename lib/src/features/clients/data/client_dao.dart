import 'package:drift/drift.dart';
import '../../../core/models/database.dart';
import '../../../core/services/database_service.dart';
import '../../../core/widgets/paginated_list_view.dart';
import 'client_model.dart';
import '../../../core/cache/cached_repository.dart';
import '../../../core/cache/cache_manager.dart';

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
        
        // Add ordering
        query = query..orderBy([(c) => OrderingTerm.asc(c.firstName)]);
        
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