import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';
import '../utils/result.dart';

// Conditional imports for different platforms
import 'dart:io' if (dart.library.js) 'cache_service_web.dart';
import 'package:path_provider/path_provider.dart' if (dart.library.js) 'cache_service_web.dart';

// Cache entry with metadata
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  CacheEntry({
    required this.data,
    required this.timestamp,
    this.expiresAt,
    this.metadata = const {},
  });

  bool get isExpired => expiresAt?.isBefore(DateTime.now()) ?? false;
  Duration get age => DateTime.now().difference(timestamp);

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'metadata': metadata,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry<T>(
      data: json['data'] as T,
      timestamp: DateTime.parse(json['timestamp']),
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

// Cache configuration
class CacheConfig {
  final int maxMemoryEntries;
  final int maxDiskSizeMB;
  final Duration defaultTtl;
  final Duration cleanupInterval;
  final bool enableDiskCache;
  final bool enableMemoryCache;

  const CacheConfig({
    this.maxMemoryEntries = 100,
    this.maxDiskSizeMB = 500,
    this.defaultTtl = const Duration(hours: 24),
    this.cleanupInterval = const Duration(hours: 1),
    this.enableDiskCache = true,
    this.enableMemoryCache = true,
  });
}

// Abstract cache interface
abstract class Cache<T> {
  Future<Result<T>> get(String key);
  Future<Result<void>> put(String key, T value, {Duration? ttl});
  Future<Result<void>> delete(String key);
  Future<Result<void>> clear();
  Future<Result<bool>> exists(String key);
  Future<Result<int>> size();
}

// LRU Cache implementation
class LRUCache<T> extends Cache<T> {
  final int maxSize;
  final Duration defaultTtl;
  final LinkedHashMap<String, CacheEntry<T>> _cache = LinkedHashMap();

  LRUCache({
    required this.maxSize,
    this.defaultTtl = const Duration(hours: 1),
  });

  @override
  Future<Result<T>> get(String key) async {
    final entry = _cache.remove(key);
    if (entry == null) {
      return const Failure(CacheError(message: 'Cache miss'));
    }

    if (entry.isExpired) {
      return const Failure(CacheError(message: 'Cache entry expired'));
    }

    // Move to end (most recently used)
    _cache[key] = entry;
    return Success(entry.data);
  }

  @override
  Future<Result<void>> put(String key, T value, {Duration? ttl}) async {
    final effectiveTtl = ttl ?? defaultTtl;
    final entry = CacheEntry<T>(
      data: value,
      timestamp: DateTime.now(),
      expiresAt: DateTime.now().add(effectiveTtl),
    );

    _cache.remove(key);
    _cache[key] = entry;

    // Remove oldest if over capacity
    if (_cache.length > maxSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    _cache.remove(key);
    return const Success(null);
  }

  @override
  Future<Result<void>> clear() async {
    _cache.clear();
    return const Success(null);
  }

  @override
  Future<Result<bool>> exists(String key) async {
    return Success(_cache.containsKey(key));
  }

  @override
  Future<Result<int>> size() async {
    return Success(_cache.length);
  }

  void cleanup() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => entry.expiresAt?.isBefore(now) ?? false);
  }
}

// File cache implementation
class FileCache extends Cache<Uint8List> {
  final String _cacheDir;
  final int _maxSizeMB;
  final Duration _defaultTtl;

  FileCache._({
    required String cacheDir,
    required int maxSizeMB,
    required Duration defaultTtl,
  })  : _cacheDir = cacheDir,
        _maxSizeMB = maxSizeMB,
        _defaultTtl = defaultTtl;

  static Future<FileCache> create({
    String? cacheDir,
    int maxSizeMB = 500,
    Duration defaultTtl = const Duration(days: 7),
  }) async {
    final String effectiveCacheDir;
    if (cacheDir != null) {
      effectiveCacheDir = cacheDir;
    } else {
      if (kIsWeb) {
        // On web, use in-memory cache only
        effectiveCacheDir = '/tmp/cache'; // This won't be used on web
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        effectiveCacheDir = path.join(appDir.path, 'cache');
      }
    }

    if (!kIsWeb) {
      await Directory(effectiveCacheDir).create(recursive: true);
    }
    
    return FileCache._(
      cacheDir: effectiveCacheDir,
      maxSizeMB: maxSizeMB,
      defaultTtl: defaultTtl,
    );
  }

