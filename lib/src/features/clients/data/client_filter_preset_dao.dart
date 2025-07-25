import 'package:drift/drift.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'dart:convert';
import '../../../core/models/database.dart';
import '../../../core/services/database_service.dart';
import 'client_filter_preset_model.dart';
import '../../../core/cache/cached_repository.dart';
import '../../../core/cache/cache_manager.dart';


class ClientFilterPresetDao extends CachedRepository {
  final AppDatabase _db = DatabaseService.instance.database;

  // Get all filter presets
  Future<List<ClientFilterPreset>> getAllPresets() async {
    const cacheKey = 'client_filter_presets_all';
    
    return await getCached(
      cacheKey,
      () async {
        final query = _db.select(_db.clientFilterPresets)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]);

        final results = await query.get();
        return results.map((row) => _presetFromRow(row)).toList();
      },
      ttl: CacheManager.defaultTtl,
    );
  }

  // Save a new preset
  Future<int> savePreset(ClientFilterPreset preset) async {
    final result = await _db.into(_db.clientFilterPresets).insert(
      ClientFilterPresetsCompanion.insert(
        name: preset.name,
        searchTerm: Value(preset.searchTerm),
        tags: Value(jsonEncode(preset.tags)),
        company: Value(preset.company),
        dateRangeStart: Value(preset.dateRange?.start.toIso8601String()),
        dateRangeEnd: Value(preset.dateRange?.end.toIso8601String()),
        sortBy: Value(preset.sortBy),
        sortAscending: Value(preset.sortAscending),
      ),
    );

    // Invalidate cache
    invalidateCache('client_filter_presets');
    
    return result;
  }

  // Update existing preset
  Future<bool> updatePreset(ClientFilterPreset preset) async {
    final query = _db.update(_db.clientFilterPresets)
      ..where((p) => p.id.equals(preset.id));
    
    final updatedRows = await query.write(
      ClientFilterPresetsCompanion(
        name: Value(preset.name),
        searchTerm: Value(preset.searchTerm),
        tags: Value(jsonEncode(preset.tags)),
        company: Value(preset.company),
        dateRangeStart: Value(preset.dateRange?.start.toIso8601String()),
        dateRangeEnd: Value(preset.dateRange?.end.toIso8601String()),
        sortBy: Value(preset.sortBy),
        sortAscending: Value(preset.sortAscending),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (updatedRows > 0) {
      invalidateCache('client_filter_presets');
    }

    return updatedRows > 0;
  }

  // Delete preset
  Future<bool> deletePreset(int presetId) async {
    final query = _db.delete(_db.clientFilterPresets)
      ..where((p) => p.id.equals(presetId));
    
    final deletedRows = await query.go();

    if (deletedRows > 0) {
      invalidateCache('client_filter_presets');
    }

    return deletedRows > 0;
  }

  // Helper method to convert database row to model
  ClientFilterPreset _presetFromRow(ClientFilterPresetData row) {
    return ClientFilterPreset(
      id: row.id,
      name: row.name,
      searchTerm: row.searchTerm,
      tags: row.tags.isNotEmpty 
          ? List<String>.from(jsonDecode(row.tags))
          : [],
      company: row.company,
      dateRange: row.dateRangeStart != null && row.dateRangeEnd != null
          ? DateTimeRange(
              start: DateTime.parse(row.dateRangeStart!),
              end: DateTime.parse(row.dateRangeEnd!),
            )
          : null,
      sortBy: row.sortBy,
      sortAscending: row.sortAscending,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
