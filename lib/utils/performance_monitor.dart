import 'dart:async';
import 'dart:io';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'logger.dart';

// Performance metrics
class PerformanceMetrics {
  final double cpuUsage;
  final int memoryUsageMB;
  final double frameRate;
  final int totalFrames;
  final int droppedFrames;
  final Duration averageFrameTime;
  final Map<String, Duration> apiCallDurations;
  final Map<String, int> apiCallCounts;

  PerformanceMetrics({
    required this.cpuUsage,
    required this.memoryUsageMB,
    required this.frameRate,
    required this.totalFrames,
    required this.droppedFrames,
    required this.averageFrameTime,
    required this.apiCallDurations,
    required this.apiCallCounts,
  });

  Map<String, dynamic> toJson() => {
        'cpu_usage_percent': cpuUsage,
        'memory_usage_mb': memoryUsageMB,
        'frame_rate': frameRate,
        'total_frames': totalFrames,
        'dropped_frames': droppedFrames,
        'average_frame_time_ms': averageFrameTime.inMicroseconds / 1000,
        'api_call_durations':
            apiCallDurations.map((k, v) => MapEntry(k, v.inMilliseconds)),
        'api_call_counts': apiCallCounts,
      };
}

// Performance event types
enum PerformanceEventType {
  apiCall,
  imageLoad,
  cacheOperation,
  uiRender,
  navigation,
  startup,
  custom,
}

// Performance event
class PerformanceEvent {
  final String name;
  final PerformanceEventType type;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final Map<String, dynamic> metadata;

  PerformanceEvent({
    required this.name,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.metadata,
  }) : duration = endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'duration_ms': duration.inMilliseconds,
        'metadata': metadata,
      };
}

// Performance timer for measuring operations
class PerformanceTimer {
  final String name;
  final PerformanceEventType type;
  final DateTime startTime;
  final Map<String, dynamic> metadata;

  PerformanceTimer({
    required this.name,
    required this.type,
    this.metadata = const {},
  }) : startTime = DateTime.now();

  PerformanceEvent stop() {
    final endTime = DateTime.now();
    return PerformanceEvent(
      name: name,
      type: type,
      startTime: startTime,
      endTime: endTime,
      metadata: metadata,
    );
  }
}

// Frame timing tracker
class FrameTimingTracker {
  final List<Duration> _frameTimes = [];
  final int _maxSamples = 120; // Track last 2 seconds at 60fps
  DateTime? _lastFrameTime;
  int _totalFrames = 0;
  int _droppedFrames = 0;

  void recordFrame() {
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!);
      _frameTimes.add(frameTime);

      if (_frameTimes.length > _maxSamples) {
        _frameTimes.removeAt(0);
      }

      // Consider frame dropped if it takes more than 20ms (50fps)
      if (frameTime.inMilliseconds > 20) {
        _droppedFrames++;
      }
    }

    _lastFrameTime = now;
    _totalFrames++;
  }

  double get averageFrameRate {
    if (_frameTimes.isEmpty) return 0;

    final totalMicroseconds =
        _frameTimes.fold(0, (sum, duration) => sum + duration.inMicroseconds);
    final avgMicroseconds = totalMicroseconds / _frameTimes.length;
    return avgMicroseconds > 0 ? 1000000 / avgMicroseconds : 0;
  }

  Duration get averageFrameTime {
    if (_frameTimes.isEmpty) return Duration.zero;
    return _frameTimes.reduce((a, b) => a + b) ~/ _frameTimes.length;
  }

  int get totalFrames => _totalFrames;
  int get droppedFrames => _droppedFrames;
}

// Memory usage tracker
class MemoryTracker {
  static const MethodChannel _channel = MethodChannel('memory_info');

  Future<int> getCurrentMemoryUsage() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod('getMemoryUsage');
        return result as int;
      } else {
        // For desktop platforms, use a rough estimation
        return _estimateMemoryUsage();
      }
    } catch (e) {
      return _estimateMemoryUsage();
    }
  }

  int _estimateMemoryUsage() {
    // This is a rough estimation - in a real app you'd want more accurate tracking
    final rss = ProcessInfo.currentRss;
    return rss ~/ (1024 * 1024); // Convert to MB
  }
}