  String _getKeyHash(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  File _getCacheFile(String key) {
    final hash = _getKeyHash(key);
    return File(path.join(_cacheDir, '$hash.cache'));
  }

  File _getMetadataFile(String key) {
    final hash = _getKeyHash(key);
    return File(path.join(_cacheDir, '$hash.meta'));
  }

  @override
  Future<Result<Uint8List>> get(String key) async {
    if (kIsWeb) {
      // Web doesn't support file caching, always return cache miss
      return const Failure(CacheError(message: 'Cache miss - web mode'));
    }
    
    try {
      final cacheFile = _getCacheFile(key);
      final metaFile = _getMetadataFile(key);

      if (!await cacheFile.exists() || !await metaFile.exists()) {
        return const Failure(CacheError(message: 'Cache miss'));
      }

      // Check metadata
      final metaContent = await metaFile.readAsString();
      final metadata = jsonDecode(metaContent) as Map<String, dynamic>;
      final expiresAt = metadata['expiresAt'] != null
          ? DateTime.parse(metadata['expiresAt'])
          : null;

      if (expiresAt?.isBefore(DateTime.now()) ?? false) {
        await delete(key);
        return const Failure(CacheError(message: 'Cache entry expired'));
      }

      final data = await cacheFile.readAsBytes();
      return Success(Uint8List.fromList(data));
    } catch (e) {
      return Failure(
          CacheError(message: 'Failed to read cache', originalError: e));
    }
  }

  @override
  Future<Result<void>> put(String key, Uint8List value, {Duration? ttl}) async {
    if (kIsWeb) {
      // Web doesn't support file caching, return success but don't actually cache
      return const Success(null);
    }
    
    try {
      final cacheFile = _getCacheFile(key);
      final metaFile = _getMetadataFile(key);
      final effectiveTtl = ttl ?? _defaultTtl;

      // Write data
      await cacheFile.writeAsBytes(value);

      // Write metadata
      final metadata = {
        'timestamp': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(effectiveTtl).toIso8601String(),
        'size': value.length,
      };
      await metaFile.writeAsString(jsonEncode(metadata));

      // Check cache size and cleanup if needed
      await _cleanupIfNeeded();

      return const Success(null);
    } catch (e) {
      return Failure(
          CacheError(message: 'Failed to write cache', originalError: e));
    }
  }

  @override
  Future<Result<void>> delete(String key) async {
    if (kIsWeb) {
      // Web doesn't support file caching, return success
      return const Success(null);
    }
    
    try {
      final cacheFile = _getCacheFile(key);
      final metaFile = _getMetadataFile(key);

      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
      if (await metaFile.exists()) {
        await metaFile.delete();
      }

      return const Success(null);
    } catch (e) {
      return Failure(
          CacheError(message: 'Failed to delete cache', originalError: e));
    }
  }

  @override
  Future<Result<void>> clear() async {
    if (kIsWeb) {
      // Web doesn't support file caching, return success
      return const Success(null);
    }
    
    try {
      final cacheDir = Directory(_cacheDir);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
      return const Success(null);
    } catch (e) {
      return Failure(
          CacheError(message: 'Failed to clear cache', originalError: e));
    }
  }

  @override
  Future<Result<bool>> exists(String key) async {
    final cacheFile = _getCacheFile(key);
    final metaFile = _getMetadataFile(key);
    return Success(await cacheFile.exists() && await metaFile.exists());
  }

  @override
  Future<Result<int>> size() async {
    try {
      final cacheDir = Directory(_cacheDir);
      if (!await cacheDir.exists()) return const Success(0);

      int totalSize = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return Success(totalSize);
    } catch (e) {
      return Failure(
          CacheError(message: 'Failed to get cache size', originalError: e));
    }
  }

  Future<void> _cleanupIfNeeded() async {
    final sizeResult = await size();
    if (sizeResult.isFailure) return;

    final currentSize = sizeResult.dataOrNull ?? 0;
    final maxSize = _maxSizeMB * 1024 * 1024;

    if (currentSize > maxSize) {
      await _cleanupOldEntries();
    }
  }

  Future<void> _cleanupOldEntries() async {
    try {
      final cacheDir = Directory(_cacheDir);
      final files = <FileSystemEntity>[];

      await for (final entity in cacheDir.list()) {
        if (entity.path.endsWith('.meta')) {
          files.add(entity);
        }
      }

      // Sort by modification time (oldest first)
      // Cast to File since we know these are .meta files
      files.sort((a, b) => (a as File).lastModifiedSync().compareTo((b as File).lastModifiedSync()));

      // Remove oldest files until under limit
      for (final file in files) {
        final sizeResult = await size();
        if (sizeResult.isFailure) break;

        final currentSize = sizeResult.dataOrNull ?? 0;
        if (currentSize <= _maxSizeMB * 1024 * 1024 * 0.8) break; // 80% of max

        final baseName = path.basenameWithoutExtension(file.path);
        final cacheFile = File(path.join(_cacheDir, '$baseName.cache'));

        if (await file.exists()) await file.delete();
        if (await cacheFile.exists()) await cacheFile.delete();
      }
    } catch (e) {
      Logger.instance.error('Failed to cleanup cache', error: e);
    }
  }

  Future<void> cleanup() async {
    try {
      final cacheDir = Directory(_cacheDir);
      if (!await cacheDir.exists()) return;

      final now = DateTime.now();
      await for (final entity in cacheDir.list()) {
        if (entity.path.endsWith('.meta')) {
          try {
            final content = await (entity as File).readAsString();
            final metadata = jsonDecode(content) as Map<String, dynamic>;
            final expiresAt = metadata['expiresAt'] != null
                ? DateTime.parse(metadata['expiresAt'])
                : null;

            if (expiresAt?.isBefore(now) ?? false) {
              final baseName = path.basenameWithoutExtension(entity.path);
              final cacheFile = File(path.join(_cacheDir, '$baseName.cache'));

              if (await entity.exists()) await entity.delete();
              if (await cacheFile.exists()) await cacheFile.delete();
            }
          } catch (e) {
            // Delete corrupted files
            if (await entity.exists()) await entity.delete();
          }
        }
      }
    } catch (e) {
      Logger.instance
          .error('Failed to cleanup expired cache entries', error: e);
    }
  }
}

// Main cache service
class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._();

