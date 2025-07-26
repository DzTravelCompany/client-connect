class ImportResult {
  final int totalRecords;
  final int successfulImports;
  final int failedImports;
  final List<ImportError> errors;
  final Duration processingTime;

  const ImportResult({
    required this.totalRecords,
    required this.successfulImports,
    required this.failedImports,
    required this.errors,
    required this.processingTime,
  });

  bool get hasErrors => errors.isNotEmpty;
  double get successRate => totalRecords > 0 ? (successfulImports / totalRecords) : 0.0;
}

class ImportError {
  final int rowNumber;
  final String field;
  final String value;
  final String errorMessage;

  const ImportError({
    required this.rowNumber,
    required this.field,
    required this.value,
    required this.errorMessage,
  });
}

class ExportResult {
  final int totalRecords;
  final String filePath;
  final Duration processingTime;
  final int fileSize; // in bytes

  const ExportResult({
    required this.totalRecords,
    required this.filePath,
    required this.processingTime,
    required this.fileSize,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ImportProgress {
  final int processedRecords;
  final int totalRecords;
  final String currentOperation;
  final bool isComplete;

  const ImportProgress({
    required this.processedRecords,
    required this.totalRecords,
    required this.currentOperation,
    this.isComplete = false,
  });

  double get progressPercentage => totalRecords > 0 ? (processedRecords / totalRecords) : 0.0;
}

class ExportProgress {
  final int processedRecords;
  final int totalRecords;
  final String currentOperation;
  final bool isComplete;

  const ExportProgress({
    required this.processedRecords,
    required this.totalRecords,
    required this.currentOperation,
    this.isComplete = false,
  });

  double get progressPercentage => totalRecords > 0 ? (processedRecords / totalRecords) : 0.0;
}

enum ImportExportFormat {
  csv,
  excel,
  json,
}

class ImportExportSettings {
  final ImportExportFormat format;
  final bool includeHeaders;
  final String delimiter; // for CSV
  final bool skipEmptyRows;
  final bool validateEmails;
  final bool allowDuplicates;

  const ImportExportSettings({
    this.format = ImportExportFormat.csv,
    this.includeHeaders = true,
    this.delimiter = ',',
    this.skipEmptyRows = true,
    this.validateEmails = true,
    this.allowDuplicates = false,
  });

  ImportExportSettings copyWith({
    ImportExportFormat? format,
    bool? includeHeaders,
    String? delimiter,
    bool? skipEmptyRows,
    bool? validateEmails,
    bool? allowDuplicates,
  }) {
    return ImportExportSettings(
      format: format ?? this.format,
      includeHeaders: includeHeaders ?? this.includeHeaders,
      delimiter: delimiter ?? this.delimiter,
      skipEmptyRows: skipEmptyRows ?? this.skipEmptyRows,
      validateEmails: validateEmails ?? this.validateEmails,
      allowDuplicates: allowDuplicates ?? this.allowDuplicates,
    );
  }
}