import 'package:drift/drift.dart';
import '../../../core/models/database.dart';
import '../../../core/services/database_service.dart';
import 'client_model.dart';

class ClientDao {
  final AppDatabase _db = DatabaseService.instance.database;

  // Watch all clients (reactive stream)
  Stream<List<ClientModel>> watchAllClients() {
    return _db.select(_db.clients).watch().map(
      (rows) => rows.map((row) => _clientFromRow(row)).toList(),
    );
  }

  // Get client by ID
  Future<ClientModel?> getClientById(int id) async {
    final query = _db.select(_db.clients)..where((c) => c.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _clientFromRow(row) : null;
  }

  // Insert new client
  Future<int> insertClient(ClientsCompanion client) async {
    return await _db.into(_db.clients).insert(client);
  }

  // Update existing client
  Future<bool> updateClient(int id, ClientsCompanion client) async {
    final query = _db.update(_db.clients)..where((c) => c.id.equals(id));
    final updatedRows = await query.write(client.copyWith(
      updatedAt: Value(DateTime.now()),
    ));
    return updatedRows > 0;
  }

  // Delete client
  Future<bool> deleteClient(int id) async {
    final query = _db.delete(_db.clients)..where((c) => c.id.equals(id));
    final deletedRows = await query.go();
    return deletedRows > 0;
  }

  // Search clients by name or email
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