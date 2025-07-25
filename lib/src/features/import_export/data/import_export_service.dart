import 'dart:io';
import 'dart:isolate';
import 'dart:convert';
import 'package:client_connect/src/core/models/database.dart';
import 'package:client_connect/src/core/services/database_service.dart';
import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:csv/csv.dart';
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import '../../clients/data/client_model.dart';


class ImportExportService {
  static ImportExportService? _instance;
  static ImportExportService get instance => _instance ??= ImportExportService._();
  ImportExportService._();

  // Import clients from file
  Future<ImportResult> importClients({
    required String filePath,
    required ImportExportSettings settings,
    required Function(ImportProgress) onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Read and parse file
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File not found: $filePath');
      }

      final content = await file.readAsString();
      List<List<dynamic>> rows;

      switch (settings.format) {
        case ImportExportFormat.csv:
          rows = const CsvToListConverter().convert(
            content,
            fieldDelimiter: settings.delimiter,
            shouldParseNumbers: false,
          );
          break;
        case ImportExportFormat.json:
          final jsonData = jsonDecode(content) as List;
          rows = _convertJsonToRows(jsonData);
          break;
        default:
          throw Exception('Unsupported import format: ${settings.format}');
      }

      if (rows.isEmpty) {
        throw Exception('No data found in file');
      }

      // Process headers
      List<String> headers = [];
      int dataStartRow = 0;
      
      if (settings.includeHeaders && rows.isNotEmpty) {
        headers = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();
        dataStartRow = 1;
      } else {
        // Default headers if no headers in file
        headers = ['first_name', 'last_name', 'email', 'phone', 'company', 'job_title', 'address', 'notes'];
      }

      final dataRows = rows.skip(dataStartRow).toList();
      
      if (dataRows.isEmpty) {
        throw Exception('No data rows found in file');
      }

      // Process import in background
      return await _processImportInBackground(
        dataRows: dataRows,
        headers: headers,
        settings: settings,
        onProgress: onProgress,
        processingTime: stopwatch,
      );

    } catch (e) {
      stopwatch.stop();
      return ImportResult(
        totalRecords: 0,
        successfulImports: 0,
        failedImports: 0,
        errors: [ImportError(
          rowNumber: 0,
          field: 'file',
          value: filePath,
          errorMessage: e.toString(),
        )],
        processingTime: stopwatch.elapsed,
      );
    }
  }

  // Export clients to file
  Future<ExportResult> exportClients({
    required List<ClientModel> clients,
    required String fileName,
    required ImportExportSettings settings,
    required Function(ExportProgress) onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Get documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(documentsDir.path, 'Client Connect', 'Exports'));
      
      if (!exportDir.existsSync()) {
        exportDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileExtension = _getFileExtension(settings.format);
      final filePath = p.join(exportDir.path, '${fileName}_$timestamp.$fileExtension');

      // Process export in background
      return await _processExportInBackground(
        clients: clients,
        filePath: filePath,
        settings: settings,
        onProgress: onProgress,
        processingTime: stopwatch,
      );

    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }

  // Background import processing
  Future<ImportResult> _processImportInBackground({
    required List<List<dynamic>> dataRows,
    required List<String> headers,
    required ImportExportSettings settings,
    required Function(ImportProgress) onProgress,
    required Stopwatch processingTime,
  }) async {
    final receivePort = ReceivePort();
    final isolateData = ImportIsolateData(
      dataRows: dataRows,
      headers: headers,
      settings: settings,
      sendPort: receivePort.sendPort,
      databasePath: DatabaseService.instance.dbPath,
    );

    // Spawn isolate for background processing
    await Isolate.spawn(_importIsolateEntryPoint, isolateData);

    ImportResult? result;
    await for (final message in receivePort) {
      if (message is ImportProgress) {
        onProgress(message);
      } else if (message is ImportResult) {
        result = message;
        break;
      } else if (message is String && message.startsWith('ERROR:')) {
        throw Exception(message.substring(6));
      }
    }

    receivePort.close();
    processingTime.stop();

    return result?.copyWith(processingTime: processingTime.elapsed) ?? 
           ImportResult(
             totalRecords: dataRows.length,
             successfulImports: 0,
             failedImports: dataRows.length,
             errors: [ImportError(
               rowNumber: 0,
               field: 'process',
               value: 'import',
               errorMessage: 'Import process failed unexpectedly',
             )],
             processingTime: processingTime.elapsed,
           );
  }

  // Background export processing
  Future<ExportResult> _processExportInBackground({
    required List<ClientModel> clients,
    required String filePath,
    required ImportExportSettings settings,
    required Function(ExportProgress) onProgress,
    required Stopwatch processingTime,
  }) async {
    final receivePort = ReceivePort();
    final isolateData = ExportIsolateData(
      clients: clients,
      filePath: filePath,
      settings: settings,
      sendPort: receivePort.sendPort,
    );

    // Spawn isolate for background processing
    await Isolate.spawn(_exportIsolateEntryPoint, isolateData);

    ExportResult? result;
    await for (final message in receivePort) {
      if (message is ExportProgress) {
        onProgress(message);
      } else if (message is ExportResult) {
        result = message;
        break;
      } else if (message is String && message.startsWith('ERROR:')) {
        throw Exception(message.substring(6));
      }
    }

    receivePort.close();
    processingTime.stop();

    return result?.copyWith(processingTime: processingTime.elapsed) ?? 
           ExportResult(
             totalRecords: clients.length,
             filePath: filePath,
             processingTime: processingTime.elapsed,
             fileSize: 0,
           );
  }

  // Helper methods
  List<List<dynamic>> _convertJsonToRows(List jsonData) {
    if (jsonData.isEmpty) return [];
    
    final firstItem = jsonData.first as Map<String, dynamic>;
    final headers = firstItem.keys.toList();
    final rows = <List<dynamic>>[headers];
    
    for (final item in jsonData) {
      final map = item as Map<String, dynamic>;
      final row = headers.map((header) => map[header] ?? '').toList();
      rows.add(row);
    }
    
    return rows;
  }

  String _getFileExtension(ImportExportFormat format) {
    switch (format) {
      case ImportExportFormat.csv:
        return 'csv';
      case ImportExportFormat.excel:
        return 'xlsx';
      case ImportExportFormat.json:
        return 'json';
    }
  }

  // File picker methods
  Future<String?> pickImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json', 'xlsx'],
      allowMultiple: false,
    );

    return result?.files.single.path;
  }

  Future<String?> pickExportLocation(String defaultFileName) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Clients',
      fileName: defaultFileName,
      allowedExtensions: ['csv', 'json'],
      type: FileType.custom,
    );

    return result;
  }
}