  CacheService._();

  late final LRUCache<String> _apiCache;
  late final LRUCache<Uint8List> _memoryImageCache;
  late final FileCache _diskImageCache;
  Timer? _cleanupTimer;

  static Future<CacheService> create({CacheConfig? config}) async {
    final service = CacheService.instance;
    await service._initialize(config ?? const CacheConfig());
    return service;
  }

  Future<void> _initialize(CacheConfig config) async {
    _apiCache = LRUCache<String>(
      maxSize: config.maxMemoryEntries,
      defaultTtl: config.defaultTtl,
    );

    _memoryImageCache = LRUCache<Uint8List>(
      maxSize: config.maxMemoryEntries ~/ 2,
      defaultTtl: config.defaultTtl,
    );

    _diskImageCache = await FileCache.create(
      maxSizeMB: config.maxDiskSizeMB,
      defaultTtl: config.defaultTtl,
    );

    // Start cleanup timer
    _cleanupTimer = Timer.periodic(config.cleanupInterval, (_) => _cleanup());
  }

  // API response caching
  Future<Result<String>> getApiResponse(String url) async {
    return _apiCache.get(url);
  }

  Future<Result<void>> cacheApiResponse(String url, String response,
      {Duration? ttl}) async {
    return _apiCache.put(url, response, ttl: ttl);
  }

  // Image caching
  Future<Result<Uint8List>> getImage(String url) async {
    // Try memory cache first
    final memoryResult = await _memoryImageCache.get(url);
    if (memoryResult.isSuccess) {
      return memoryResult;
    }

    // Try disk cache
    final diskResult = await _diskImageCache.get(url);
    if (diskResult.isSuccess) {
      // Put back in memory for faster access
      final data = diskResult.dataOrNull!;
      await _memoryImageCache.put(url, data);
      return diskResult;
    }

    return const Failure(CacheError(message: 'Image not found in cache'));
  }

  Future<Result<void>> cacheImage(String url, Uint8List data,
      {Duration? ttl}) async {
    // Store in both memory and disk
    await _memoryImageCache.put(url, data, ttl: ttl);
    await _diskImageCache.put(url, data, ttl: ttl);
    return const Success(null);
  }

  // Cache statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final apiSizeResult = await _apiCache.size();
    final memorySizeResult = await _memoryImageCache.size();
    final diskSizeResult = await _diskImageCache.size();

    return {
      'api_cache_entries': apiSizeResult.dataOrNull ?? 0,
      'memory_image_entries': memorySizeResult.dataOrNull ?? 0,
      'disk_cache_size_bytes': diskSizeResult.dataOrNull ?? 0,
    };
  }

  // Clear all caches
  Future<void> clearAll() async {
    await _apiCache.clear();
    await _memoryImageCache.clear();
    await _diskImageCache.clear();
  }

  Future<void> _cleanup() async {
    _apiCache.cleanup();
    _memoryImageCache.cleanup();
    await _diskImageCache.cleanup();
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }
}
