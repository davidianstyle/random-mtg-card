import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

// Conditional imports for different platforms
import 'dart:io' if (dart.library.js) 'io_web_stubs.dart';
import 'package:path_provider/path_provider.dart'
    if (dart.library.js) 'io_web_stubs.dart';

enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  critical(4);

  const LogLevel(this.value);
  final int value;
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? component;
  final Map<String, dynamic>? context;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.component,
    this.context,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'message': message,
        if (component != null) 'component': component,
        if (context != null) 'context': context,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      };

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${level.name.toUpperCase()}] ');
    if (component != null) buffer.write('[$component] ');
    buffer.write(message);
    if (context != null) {
      buffer.write(' | Context: ${jsonEncode(context)}');
    }
    if (error != null) {
      buffer.write(' | Error: $error');
    }
    return buffer.toString();
  }
}

class Logger {
  static Logger? _instance;
  static Logger get instance => _instance ??= Logger._();

  Logger._();

  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  final List<LogHandler> _handlers = [];
  final StreamController<LogEntry> _logStream =
      StreamController<LogEntry>.broadcast();

  Stream<LogEntry> get logStream => _logStream.stream;

  static Future<void> initialize({
    LogLevel minLevel = LogLevel.info,
    bool enableFileLogging = true,
    bool enableConsoleLogging = true,
    int maxLogFiles = 5,
    int maxLogSizeMB = 10,
  }) async {
    final logger = Logger.instance;
    logger._minLevel = minLevel;

    if (enableConsoleLogging) {
      logger.addHandler(ConsoleLogHandler());
    }

    if (enableFileLogging) {
      final fileHandler = await FileLogHandler.create(
        maxFiles: maxLogFiles,
        maxSizeMB: maxLogSizeMB,
      );
      logger.addHandler(fileHandler);
    }
  }

  void addHandler(LogHandler handler) {
    _handlers.add(handler);
  }

  void removeHandler(LogHandler handler) {
    _handlers.remove(handler);
  }

  void log(
    LogLevel level,
    String message, {
    String? component,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.value < _minLevel.value) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      component: component,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );

    _logStream.add(entry);

    for (final handler in _handlers) {
      handler.handle(entry);
    }
  }

  void debug(String message,
      {String? component, Map<String, dynamic>? context}) {
    log(LogLevel.debug, message, component: component, context: context);
  }

  void info(String message,
      {String? component, Map<String, dynamic>? context}) {
    log(LogLevel.info, message, component: component, context: context);
  }

  void warning(String message,
      {String? component, Map<String, dynamic>? context, Object? error}) {
    log(LogLevel.warning, message,
        component: component, context: context, error: error);
  }

  void error(String message,
      {String? component,
      Map<String, dynamic>? context,
      Object? error,
      StackTrace? stackTrace}) {
    log(LogLevel.error, message,
        component: component,
        context: context,
        error: error,
        stackTrace: stackTrace);
  }

  void critical(String message,
      {String? component,
      Map<String, dynamic>? context,
      Object? error,
      StackTrace? stackTrace}) {
    log(LogLevel.critical, message,
        component: component,
        context: context,
        error: error,
        stackTrace: stackTrace);
  }

  void dispose() {
    _logStream.close();
    for (final handler in _handlers) {
      handler.dispose();
    }
    _handlers.clear();
  }
}

abstract class LogHandler {
  void handle(LogEntry entry);
  void dispose() {}
}

class ConsoleLogHandler extends LogHandler {
  @override
  void handle(LogEntry entry) {
    if (kDebugMode) {
      // Use developer.log in debug mode for better IDE integration
      developer.log(
        entry.message,
        name: entry.component ?? 'App',
        level: entry.level.value,
        error: entry.error,
        stackTrace: entry.stackTrace,
        time: entry.timestamp,
      );
    } else {
      // Use debugPrint in release mode
      debugPrint(entry.toString());
    }
  }
}

class FileLogHandler extends LogHandler {
  final String _logDirectory;
  final int _maxFiles;
  final int _maxSizeMB;
  File? _currentLogFile;
  IOSink? _logSink;

  FileLogHandler._(this._logDirectory, this._maxFiles, this._maxSizeMB);

  static Future<FileLogHandler> create({
    int maxFiles = 5,
    int maxSizeMB = 10,
  }) async {
    final String logDir;
    if (kIsWeb) {
      // On web, use a dummy path since file logging isn't supported
      logDir = '/tmp/logs';
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      logDir = path.join(appDir.path, 'logs');
      await Directory(logDir).create(recursive: true);
    }

    final handler = FileLogHandler._(logDir, maxFiles, maxSizeMB);
    if (!kIsWeb) {
      await handler._initializeLogFile();
    }
    return handler;
  }

  Future<void> _initializeLogFile() async {
    if (kIsWeb) {
      // File logging not supported on web
      return;
    }

    final now = DateTime.now();
    final filename =
        'app_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.log';
    _currentLogFile = File(path.join(_logDirectory, filename));

    // Rotate if file is too large
    if (await _currentLogFile!.exists()) {
      final size = await _currentLogFile!.length();
      if (size > _maxSizeMB * 1024 * 1024) {
        await _rotateLogFile();
      }
    }

    _logSink = _currentLogFile!.openWrite(mode: FileMode.append);
    await _cleanupOldLogs();
  }

  Future<void> _rotateLogFile() async {
    if (_currentLogFile == null) return;

    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final baseName = path.basenameWithoutExtension(_currentLogFile!.path);
    final rotatedName = '${baseName}_$timestamp.log';
    final rotatedFile = File(path.join(_logDirectory, rotatedName));

    await _logSink?.close();
    await _currentLogFile!.rename(rotatedFile.path);

    // Create new log file
    _currentLogFile = File(path.join(_logDirectory, '$baseName.log'));
    _logSink = _currentLogFile!.openWrite();
  }

  Future<void> _cleanupOldLogs() async {
    final logDir = Directory(_logDirectory);
    final files = await logDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.log'))
        .cast<File>()
        .toList();

    if (files.length > _maxFiles) {
      files
          .sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      for (int i = 0; i < files.length - _maxFiles; i++) {
        await files[i].delete();
      }
    }
  }

  @override
  void handle(LogEntry entry) {
    if (!kIsWeb) {
      _logSink?.writeln(jsonEncode(entry.toJson()));
    }
  }

  @override
  void dispose() {
    _logSink?.close();
  }
}

// Mixin for easier logging in any class
mixin LoggerExtension {
  Logger get logger => Logger.instance;

  void logDebug(String message, {Map<String, dynamic>? context}) {
    logger.debug(message, component: runtimeType.toString(), context: context);
  }

  void logInfo(String message, {Map<String, dynamic>? context}) {
    logger.info(message, component: runtimeType.toString(), context: context);
  }

  void logWarning(String message,
      {Map<String, dynamic>? context, Object? error}) {
    logger.warning(message,
        component: runtimeType.toString(), context: context, error: error);
  }

  void logError(String message,
      {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    logger.error(message,
        component: runtimeType.toString(),
        context: context,
        error: error,
        stackTrace: stackTrace);
  }

  void logCritical(String message,
      {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) {
    logger.critical(message,
        component: runtimeType.toString(),
        context: context,
        error: error,
        stackTrace: stackTrace);
  }
}
