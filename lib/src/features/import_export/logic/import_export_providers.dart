import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/import_export_service.dart';
import '../../clients/data/client_model.dart';

// Import/Export service provider
final importExportServiceProvider = Provider<ImportExportService>((ref) => ImportExportService.instance);

// Import state provider
final importStateProvider = StateNotifierProvider<ImportStateNotifier, ImportState>((ref) {
  return ImportStateNotifier(ref.watch(importExportServiceProvider));
});

// Export state provider
final exportStateProvider = StateNotifierProvider<ExportStateNotifier, ExportState>((ref) {
  return ExportStateNotifier(ref.watch(importExportServiceProvider));
});

// Import/Export settings provider
final importExportSettingsProvider = StateNotifierProvider<ImportExportSettingsNotifier, ImportExportSettings>((ref) {
  return ImportExportSettingsNotifier();
});

// Import State
class ImportState {
  final bool isLoading;
  final ImportProgress? progress;
  final ImportResult? result;
  final String? error;

  const ImportState({
    this.isLoading = false,
    this.progress,
    this.result,
    this.error,
  });

  ImportState copyWith({
    bool? isLoading,
    ImportProgress? progress,
    ImportResult? result,
    String? error,
  }) {
    return ImportState(
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

// Export State
class ExportState {
  final bool isLoading;
  final ExportProgress? progress;
  final ExportResult? result;
  final String? error;

  const ExportState({
    this.isLoading = false,
    this.progress,
    this.result,
    this.error,
  });

  ExportState copyWith({
    bool? isLoading,
    ExportProgress? progress,
    ExportResult? result,
    String? error,
  }) {
    return ExportState(
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

// Import State Notifier
class ImportStateNotifier extends StateNotifier<ImportState> {
  final ImportExportService _service;

  ImportStateNotifier(this._service) : super(const ImportState());

  Future<void> importClients({
    required String filePath,
    required ImportExportSettings settings,
  }) async {
    state = state.copyWith(isLoading: true, error: null, result: null, progress: null);

    try {
      final result = await _service.importClients(
        filePath: filePath,
        settings: settings,
        onProgress: (progress) {
          if (mounted) {
            state = state.copyWith(progress: progress);
          }
        },
      );

      state = state.copyWith(
        isLoading: false,
        result: result,
        progress: ImportProgress(
          processedRecords: result.totalRecords,
          totalRecords: result.totalRecords,
          currentOperation: 'Import completed',
          isComplete: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const ImportState();
  }
}

// Export State Notifier
class ExportStateNotifier extends StateNotifier<ExportState> {
  final ImportExportService _service;

  ExportStateNotifier(this._service) : super(const ExportState());

  Future<void> exportClients({
    required List<ClientModel> clients,
    required String fileName,
    required ImportExportSettings settings,
  }) async {
    state = state.copyWith(isLoading: true, error: null, result: null, progress: null);

    try {
      final result = await _service.exportClients(
        clients: clients,
        fileName: fileName,
        settings: settings,
        onProgress: (progress) {
          if (mounted) {
            state = state.copyWith(progress: progress);
          }
        },
      );

      state = state.copyWith(
        isLoading: false,
        result: result,
        progress: ExportProgress(
          processedRecords: result.totalRecords,
          totalRecords: result.totalRecords,
          currentOperation: 'Export completed',
          isComplete: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const ExportState();
  }
}

// Import/Export Settings Notifier
class ImportExportSettingsNotifier extends StateNotifier<ImportExportSettings> {
  ImportExportSettingsNotifier() : super(const ImportExportSettings());

  void updateSettings(ImportExportSettings settings) {
    state = settings;
  }

  void updateFormat(ImportExportFormat format) {
    state = state.copyWith(format: format);
  }

  void updateIncludeHeaders(bool includeHeaders) {
    state = state.copyWith(includeHeaders: includeHeaders);
  }

  void updateDelimiter(String delimiter) {
    state = state.copyWith(delimiter: delimiter);
  }

  void updateSkipEmptyRows(bool skipEmptyRows) {
    state = state.copyWith(skipEmptyRows: skipEmptyRows);
  }

  void updateValidateEmails(bool validateEmails) {
    state = state.copyWith(validateEmails: validateEmails);
  }

  void updateAllowDuplicates(bool allowDuplicates) {
    state = state.copyWith(allowDuplicates: allowDuplicates);
  }

  void reset() {
    state = const ImportExportSettings();
  }
}