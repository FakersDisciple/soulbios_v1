import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Performance optimization utilities for SoulBios
/// Provides device-specific optimizations and performance monitoring
class PerformanceOptimizer {
  static PerformanceOptimizer? _instance;
  static PerformanceOptimizer get instance => _instance ??= PerformanceOptimizer._();
  
  PerformanceOptimizer._();

  bool? _isLowEndDevice;
  bool? _isReducedMotionEnabled;
  double? _devicePixelRatio;
  
  /// Initialize performance optimizer with device capabilities
  Future<void> initialize() async {
    _devicePixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    _isReducedMotionEnabled = await _checkReducedMotionPreference();
    _isLowEndDevice = _determineDeviceCapability();
    
    if (kDebugMode) {
      print('🔧 Performance Optimizer initialized:');
      print('   Device Pixel Ratio: $_devicePixelRatio');
      print('   Low-end Device: $_isLowEndDevice');
      print('   Reduced Motion: $_isReducedMotionEnabled');
    }
  }

  /// Check if device is considered low-end for performance optimization
  bool get isLowEndDevice => _isLowEndDevice ?? false;

  /// Check if user has reduced motion preferences enabled
  bool get isReducedMotionEnabled => _isReducedMotionEnabled ?? false;

  /// Get device pixel ratio
  double get devicePixelRatio => _devicePixelRatio ?? 1.0;

  /// Get optimized particle count based on device capability
  int getOptimizedParticleCount(int defaultCount) {
    if (isLowEndDevice) {
      return (defaultCount * 0.3).round().clamp(5, 20); // Reduce to 30%, min 5, max 20
    } else if (devicePixelRatio < 2.0) {
      return (defaultCount * 0.6).round().clamp(10, 30); // Reduce to 60%
    }
    return defaultCount;
  }

  /// Get optimized animation duration based on performance settings
  Duration getOptimizedAnimationDuration(Duration defaultDuration) {
    if (isReducedMotionEnabled) {
      return Duration(milliseconds: (defaultDuration.inMilliseconds * 0.3).round());
    } else if (isLowEndDevice) {
      return Duration(milliseconds: (defaultDuration.inMilliseconds * 0.7).round());
    }
    return defaultDuration;
  }

  /// Get optimized frame rate for animations
  int getOptimizedFrameRate() {
    if (isLowEndDevice) {
      return 30; // 30 FPS for low-end devices
    }
    return 60; // 60 FPS for capable devices
  }

  /// Check if complex visual effects should be enabled
  bool shouldEnableComplexEffects() {
    return !isLowEndDevice && !isReducedMotionEnabled;
  }

  /// Get optimized blur radius for glassmorphic effects
  double getOptimizedBlurRadius(double defaultRadius) {
    if (isLowEndDevice) {
      return defaultRadius * 0.5; // Reduce blur for performance
    }
    return defaultRadius;
  }

  /// Get optimized shadow configuration
  List<BoxShadow> getOptimizedShadows(List<BoxShadow> defaultShadows) {
    if (isLowEndDevice) {
      // Reduce shadow complexity
      return defaultShadows.take(1).map((shadow) => BoxShadow(
        color: shadow.color,
        offset: shadow.offset,
        blurRadius: shadow.blurRadius * 0.5,
        spreadRadius: shadow.spreadRadius * 0.5,
      )).toList();
    }
    return defaultShadows;
  }

