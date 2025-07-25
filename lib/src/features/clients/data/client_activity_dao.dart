import 'package:client_connect/src/core/models/database.dart';
import 'package:client_connect/src/features/clients/data/client_activity_model.dart';
import 'package:drift/drift.dart';
import '../../../core/services/database_service.dart';
import '../../../core/cache/cached_repository.dart';
import '../../../core/cache/cache_manager.dart';

class ClientActivityDao extends CachedRepository {
  final AppDatabase _db = DatabaseService.instance.database;

  // Add activity for a client
  Future<int> addActivity({
    required int clientId,
    required ClientActivityType activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final result = await _db.into(_db.clientActivities).insert(
      ClientActivitiesCompanion.insert(
        clientId: clientId,
        activityType: activityType.name,
        description: description,
        metadata: Value(metadata != null ? 
          _encodeMetadata(metadata) : null),
      ),
    );

    // Invalidate cache for this client's activities
    invalidateCache('client_activities_$clientId');
    
    return result;
  }

  // Get activities for a specific client
  Future<List<ClientActivityModel>> getClientActivities(
    int clientId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final cacheKey = 'client_activities_${clientId}_${limit}_$offset';
    
    return await getCached(
      cacheKey,
      () async {
        final query = _db.select(_db.clientActivities)
          ..where((a) => a.clientId.equals(clientId))
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
          ..limit(limit, offset: offset);

        final results = await query.get();
        return results.map((row) => _activityFromRow(row)).toList();
      },
      ttl: CacheManager.shortTtl,
    );
  }

  // Get recent activities across all clients
  Future<List<ClientActivityModel>> getRecentActivities({
    int limit = 20,
  }) async {
    final cacheKey = 'recent_activities_$limit';
    
    return await getCached(
      cacheKey,
      () async {
        final query = _db.select(_db.clientActivities)
          ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
          ..limit(limit);

        final results = await query.get();
        return results.map((row) => _activityFromRow(row)).toList();
      },
      ttl: CacheManager.shortTtl,
    );
  }

  // Delete activities for a client (when client is deleted)
  Future<void> deleteClientActivities(int clientId) async {
    await (_db.delete(_db.clientActivities)
      ..where((a) => a.clientId.equals(clientId))).go();
    
    invalidateCache('client_activities_$clientId');
  }

  // Helper method to convert database row to model
  ClientActivityModel _activityFromRow(ClientActivity row) {
    return ClientActivityModel(
      id: row.id,
      clientId: row.clientId,
      activityType: ClientActivityType.values.firstWhere(
        (e) => e.name == row.activityType,
        orElse: () => ClientActivityType.updated,
      ),
      description: row.description,
      metadata: row.metadata != null ? _decodeMetadata(row.metadata!) : null,
      createdAt: row.createdAt,
    );
  }

  // Helper methods for metadata encoding/decoding
  String _encodeMetadata(Map<String, dynamic> metadata) {
    // Simple JSON encoding - in production, use proper JSON serialization
    return metadata.toString();
  }

  Map<String, dynamic>? _decodeMetadata(String metadata) {
    // Simple JSON decoding - in production, use proper JSON deserialization
    try {
      // This is a simplified implementation
      return <String, dynamic>{};
    } catch (e) {
      return null;
    }
  }
}