// Isolate data classes
class ImportIsolateData {
  final List<List<dynamic>> dataRows;
  final List<String> headers;
  final ImportExportSettings settings;
  final SendPort sendPort;
  final String databasePath;

  ImportIsolateData({
    required this.dataRows,
    required this.headers,
    required this.settings,
    required this.sendPort,
    required this.databasePath,
  });
}

class ExportIsolateData {
  final List<ClientModel> clients;
  final String filePath;
  final ImportExportSettings settings;
  final SendPort sendPort;

  ExportIsolateData({
    required this.clients,
    required this.filePath,
    required this.settings,
    required this.sendPort,
  });
}

// Import isolate entry point
void _importIsolateEntryPoint(ImportIsolateData data) async {
  try {
    final errors = <ImportError>[];
    int successfulImports = 0;
    int processedRecords = 0;

    // Initialize database connection in isolate using a copy path from database sevice
    // Initialize a new AppDatabase instance directly in the isolate
    final file = File(data.databasePath);
    final db = AppDatabase(NativeDatabase(file));


    // Map headers to field indices
    final fieldMap = <String, int>{};
    for (int i = 0; i < data.headers.length; i++) {
      final header = data.headers[i].toLowerCase().trim();
      fieldMap[header] = i;
    }

    // Process each row
    for (int rowIndex = 0; rowIndex < data.dataRows.length; rowIndex++) {
      final row = data.dataRows[rowIndex];
      final rowNumber = rowIndex + 2; // +2 because of 0-based index and header row

      try {
        // Send progress update
        data.sendPort.send(ImportProgress(
          processedRecords: processedRecords,
          totalRecords: data.dataRows.length,
          currentOperation: 'Processing row $rowNumber',
        ));

        // Skip empty rows if configured
        if (data.settings.skipEmptyRows && _isRowEmpty(row)) {
          processedRecords++;
          continue;
        }

        // Extract client data
        final clientData = _extractClientData(row, fieldMap, data.settings);
        
        // Validate required fields
        final validationErrors = _validateClientData(clientData, rowNumber);
        if (validationErrors.isNotEmpty) {
          errors.addAll(validationErrors);
          processedRecords++;
          continue;
        }

        // Check for duplicates if not allowed
        if (!data.settings.allowDuplicates) {
          final existingClient = await _findDuplicateClient(db, clientData);
          if (existingClient != null) {
            errors.add(ImportError(
              rowNumber: rowNumber,
              field: 'email',
              value: clientData['email'] ?? '',
              errorMessage: 'Duplicate client found (existing ID: ${existingClient.id})',
            ));
            processedRecords++;
            continue;
          }
        }

        // Insert client
        await db.into(db.clients).insert(ClientsCompanion.insert(
          firstName: clientData['firstName']!,
          lastName: clientData['lastName']!,
          email: Value(clientData['email']),
          phone: Value(clientData['phone']),
          company: Value(clientData['company']),
          jobTitle: Value(clientData['jobTitle']),
          address: Value(clientData['address']),
          notes: Value(clientData['notes']),
        ));

        successfulImports++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: rowNumber,
          field: 'row',
          value: row.toString(),
          errorMessage: e.toString(),
        ));
      }

      processedRecords++;
    }

    // Send final result
    data.sendPort.send(ImportResult(
      totalRecords: data.dataRows.length,
      successfulImports: successfulImports,
      failedImports: data.dataRows.length - successfulImports,
      errors: errors,
      processingTime: Duration.zero, // Will be set by caller
    ));

    await db.close(); // Close the isolate-specific database connection
  } catch (e) {
    data.sendPort.send('ERROR: $e');
  }
}

