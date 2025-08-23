import 'dart:convert';
import 'dart:io';
import 'package:client_connect/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

class WhatsAppMediaCacheManager {
  static const String _cacheFileName = 'whatsapp_media_cache.json';
  
  late File _cacheFile;
  final Map<String, MediaCacheEntry> _memoryCache = {};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(p.join(appDir.path, 'cache'));
      
      // Create cache directory if it doesn't exist
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      _cacheFile = File(p.join(cacheDir.path, _cacheFileName));
      
      // Load existing cache from disk
      await _loadCacheFromDisk();
      
      // Clean expired entries
      await _cleanExpiredEntries();
      
      _initialized = true;
      logger.i('WhatsApp media cache manager initialized');
    } catch (e) {
      logger.e('Failed to initialize media cache manager: $e');
      _initialized = true; // Continue without cache
    }
  }

  Future<void> _loadCacheFromDisk() async {
    try {
      if (await _cacheFile.exists()) {
        final jsonString = await _cacheFile.readAsString();
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);
        
        _memoryCache.clear();
        for (final entry in jsonData.entries) {
          try {
            _memoryCache[entry.key] = MediaCacheEntry.fromJson(entry.value);
          } catch (e) {
            logger.w('Failed to parse cache entry ${entry.key}: $e');
          }
        }
        
        logger.i('Loaded ${_memoryCache.length} media cache entries from disk');
      }
    } catch (e) {
      logger.e('Failed to load cache from disk: $e');
      _memoryCache.clear();
    }
  }

  Future<void> _saveCacheToDisk() async {
    try {
      final jsonData = <String, dynamic>{};
      for (final entry in _memoryCache.entries) {
        jsonData[entry.key] = entry.value.toJson();
      }
      
      final jsonString = jsonEncode(jsonData);
      await _cacheFile.writeAsString(jsonString);
      
      logger.d('Saved ${_memoryCache.length} media cache entries to disk');
    } catch (e) {
      logger.e('Failed to save cache to disk: $e');
    }
  }

  Future<void> _cleanExpiredEntries() async {
    final expiredKeys = <String>[];
    
    for (final entry in _memoryCache.entries) {
      if (!entry.value.isValid) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      logger.i('Cleaned ${expiredKeys.length} expired cache entries');
      await _saveCacheToDisk();
    }
  }

  String _generateCacheKey(String filePath, String fileHash) {
    return '${p.basename(filePath)}_$fileHash';
  }

  Future<String> _calculateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      logger.e('Failed to calculate file hash for ${file.path}: $e');
      // Fallback to file path + modification time
      final stat = await file.stat();
      return sha256.convert('${file.path}_${stat.modified.millisecondsSinceEpoch}'.codeUnits).toString();
    }
  }

  Future<MediaCacheEntry?> getCachedMedia(String filePath) async {
    if (!_initialized) await initialize();
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      final fileHash = await _calculateFileHash(file);
      final cacheKey = _generateCacheKey(filePath, fileHash);
      
      final cachedEntry = _memoryCache[cacheKey];
      if (cachedEntry != null && cachedEntry.isValid) {
        logger.d('Cache hit for $filePath');
        return cachedEntry;
      } else if (cachedEntry != null) {
        // Remove expired entry
        _memoryCache.remove(cacheKey);
        await _saveCacheToDisk();
        logger.d('Removed expired cache entry for $filePath');
      }
      
      return null;
    } catch (e) {
      logger.e('Error checking cache for $filePath: $e');
      return null;
    }
  }

  Future<void> cacheMedia(String filePath, String mediaId) async {
    if (!_initialized) await initialize();
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        logger.w('Cannot cache media for non-existent file: $filePath');
        return;
      }
      
      final fileHash = await _calculateFileHash(file);
      final cacheKey = _generateCacheKey(filePath, fileHash);
      
      final cacheEntry = MediaCacheEntry(
        mediaId: mediaId,
        uploadedAt: DateTime.now(),
        filePath: filePath,
        fileHash: fileHash,
      );
      
      _memoryCache[cacheKey] = cacheEntry;
      await _saveCacheToDisk();
      
      logger.i('Cached media ID for $filePath: $mediaId');
    } catch (e) {
      logger.e('Error caching media for $filePath: $e');
    }
  }

  Future<void> clearCache() async {
    if (!_initialized) await initialize();
    
    try {
      _memoryCache.clear();
      
      if (await _cacheFile.exists()) {
        await _cacheFile.delete();
      }
      
      logger.i('Cleared all media cache entries');
    } catch (e) {
      logger.e('Error clearing cache: $e');
    }
  }

  Future<void> clearExpiredEntries() async {
    if (!_initialized) await initialize();
    await _cleanExpiredEntries();
  }

  int get cacheSize => _memoryCache.length;
  
  List<MediaCacheEntry> get allEntries => _memoryCache.values.toList();
  
  Future<int> getCacheSizeInBytes() async {
    if (!_initialized) await initialize();
    
    try {
      if (await _cacheFile.exists()) {
        final stat = await _cacheFile.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      logger.e('Error getting cache size: $e');
      return 0;
    }
  }
}

class MediaCacheEntry {
  final String mediaId;
  final DateTime uploadedAt;
  final String filePath;
  final String fileHash;

  MediaCacheEntry({
    required this.mediaId,
    required this.uploadedAt,
    required this.filePath,
    required this.fileHash,
  });

  // Check if cache entry is still valid (24 hours)
  bool get isValid => DateTime.now().difference(uploadedAt).inHours < 24;

  Map<String, dynamic> toJson() {
    return {
      'mediaId': mediaId,
      'uploadedAt': uploadedAt.toIso8601String(),
      'filePath': filePath,
      'fileHash': fileHash,
    };
  }

  factory MediaCacheEntry.fromJson(Map<String, dynamic> json) {
    return MediaCacheEntry(
      mediaId: json['mediaId'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      filePath: json['filePath'] as String,
      fileHash: json['fileHash'] as String,
    );
  }

  @override
  String toString() {
    return 'MediaCacheEntry(mediaId: $mediaId, filePath: $filePath, uploadedAt: $uploadedAt, valid: $isValid)';
  }
}