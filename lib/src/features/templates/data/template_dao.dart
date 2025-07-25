import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:drift/drift.dart';
import '../../../core/models/database.dart';
import '../../../core/services/database_service.dart';
import '../../../core/realtime/realtime_sync_service.dart';
import '../../../core/realtime/event_bus.dart';
import 'template_model.dart';

class TemplateDao {
  final AppDatabase _database = DatabaseService.instance.database;
  final RealtimeSyncService _syncService = RealtimeSyncService();

  // Get all templates
  Stream<List<TemplateModel>> watchAllTemplates() {
    return _database.select(_database.templates).watch().map((templates) {
      return templates.map((template) => TemplateModel.fromDatabase(template)).toList();
    });
  }

  // Get templates by type
  Stream<List<TemplateModel>> watchTemplatesByType(TemplateType type) {
    final typeString = type == TemplateType.whatsapp ? 'whatsapp' : 'email';
    return (_database.select(_database.templates)
          ..where((t) => t.templateType.equals(typeString)))
        .watch()
        .map((templates) {
      return templates.map((template) => TemplateModel.fromDatabase(template)).toList();
    });
  }

  // Get template by ID
  Future<TemplateModel?> getTemplateById(int id) async {
    final template = await (_database.select(_database.templates)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    
    if (template == null) return null;
    return TemplateModel.fromDatabase(template);
  }

  // Watch template by ID
  Stream<TemplateModel?> watchTemplateById(int id) {
    return (_database.select(_database.templates)
          ..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((template) => template != null ? TemplateModel.fromDatabase(template) : null);
  }

  // Create new template - ENHANCED WITH EVENT EMISSION
  Future<TemplateModel> createTemplate(TemplateModel template) async {
    final id = await _database.into(_database.templates).insert(template.toDatabase());
    
    // Emit real-time event
    _syncService.emitEvent(TemplateEvent(
      type: TemplateEventType.created,
      templateId: id,
      timestamp: DateTime.now(),
      source: 'TemplateDao.createTemplate',
      metadata: {
        'name': template.name,
        'templateType': template.templateType.name,
        'blockCount': template.blocks.length,
      },
    ));
    
    // Return the created template with the new ID
    final createdTemplate = await getTemplateById(id);
    return createdTemplate!;
  }

  // Update existing template - ENHANCED WITH EVENT EMISSION
  Future<TemplateModel> updateTemplate(TemplateModel template) async {
    await (_database.update(_database.templates)
          ..where((t) => t.id.equals(template.id)))
        .write(template.toDatabaseUpdate());
    
    // Emit real-time event
    _syncService.emitEvent(TemplateEvent(
      type: TemplateEventType.updated,
      templateId: template.id,
      timestamp: DateTime.now(),
      source: 'TemplateDao.updateTemplate',
      metadata: {
        'name': template.name,
        'templateType': template.templateType.name,
        'blockCount': template.blocks.length,
      },
    ));
    
    // Return the updated template
    final updatedTemplate = await getTemplateById(template.id);
    return updatedTemplate!;
  }

  Future<bool> updateTemplatenew(TemplateModel template) async {
    try {
      final companion = template.toDatabaseUpdate();
      final rowsAffected = await _database.update(_database.templates).replace(companion);
      
      if (rowsAffected) {
        // Emit real-time event
        _syncService.emitEvent(TemplateEvent(
          type: TemplateEventType.updated,
          templateId: template.id,
          timestamp: DateTime.now(),
          source: 'TemplateDao.updateTemplatenew',
          metadata: {
            'name': template.name,
            'templateType': template.templateType.name,
          },
        ));
      }
      
      return rowsAffected;
    } catch (e) {
      throw Exception('Failed to update template: $e');
    }
  }

  // Delete template - ENHANCED WITH EVENT EMISSION
  Future<bool> deleteTemplate(int id) async {
    // Get template data before deletion for event metadata
    final templateData = await getTemplateById(id);
    
    final deletedRows = await (_database.delete(_database.templates)
          ..where((t) => t.id.equals(id)))
        .go();
    
    if (deletedRows > 0) {
      // Emit real-time event
      _syncService.emitEvent(TemplateEvent(
        type: TemplateEventType.deleted,
        templateId: id,
        timestamp: DateTime.now(),
        source: 'TemplateDao.deleteTemplate',
        metadata: {
          'deletedTemplate': templateData != null ? {
            'name': templateData.name,
            'templateType': templateData.templateType.name,
            'blockCount': templateData.blocks.length,
          } : null,
        },
      ));
    }
    
    return deletedRows > 0;
  }

  // Duplicate template - ENHANCED WITH EVENT EMISSION
  Future<TemplateModel> duplicateTemplate(int id) async {
    final originalTemplate = await getTemplateById(id);
    if (originalTemplate == null) {
      throw Exception('Template not found');
    }

    // Create a copy with a new name
    final duplicatedTemplate = originalTemplate.copyWith(
      name: '${originalTemplate.name} (Copy)',
    );

    // Remove the ID so it gets a new one when inserted
    final newTemplate = TemplateModel(
      id: 0, // Will be ignored during insertion
      name: duplicatedTemplate.name,
      subject: duplicatedTemplate.subject,
      body: duplicatedTemplate.body,
      templateType: duplicatedTemplate.templateType,
      blocks: duplicatedTemplate.blocks,
      isEmail: duplicatedTemplate.isEmail,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final createdTemplate = await createTemplate(newTemplate);
    
    // Emit additional duplication event
    _syncService.emitEvent(TemplateEvent(
      type: TemplateEventType.duplicated,
      templateId: createdTemplate.id,
      timestamp: DateTime.now(),
      source: 'TemplateDao.duplicateTemplate',
      metadata: {
        'originalTemplateId': id,
        'originalTemplateName': originalTemplate.name,
        'newTemplateName': createdTemplate.name,
      },
    ));

    return createdTemplate;
  }

  // Search templates by name
  Future<List<TemplateModel>> searchTemplates(String query) async {
    final templates = await (_database.select(_database.templates)
          ..where((t) => t.name.like('%$query%')))
        .get();
    return templates.map((template) => TemplateModel.fromDatabase(template)).toList();
  }

  // Get recent templates (last 10)
  Future<List<TemplateModel>> getRecentTemplates({int limit = 10}) async {
    final templates = await (_database.select(_database.templates)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit))
        .get();
    return templates.map((template) => TemplateModel.fromDatabase(template)).toList();
  }

  // Get template count
  Future<int> getTemplateCount() async {
    final count = await _database.customSelect(
      'SELECT COUNT(*) as count FROM templates',
      readsFrom: {_database.templates},
    ).getSingle();
    return count.data['count'] as int;
  }

  // Get template count by type
  Future<int> getTemplateCountByType(TemplateType type) async {
    final typeString = type == TemplateType.whatsapp ? 'whatsapp' : 'email';
    final count = await _database.customSelect(
      'SELECT COUNT(*) as count FROM templates WHERE template_type = ?',
      variables: [Variable.withString(typeString)],
      readsFrom: {_database.templates},
    ).getSingle();
    return count.data['count'] as int;
  }

  // Check if template name exists
  Future<bool> templateNameExists(String name, {int? excludeId}) async {
    var query = _database.select(_database.templates)
      ..where((t) => t.name.equals(name));
    
    if (excludeId != null) {
      query = query..where((t) => t.id.equals(excludeId).not());
    }
    
    final template = await query.getSingleOrNull();
    return template != null;
  }

  // Batch operations - ENHANCED WITH EVENT EMISSION
  Future<void> deleteMultipleTemplates(List<int> ids) async {
    if (ids.isEmpty) return;
    
    // Get template data before deletion for event metadata
    final templatesData = <Map<String, dynamic>>[];
    for (final id in ids) {
      final template = await getTemplateById(id);
      if (template != null) {
        templatesData.add({
          'id': id,
          'name': template.name,
          'templateType': template.templateType.name,
        });
      }
    }
    
    await _database.batch((batch) {
      for (final id in ids) {
        batch.deleteWhere(_database.templates, (t) => t.id.equals(id));
      }
    });
    
    // Emit real-time event
    _syncService.emitEvent(TemplateEvent(
      type: TemplateEventType.bulkDeleted,
      timestamp: DateTime.now(),
      source: 'TemplateDao.deleteMultipleTemplates',
      metadata: {
        'deletedCount': ids.length,
        'templateIds': ids,
        'deletedTemplates': templatesData,
      },
    ));
  }

  // Export templates (get all data for backup)
  Future<List<Map<String, dynamic>>> exportTemplates() async {
    final templates = await _database.select(_database.templates).get();
    return templates.map((template) => {
      'id': template.id,
      'name': template.name,
      'subject': template.subject,
      'body': template.body,
      'template_type': template.templateType,
      'blocks_json': template.blocksJson,
      'is_email': template.isEmail,
      'created_at': template.createdAt.toIso8601String(),
      'updated_at': template.updatedAt.toIso8601String(),
    }).toList();
  }

  // Import templates (restore from backup)
  Future<void> importTemplates(List<Map<String, dynamic>> templatesData) async {
    await _database.batch((batch) {
      for (final templateData in templatesData) {
        batch.insert(
          _database.templates,
          TemplatesCompanion.insert(
            name: templateData['name'],
            subject: Value(templateData['subject']),
            body: templateData['body'],
            templateType: Value(templateData['template_type']),
            blocksJson: Value(templateData['blocks_json']),
            isEmail: Value(templateData['is_email']),
            createdAt: Value(DateTime.parse(templateData['created_at'])),
            updatedAt: Value(DateTime.parse(templateData['updated_at'])),
          ),
        );
      }
    });
  }

  // Clean up orphaned template blocks (if using separate blocks table)
  Future<void> cleanupOrphanedBlocks() async {
    await _database.customStatement(
      'DELETE FROM template_blocks WHERE template_id NOT IN (SELECT id FROM templates)',
    );
  }

  // Get templates with block statistics
  Future<List<Map<String, dynamic>>> getTemplatesWithStats() async {
    final templates = await watchAllTemplates().first;
    
    return templates.map((t) {
      final blockTypeCounts = <String, int>{};
      for (final block in t.blocks) {
        final typeName = block.type.name;
        blockTypeCounts[typeName] = (blockTypeCounts[typeName] ?? 0) + 1;
      }
      
      return {
        'template': t,
        'block_count': t.blocks.length,
        'block_types': blockTypeCounts,
        'has_images': t.blocks.any((b) => b.type == TemplateBlockType.image),
        'has_buttons': t.blocks.any((b) => b.type == TemplateBlockType.button),
      };
    }).toList();
  }
}