// Export isolate entry point
void _exportIsolateEntryPoint(ExportIsolateData data) async {
  try {
    final file = File(data.filePath);
    
    switch (data.settings.format) {
      case ImportExportFormat.csv:
        await _exportToCsv(file, data.clients, data.settings, data.sendPort);
        break;
      case ImportExportFormat.json:
        await _exportToJson(file, data.clients, data.settings, data.sendPort);
        break;
      default:
        throw Exception('Unsupported export format: ${data.settings.format}');
    }

    final fileSize = await file.length();
    
    data.sendPort.send(ExportResult(
      totalRecords: data.clients.length,
      filePath: data.filePath,
      processingTime: Duration.zero, // Will be set by caller
      fileSize: fileSize,
    ));
  } catch (e) {
    data.sendPort.send('ERROR: $e');
  }
}

// Helper functions for isolates
bool _isRowEmpty(List<dynamic> row) {
  return row.every((cell) => cell == null || cell.toString().trim().isEmpty);
}

Map<String, String?> _extractClientData(
  List<dynamic> row,
  Map<String, int> fieldMap,
  ImportExportSettings settings,
) {
  String? getValue(String fieldName) {
    final index = fieldMap[fieldName];
    if (index == null || index >= row.length) return null;
    final value = row[index]?.toString().trim();
    return value?.isEmpty == true ? null : value;
  }

  return {
    'firstName': getValue('first_name') ?? getValue('firstname') ?? getValue('first name'),
    'lastName': getValue('last_name') ?? getValue('lastname') ?? getValue('last name'),
    'email': getValue('email') ?? getValue('email_address') ?? getValue('email address'),
    'phone': getValue('phone') ?? getValue('phone_number') ?? getValue('phone number') ?? getValue('mobile'),
    'company': getValue('company') ?? getValue('organization') ?? getValue('business'),
    'jobTitle': getValue('job_title') ?? getValue('jobtitle') ?? getValue('job title') ?? getValue('position'),
    'address': getValue('address') ?? getValue('location'),
    'notes': getValue('notes') ?? getValue('comments') ?? getValue('description'),
  };
}

