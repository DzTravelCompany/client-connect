import 'dart:io';
import 'package:client_connect/constants.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/database.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  
  DatabaseService._();
  
  AppDatabase? _database;
  AppDatabase get database => _database!;
  String? _dbPath; // Store path for later access

  String get dbPath {
    if (_dbPath == null) {
      throw StateError("Database path is not initialized. Call initialize() first.");
    }
    return _dbPath!;
  }
  
  Future<void> initialize() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    _dbPath = p.join(dbFolder.path, 'client_connect.db');
    final file = File(_dbPath!);
    
    _database = AppDatabase(NativeDatabase(file));

    logger.i('Database file path: ${file.path}');
  }
  
  Future<void> close() async {
    await _database?.close();
  }
}