  /// Monitor frame rendering performance
  void startPerformanceMonitoring() {
    if (kDebugMode) {
      WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);
    }
  }

  /// Stop performance monitoring
  void stopPerformanceMonitoring() {
    if (kDebugMode) {
      WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
    }
  }

  /// Determine device capability based on available metrics
  bool _determineDeviceCapability() {
    // Simple heuristic based on device pixel ratio and platform
    if (devicePixelRatio < 2.0) {
      return true; // Likely low-end device
    }
    
    // Additional checks could include:
    // - Available memory
    // - CPU cores
    // - GPU capabilities
    // For now, we use a conservative approach
    
    return false;
  }

  /// Check for reduced motion accessibility preference
  Future<bool> _checkReducedMotionPreference() async {
    try {
      // This would typically check system accessibility settings
      // For now, we return false as default
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Handle frame timing callbacks for performance monitoring
  void _onFrameTimings(List<dynamic> timings) {
    if (timings.isEmpty) return;
    
    // Simple performance monitoring without FrameTiming dependency
    if (kDebugMode) {
      print('📊 Performance monitoring active');
    }
  }
}

/// Widget that automatically optimizes its children based on device performance
class PerformanceOptimizedWidget extends StatelessWidget {
  final Widget child;
  final Widget? lowEndChild;
  final bool forceOptimization;

  const PerformanceOptimizedWidget({
    super.key,
    required this.child,
    this.lowEndChild,
    this.forceOptimization = false,
  });

  @override
  Widget build(BuildContext context) {
    final optimizer = PerformanceOptimizer.instance;
    
    if (forceOptimization || optimizer.isLowEndDevice) {
      return lowEndChild ?? child;
    }
    
    return child;
  }
}

/// Optimized particle system for data pathway visualizer
class OptimizedParticleSystem {
  final int maxParticles;
  final Duration animationDuration;
  final bool enableComplexEffects;
  
  OptimizedParticleSystem({
    int defaultMaxParticles = 50,
    Duration defaultDuration = const Duration(seconds: 2),
  }) : maxParticles = PerformanceOptimizer.instance.getOptimizedParticleCount(defaultMaxParticles),
       animationDuration = PerformanceOptimizer.instance.getOptimizedAnimationDuration(defaultDuration),
       enableComplexEffects = PerformanceOptimizer.instance.shouldEnableComplexEffects();

  /// Create optimized particle configuration
  Map<String, dynamic> getParticleConfig() {
    return {
      'maxParticles': maxParticles,
      'animationDuration': animationDuration.inMilliseconds,
      'enableTrails': enableComplexEffects,
      'enableGlow': enableComplexEffects,
      'frameRate': PerformanceOptimizer.instance.getOptimizedFrameRate(),
    };
  }
}

/// Performance-aware animation controller
class OptimizedAnimationController extends AnimationController {
  OptimizedAnimationController({
    required Duration duration,
    required TickerProvider vsync,
    String? debugLabel,
  }) : super(
    duration: PerformanceOptimizer.instance.getOptimizedAnimationDuration(duration),
    vsync: vsync,
    debugLabel: debugLabel,
  );

  /// Create animation with performance optimization
  static OptimizedAnimationController create({
    required Duration duration,
    required TickerProvider vsync,
    String? debugLabel,
  }) {
    return OptimizedAnimationController(
      duration: duration,
      vsync: vsync,
      debugLabel: debugLabel,
    );
  }
}

/// Memory-efficient image cache manager
class OptimizedImageCache {
  static const int _maxCacheSize = 50; // Maximum cached images
  static const int _maxMemoryUsage = 100 * 1024 * 1024; // 100MB max
  
  static final Map<String, ImageInfo> _cache = {};
  static int _currentMemoryUsage = 0;

  /// Cache image with memory management
  static void cacheImage(String key, ImageInfo imageInfo) {
    // Estimate memory usage (rough calculation)
    final estimatedSize = imageInfo.image.width * imageInfo.image.height * 4; // 4 bytes per pixel
    
    // Clean cache if needed
    if (_cache.length >= _maxCacheSize || _currentMemoryUsage + estimatedSize > _maxMemoryUsage) {
      _cleanCache();
    }
    
    _cache[key] = imageInfo;
    _currentMemoryUsage += estimatedSize;
  }

  /// Get cached image
  static ImageInfo? getCachedImage(String key) {
    return _cache[key];
  }

  /// Clean cache using LRU strategy
  static void _cleanCache() {
    if (_cache.isEmpty) return;
    
    // Remove oldest entries (simplified LRU)
    final keysToRemove = _cache.keys.take(_cache.length ~/ 2).toList();
    
    for (final key in keysToRemove) {
      final imageInfo = _cache.remove(key);
      if (imageInfo != null) {
        final estimatedSize = imageInfo.image.width * imageInfo.image.height * 4;
        _currentMemoryUsage -= estimatedSize;
      }
    }
    
    _currentMemoryUsage = _currentMemoryUsage.clamp(0, _maxMemoryUsage);
  }

  /// Clear all cached images
  static void clearCache() {
    _cache.clear();
    _currentMemoryUsage = 0;
  }
}

/// Performance metrics collector
class PerformanceMetrics {
  static final List<double> _frameTimes = [];
  static final List<int> _memoryUsage = [];
  static DateTime? _startTime;

  /// Start collecting performance metrics
  static void startCollection() {
    _startTime = DateTime.now();
    _frameTimes.clear();
    _memoryUsage.clear();
    
    PerformanceOptimizer.instance.startPerformanceMonitoring();
  }

  /// Stop collecting and generate report
  static Map<String, dynamic> generateReport() {
    PerformanceOptimizer.instance.stopPerformanceMonitoring();
    
    final duration = _startTime != null 
        ? DateTime.now().difference(_startTime!).inSeconds 
        : 0;
    
    final avgFrameTime = _frameTimes.isNotEmpty 
        ? _frameTimes.reduce((a, b) => a + b) / _frameTimes.length 
        : 0.0;
    
    final maxFrameTime = _frameTimes.isNotEmpty 
        ? _frameTimes.reduce((a, b) => a > b ? a : b) 
        : 0.0;
    
    final avgMemoryUsage = _memoryUsage.isNotEmpty 
        ? _memoryUsage.reduce((a, b) => a + b) / _memoryUsage.length 
        : 0;
    
    return {
      'duration_seconds': duration,
      'average_frame_time_ms': avgFrameTime,
      'max_frame_time_ms': maxFrameTime,
      'frame_drops': _frameTimes.where((time) => time > 16.67).length,
      'average_memory_usage_mb': avgMemoryUsage / (1024 * 1024),
      'is_low_end_device': PerformanceOptimizer.instance.isLowEndDevice,
      'device_pixel_ratio': PerformanceOptimizer.instance.devicePixelRatio,
    };
  }

  /// Record frame time
  static void recordFrameTime(double timeMs) {
    _frameTimes.add(timeMs);
    
    // Keep only recent measurements
    if (_frameTimes.length > 1000) {
      _frameTimes.removeRange(0, 500);
    }
  }

  /// Record memory usage
  static void recordMemoryUsage(int bytes) {
    _memoryUsage.add(bytes);
    
    // Keep only recent measurements
    if (_memoryUsage.length > 100) {
      _memoryUsage.removeRange(0, 50);
    }
  }
}