List<ImportError> _validateClientData(Map<String, String?> clientData, int rowNumber) {
  final errors = <ImportError>[];

  // Validate required fields
  if (clientData['firstName']?.isEmpty != false) {
    errors.add(ImportError(
      rowNumber: rowNumber,
      field: 'first_name',
      value: clientData['firstName'] ?? '',
      errorMessage: 'First name is required',
    ));
  }

  if (clientData['lastName']?.isEmpty != false) {
    errors.add(ImportError(
      rowNumber: rowNumber,
      field: 'last_name',
      value: clientData['lastName'] ?? '',
      errorMessage: 'Last name is required',
    ));
  }

  // Validate email format if provided
  final email = clientData['email'];
  if (email != null && email.isNotEmpty) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      errors.add(ImportError(
        rowNumber: rowNumber,
        field: 'email',
        value: email,
        errorMessage: 'Invalid email format',
      ));
    }
  }

  return errors;
}

Future<Client?> _findDuplicateClient(AppDatabase db, Map<String, String?> clientData) async {
  final email = clientData['email'];
  if (email == null || email.isEmpty) return null;

  final query = db.select(db.clients)..where((c) => c.email.equals(email));
  return await query.getSingleOrNull();
}

Future<void> _exportToCsv(
  File file,
  List<ClientModel> clients,
  ImportExportSettings settings,
  SendPort sendPort,
) async {
  final rows = <List<String>>[];
  
  // Add headers if configured
  if (settings.includeHeaders) {
    rows.add([
      'First Name',
      'Last Name',
      'Email',
      'Phone',
      'Company',
      'Job Title',
      'Address',
      'Notes',
      'Created At',
      'Updated At',
    ]);
  }

  // Add client data
  for (int i = 0; i < clients.length; i++) {
    final client = clients[i];
    
    sendPort.send(ExportProgress(
      processedRecords: i,
      totalRecords: clients.length,
      currentOperation: 'Exporting ${client.fullName}',
    ));

    rows.add([
      client.firstName,
      client.lastName,
      client.email ?? '',
      client.phone ?? '',
      client.company ?? '',
      client.jobTitle ?? '',
      client.address ?? '',
      client.notes ?? '',
      client.createdAt.toIso8601String(),
      client.updatedAt.toIso8601String(),
    ]);
  }

  // Convert to CSV and write to file
  final csvData = const ListToCsvConverter(fieldDelimiter: ',').convert(rows);
  await file.writeAsString(csvData);
}

Future<void> _exportToJson(
  File file,
  List<ClientModel> clients,
  ImportExportSettings settings,
  SendPort sendPort,
) async {
  final jsonData = <Map<String, dynamic>>[];

  for (int i = 0; i < clients.length; i++) {
    final client = clients[i];
    
    sendPort.send(ExportProgress(
      processedRecords: i,
      totalRecords: clients.length,
      currentOperation: 'Exporting ${client.fullName}',
    ));

    jsonData.add({
      'id': client.id,
      'firstName': client.firstName,
      'lastName': client.lastName,
      'email': client.email,
      'phone': client.phone,
      'company': client.company,
      'jobTitle': client.jobTitle,
      'address': client.address,
      'notes': client.notes,
      'createdAt': client.createdAt.toIso8601String(),
      'updatedAt': client.updatedAt.toIso8601String(),
    });
  }

  // Write JSON to file
  final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
  await file.writeAsString(jsonString);
}

// Extension to add copyWith method to ImportResult and ExportResult
extension ImportResultExtension on ImportResult {
  ImportResult copyWith({
    int? totalRecords,
    int? successfulImports,
    int? failedImports,
    List<ImportError>? errors,
    Duration? processingTime,
  }) {
    return ImportResult(
      totalRecords: totalRecords ?? this.totalRecords,
      successfulImports: successfulImports ?? this.successfulImports,
      failedImports: failedImports ?? this.failedImports,
      errors: errors ?? this.errors,
      processingTime: processingTime ?? this.processingTime,
    );
  }
}

extension ExportResultExtension on ExportResult {
  ExportResult copyWith({
    int? totalRecords,
    String? filePath,
    Duration? processingTime,
    int? fileSize,
  }) {
    return ExportResult(
      totalRecords: totalRecords ?? this.totalRecords,
      filePath: filePath ?? this.filePath,
      processingTime: processingTime ?? this.processingTime,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}
