import 'package:drift/drift.dart';
import '../../../core/models/database.dart';
import '../../../core/services/database_service.dart';
import 'template_model.dart';

class TemplateDao {
  final AppDatabase _db = DatabaseService.instance.database;

  // Watch all templates
  Stream<List<TemplateModel>> watchAllTemplates() {
    return _db.select(_db.templates).watch().map(
      (rows) => rows.map((row) => _templateFromRow(row)).toList(),
    );
  }

  // Watch templates by type
  Stream<List<TemplateModel>> watchTemplatesByType(String type) {
    final query = _db.select(_db.templates)..where((t) => t.type.equals(type));
    return query.watch().map(
      (rows) => rows.map((row) => _templateFromRow(row)).toList(),
    );
  }

  // Get template by ID
  Future<TemplateModel?> getTemplateById(int id) async {
    final query = _db.select(_db.templates)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _templateFromRow(row) : null;
  }

  // Insert new template
  Future<int> insertTemplate(TemplatesCompanion template) async {
    return await _db.into(_db.templates).insert(template);
  }

  // Update existing template
  Future<bool> updateTemplate(int id, TemplatesCompanion template) async {
    final query = _db.update(_db.templates)..where((t) => t.id.equals(id));
    final updatedRows = await query.write(template.copyWith(
      updatedAt: Value(DateTime.now()),
    ));
    return updatedRows > 0;
  }

  // Delete template
  Future<bool> deleteTemplate(int id) async {
    final query = _db.delete(_db.templates)..where((t) => t.id.equals(id));
    final deletedRows = await query.go();
    return deletedRows > 0;
  }

  // Helper method to convert database row to TemplateModel
  TemplateModel _templateFromRow(Template row) {
    return TemplateModel(
      id: row.id,
      name: row.name,
      type: row.type,
      subject: row.subject,
      body: row.body,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}