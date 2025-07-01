import 'package:drift/drift.dart';
import '../../../core/models/database.dart';
import '../../../core/services/database_service.dart';
import 'tag_model.dart';

class TagDao {
  final AppDatabase _db = DatabaseService.instance.database;

  // Watch all tags
  Stream<List<TagModel>> watchAllTags() {
    return _db.select(_db.tags).watch().map(
      (rows) => rows.map((row) => _tagFromRow(row)).toList(),
    );
  }

  // Get tag by ID
  Future<TagModel?> getTagById(int id) async {
    final query = _db.select(_db.tags)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _tagFromRow(row) : null;
  }

  // Insert new tag
  Future<int> insertTag(TagsCompanion tag) async {
    return await _db.into(_db.tags).insert(tag);
  }

  // Update existing tag
  Future<bool> updateTag(int id, TagsCompanion tag) async {
    final query = _db.update(_db.tags)..where((t) => t.id.equals(id));
    final updatedRows = await query.write(tag.copyWith(
      updatedAt: Value(DateTime.now()),
    ));
    return updatedRows > 0;
  }

  // Delete tag
  Future<bool> deleteTag(int id) async {
    // First remove all client-tag associations
    await (_db.delete(_db.clientTags)..where((ct) => ct.tagId.equals(id))).go();
    
    // Then delete the tag
    final query = _db.delete(_db.tags)..where((t) => t.id.equals(id));
    final deletedRows = await query.go();
    return deletedRows > 0;
  }

  // Get tags for a specific client
  Future<List<TagModel>> getTagsForClient(int clientId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(_db.clientTags, _db.clientTags.tagId.equalsExp(_db.tags.id)),
    ])..where(_db.clientTags.clientId.equals(clientId));

    final rows = await query.get();
    return rows.map((row) => _tagFromRow(row.readTable(_db.tags))).toList();
  }

  // Watch tags for a specific client
  Stream<List<TagModel>> watchTagsForClient(int clientId) {
    final query = _db.select(_db.tags).join([
      innerJoin(_db.clientTags, _db.clientTags.tagId.equalsExp(_db.tags.id)),
    ])..where(_db.clientTags.clientId.equals(clientId));

    return query.watch().map(
      (rows) => rows.map((row) => _tagFromRow(row.readTable(_db.tags))).toList(),
    );
  }

  // Get clients with specific tags
  Stream<List<ClientWithTags>> watchClientsWithTags({List<int>? tagIds}) {
    if (tagIds == null || tagIds.isEmpty) {
      return watchAllClientsWithTags();
    }

    final query = _db.select(_db.clients).join([
      innerJoin(_db.clientTags, _db.clientTags.clientId.equalsExp(_db.clients.id)),
    ])..where(_db.clientTags.tagId.isIn(tagIds))
      ..groupBy([_db.clients.id]);

    return query.watch().asyncMap((rows) async {
      final clients = <ClientWithTags>[];
      for (final row in rows) {
        final client = row.readTable(_db.clients);
        final tags = await getTagsForClient(client.id);
        clients.add(ClientWithTags(
          id: client.id,
          firstName: client.firstName,
          lastName: client.lastName,
          email: client.email,
          phone: client.phone,
          company: client.company,
          jobTitle: client.jobTitle,
          tags: tags,
        ));
      }
      return clients;
    });
  }

  // Get all clients with their tags
  Stream<List<ClientWithTags>> watchAllClientsWithTags() {
    return _db.select(_db.clients).watch().asyncMap((clients) async {
      final clientsWithTags = <ClientWithTags>[];
      for (final client in clients) {
        final tags = await getTagsForClient(client.id);
        clientsWithTags.add(ClientWithTags(
          id: client.id,
          firstName: client.firstName,
          lastName: client.lastName,
          email: client.email,
          phone: client.phone,
          company: client.company,
          jobTitle: client.jobTitle,
          tags: tags,
        ));
      }
      return clientsWithTags;
    });
  }

  // Add tag to client
  Future<void> addTagToClient(int clientId, int tagId) async {
    await _db.into(_db.clientTags).insert(ClientTagsCompanion.insert(
      clientId: clientId,
      tagId: tagId,
    ));
  }

  // Remove tag from client
  Future<void> removeTagFromClient(int clientId, int tagId) async {
    await (_db.delete(_db.clientTags)
      ..where((ct) => ct.clientId.equals(clientId) & ct.tagId.equals(tagId))
    ).go();
  }

  // Add multiple tags to client
  Future<void> addTagsToClient(int clientId, List<int> tagIds) async {
    await _db.batch((batch) {
      for (final tagId in tagIds) {
        batch.insert(_db.clientTags, ClientTagsCompanion.insert(
          clientId: clientId,
          tagId: tagId,
        ));
      }
    });
  }

  // Remove all tags from client
  Future<void> removeAllTagsFromClient(int clientId) async {
    await (_db.delete(_db.clientTags)
      ..where((ct) => ct.clientId.equals(clientId))
    ).go();
  }

  // Bulk tag operations
  Future<void> addTagToMultipleClients(List<int> clientIds, int tagId) async {
    await _db.batch((batch) {
      for (final clientId in clientIds) {
        batch.insert(_db.clientTags, ClientTagsCompanion.insert(
          clientId: clientId,
          tagId: tagId,
        ));
      }
    });
  }

  Future<void> removeTagFromMultipleClients(List<int> clientIds, int tagId) async {
    await (_db.delete(_db.clientTags)
      ..where((ct) => ct.clientId.isIn(clientIds) & ct.tagId.equals(tagId))
    ).go();
  }

  // Search tags
  Stream<List<TagModel>> searchTags(String searchTerm) {
    final query = _db.select(_db.tags)
      ..where((t) => t.name.contains(searchTerm) | t.description.contains(searchTerm));
    
    return query.watch().map(
      (rows) => rows.map((row) => _tagFromRow(row)).toList(),
    );
  }

  // Get tag usage statistics
  Future<Map<int, int>> getTagUsageStats() async {
    final query = _db.selectOnly(_db.clientTags)
      ..addColumns([_db.clientTags.tagId, _db.clientTags.tagId.count()])
      ..groupBy([_db.clientTags.tagId]);

    final rows = await query.get();
    final stats = <int, int>{};
    for (final row in rows) {
      final tagId = row.read(_db.clientTags.tagId)!;
      final count = row.read(_db.clientTags.tagId.count())!;
      stats[tagId] = count;
    }
    return stats;
  }

  // Helper method to convert database row to TagModel
  TagModel _tagFromRow(Tag row) {
    return TagModel(
      id: row.id,
      name: row.name,
      color: row.color,
      description: row.description,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}