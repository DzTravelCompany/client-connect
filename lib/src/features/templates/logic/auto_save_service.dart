import 'dart:async';
import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/templates/data/template_dao.dart';
import 'package:client_connect/src/features/templates/data/template_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutoSaveService {
  static const Duration _autoSaveDelay = Duration(seconds: 30);
  static const Duration _debounceDelay = Duration(seconds: 2);
  
  final TemplateDao _templateDao;
  Timer? _saveTimer;
  Timer? _debounceTimer;
  bool _isAutoSaving = false;
  DateTime? _lastSaved;
  String? _lastError;

  AutoSaveService(this._templateDao);

  /// Schedule an auto-save operation
  void scheduleAutoSave(TemplateModel template, {bool immediate = false}) {
    // Cancel existing timers
    _debounceTimer?.cancel();
    
    if (immediate) {
      _performAutoSave(template);
      return;
    }

    // Debounce rapid changes
    _debounceTimer = Timer(_debounceDelay, () {
      _saveTimer?.cancel();
      _saveTimer = Timer(_autoSaveDelay, () {
        _performAutoSave(template);
      });
    });
  }

  /// Perform the actual auto-save operation
  Future<void> _performAutoSave(TemplateModel template) async {
    if (_isAutoSaving) return;
    
    _isAutoSaving = true;
    _lastError = null;
    
    try {
      logger.i('Auto-saving template: ${template.name}');
      
      if (template.id > 0) {
        // Update existing template
        await _templateDao.updateTemplate(template);
      } else {
        // Create new template (shouldn't happen in auto-save, but handle it)
        await _templateDao.createTemplate(template);
      }
      
      _lastSaved = DateTime.now();
      logger.i('Auto-save completed successfully');
      
    } catch (e) {
      _lastError = e.toString();
      logger.e('Auto-save failed: $e');
    } finally {
      _isAutoSaving = false;
    }
  }

  /// Cancel any pending auto-save operations
  void cancelAutoSave() {
    _saveTimer?.cancel();
    _debounceTimer?.cancel();
    _saveTimer = null;
    _debounceTimer = null;
  }

  /// Get the current auto-save status
  AutoSaveStatus get status {
    if (_isAutoSaving) {
      return AutoSaveStatus.saving;
    } else if (_lastError != null) {
      return AutoSaveStatus.error;
    } else if (_lastSaved != null) {
      return AutoSaveStatus.saved;
    } else {
      return AutoSaveStatus.idle;
    }
  }

  /// Get the last save time
  DateTime? get lastSaved => _lastSaved;

  /// Get the last error message
  String? get lastError => _lastError;

  /// Check if auto-save is currently in progress
  bool get isAutoSaving => _isAutoSaving;

  /// Dispose of resources
  void dispose() {
    cancelAutoSave();
  }
}

enum AutoSaveStatus {
  idle,
  saving,
  saved,
  error,
}

/// Provider for the auto-save service
final autoSaveServiceProvider = Provider<AutoSaveService>((ref) {
  final templateDao = TemplateDao();
  final service = AutoSaveService(templateDao);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for auto-save status
final autoSaveStatusProvider = StateProvider<AutoSaveStatus>((ref) {
  return AutoSaveStatus.idle;
});

/// Provider for last saved time
final lastSavedProvider = StateProvider<DateTime?>((ref) {
  return null;
});