// Performance monitor
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance =>
      _instance ??= PerformanceMonitor._();

  PerformanceMonitor._();

  final Map<String, Duration> _apiCallDurations = {};
  final Map<String, int> _apiCallCounts = {};
  final List<PerformanceEvent> _events = [];
  final FrameTimingTracker _frameTracker = FrameTimingTracker();
  final MemoryTracker _memoryTracker = MemoryTracker();

  Timer? _metricsTimer;
  bool _isEnabled = false;
  final int _maxEvents = 1000;

  // Enable/disable monitoring
  void enable() {
    if (_isEnabled) return;

    _isEnabled = true;

    // Start frame timing
    SchedulerBinding.instance.addPostFrameCallback(_onFrameEnd);

    // Start periodic metrics collection
    _metricsTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _collectMetrics(),
    );

    Logger.instance.info('Performance monitoring enabled');
  }

  void disable() {
    _isEnabled = false;
    _metricsTimer?.cancel();
    _metricsTimer = null;
    Logger.instance.info('Performance monitoring disabled');
  }

  // Start timing an operation
  PerformanceTimer startTimer(String name, PerformanceEventType type,
      {Map<String, dynamic>? metadata}) {
    return PerformanceTimer(
      name: name,
      type: type,
      metadata: metadata ?? {},
    );
  }

  // Record a completed event
  void recordEvent(PerformanceEvent event) {
    if (!_isEnabled) return;

    _events.add(event);

    // Track API calls separately
    if (event.type == PerformanceEventType.apiCall) {
      _apiCallDurations[event.name] = event.duration;
      _apiCallCounts[event.name] = (_apiCallCounts[event.name] ?? 0) + 1;
    }

    // Limit event history
    if (_events.length > _maxEvents) {
      _events.removeAt(0);
    }

    // Log slow operations
    if (event.duration.inMilliseconds > 1000) {
      Logger.instance.warning(
        'Slow operation detected: ${event.name} took ${event.duration.inMilliseconds}ms',
        component: 'PerformanceMonitor',
        context: event.metadata,
      );
    }
  }

  // Convenience method for timing operations
  Future<T> timeOperation<T>(
    String name,
    PerformanceEventType type,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    final timer = startTimer(name, type, metadata: metadata);
    try {
      final result = await operation();
      recordEvent(timer.stop());
      return result;
    } catch (e) {
      final event = timer.stop();
      recordEvent(event);
      rethrow;
    }
  }

  // Get current performance metrics
  Future<PerformanceMetrics> getMetrics() async {
    final memoryUsage = await _memoryTracker.getCurrentMemoryUsage();

    return PerformanceMetrics(
      cpuUsage: _estimateCpuUsage(),
      memoryUsageMB: memoryUsage,
      frameRate: _frameTracker.averageFrameRate,
      totalFrames: _frameTracker.totalFrames,
      droppedFrames: _frameTracker.droppedFrames,
      averageFrameTime: _frameTracker.averageFrameTime,
      apiCallDurations: Map.from(_apiCallDurations),
      apiCallCounts: Map.from(_apiCallCounts),
    );
  }

  // Get recent performance events
  List<PerformanceEvent> getRecentEvents({int limit = 100}) {
    final events = _events.toList();
    events.sort((a, b) => b.startTime.compareTo(a.startTime));
    return events.take(limit).toList();
  }

  // Get performance summary
  Map<String, dynamic> getSummary() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));

    final recentEvents =
        _events.where((e) => e.startTime.isAfter(last24h)).toList();

    final apiEvents =
        recentEvents.where((e) => e.type == PerformanceEventType.apiCall);
    final imageEvents =
        recentEvents.where((e) => e.type == PerformanceEventType.imageLoad);
    final uiEvents =
        recentEvents.where((e) => e.type == PerformanceEventType.uiRender);

    return {
      'total_events_24h': recentEvents.length,
      'api_calls_24h': apiEvents.length,
      'image_loads_24h': imageEvents.length,
      'ui_renders_24h': uiEvents.length,
      'average_api_time_ms': apiEvents.isNotEmpty
          ? apiEvents
                  .map((e) => e.duration.inMilliseconds)
                  .reduce((a, b) => a + b) /
              apiEvents.length
          : 0,
      'slowest_operations': _getSlowestOperations(),
      'frame_stats': {
        'total_frames': _frameTracker.totalFrames,
        'dropped_frames': _frameTracker.droppedFrames,
        'drop_rate': _frameTracker.totalFrames > 0
            ? _frameTracker.droppedFrames / _frameTracker.totalFrames
            : 0,
      },
    };
  }

  // Frame callback
  void _onFrameEnd(Duration timeStamp) {
    if (!_isEnabled) return;

    _frameTracker.recordFrame();

    // Schedule next frame callback
    SchedulerBinding.instance.addPostFrameCallback(_onFrameEnd);
  }

  // Collect metrics periodically
  Future<void> _collectMetrics() async {
    if (!_isEnabled) return;

    try {
      final metrics = await getMetrics();

      Logger.instance.info(
        'Performance metrics collected',
        component: 'PerformanceMonitor',
        context: {
          'memory_mb': metrics.memoryUsageMB,
          'frame_rate': metrics.frameRate.toStringAsFixed(1),
          'dropped_frames': metrics.droppedFrames,
          'api_calls': metrics.apiCallCounts.values.fold(0, (a, b) => a + b),
        },
      );

      // Alert on performance issues
      if (metrics.frameRate < 30) {
        Logger.instance.warning(
          'Low frame rate detected: ${metrics.frameRate.toStringAsFixed(1)} fps',
          component: 'PerformanceMonitor',
        );
      }

      if (metrics.memoryUsageMB > 200) {
        Logger.instance.warning(
          'High memory usage: ${metrics.memoryUsageMB}MB',
          component: 'PerformanceMonitor',
        );
      }
    } catch (e) {
      Logger.instance.error('Failed to collect performance metrics', error: e);
    }
  }

  // Estimate CPU usage (simplified)
  double _estimateCpuUsage() {
    // This is a simplified estimation - in a real app you'd want more accurate tracking
    final dropRate = _frameTracker.totalFrames > 0
        ? _frameTracker.droppedFrames / _frameTracker.totalFrames
        : 0;

    return (dropRate * 100).clamp(0, 100).toDouble();
  }

  // Get slowest operations
  List<Map<String, dynamic>> _getSlowestOperations() {
    final events = _events.toList();
    events.sort((a, b) => b.duration.compareTo(a.duration));

    return events
        .take(10)
        .map((e) => {
              'name': e.name,
              'type': e.type.name,
              'duration_ms': e.duration.inMilliseconds,
              'timestamp': e.startTime.toIso8601String(),
            })
        .toList();
  }

  // Clear all collected data
  void clear() {
    _events.clear();
    _apiCallDurations.clear();
    _apiCallCounts.clear();
    Logger.instance.info('Performance data cleared');
  }

  void dispose() {
    disable();
    clear();
  }
}

// Extensions for easy performance monitoring
extension PerformanceExtensions<T> on Future<T> {
  Future<T> timed(String name, PerformanceEventType type,
      {Map<String, dynamic>? metadata}) {
    return PerformanceMonitor.instance
        .timeOperation(name, type, () => this, metadata: metadata);
  }
}

// Mixin for automatic performance monitoring
mixin PerformanceMonitoring {
  PerformanceMonitor get performanceMonitor => PerformanceMonitor.instance;

  Future<T> timeAsync<T>(String name, Future<T> Function() operation,
      {Map<String, dynamic>? metadata}) {
    return performanceMonitor.timeOperation(
        name, PerformanceEventType.custom, operation,
        metadata: metadata);
  }

  T timeSync<T>(String name, T Function() operation,
      {Map<String, dynamic>? metadata}) {
    final timer = performanceMonitor
        .startTimer(name, PerformanceEventType.custom, metadata: metadata);
    try {
      final result = operation();
      performanceMonitor.recordEvent(timer.stop());
      return result;
    } catch (e) {
      performanceMonitor.recordEvent(timer.stop());
      rethrow;
    }
  }
}
