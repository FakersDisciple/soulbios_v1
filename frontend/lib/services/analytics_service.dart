import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver _observer = 
      FirebaseAnalyticsObserver(analytics: _analytics);

  static FirebaseAnalyticsObserver get observer => _observer;

  // Journey-specific events
  static Future<void> trackMemoryCapture({
    required String method, // 'text' or 'voice'
    required int contentLength,
    required List<String> tags,
    String? emotionalState,
  }) async {
    if (kDebugMode) return; // Skip in debug mode
    
    await _analytics.logEvent(
      name: 'memory_captured',
      parameters: {
        'method': method,
        'content_length': contentLength,
        'tag_count': tags.length,
        'emotional_state': emotionalState ?? 'unknown',
        'tags': tags.join(','),
      },
    );
  }

  static Future<void> trackPatternDiscovery({
    required String nodeId,
    required String patternType,
    required bool isRevealed,
  }) async {
    if (kDebugMode) return;
    
    await _analytics.logEvent(
      name: 'pattern_discovered',
      parameters: {
        'node_id': nodeId,
        'pattern_type': patternType,
        'is_revealed': isRevealed,
      },
    );
  }

  static Future<void> trackAliceInteraction({
    required String messageLength,
    required String alicePersona,
    required String consciousnessLevel,
  }) async {
    if (kDebugMode) return;
    
    await _analytics.logEvent(
      name: 'alice_interaction',
      parameters: {
        'message_length': messageLength,
        'alice_persona': alicePersona,
        'consciousness_level': consciousnessLevel,
      },
    );
  }

  static Future<void> trackTimelineUsage({
    required String sortOption,
    String? filterTag,
    required int memoryCount,
  }) async {
    if (kDebugMode) return;
    
    await _analytics.logEvent(
      name: 'timeline_used',
      parameters: {
        'sort_option': sortOption,
        'filter_tag': filterTag ?? 'none',
        'memory_count': memoryCount,
      },
    );
  }

  static Future<void> trackVoiceInputUsage({
    required bool successful,
    required double duration,
    String? errorType,
  }) async {
    if (kDebugMode) return;
    
    await _analytics.logEvent(
      name: 'voice_input_used',
      parameters: {
        'successful': successful,
        'duration_seconds': duration,
        'error_type': errorType ?? 'none',
      },
    );
  }

  static Future<void> trackProFeatureRequest({
    required String featureName,
    required String context,
  }) async {
    if (kDebugMode) return;
    
    await _analytics.logEvent(
      name: 'pro_feature_requested',
      parameters: {
        'feature_name': featureName,
        'context': context,
      },
    );
  }

  // User engagement metrics
  static Future<void> trackSessionStart() async {
    if (kDebugMode) return;
    
    await _analytics.logEvent(name: 'session_start');
  }

  static Future<void> trackJourneyPageView() async {
    if (kDebugMode) return;
    
    await _analytics.logEvent(
      name: 'page_view',
      parameters: {'page_name': 'journey'},
    );
  }

  // Performance metrics
  static Future<void> trackPerformanceMetric({
    required String metricName,
    required double value,
    String? context,
  }) async {
    if (kDebugMode) return;
    
    await _analytics.logEvent(
      name: 'performance_metric',
      parameters: {
        'metric_name': metricName,
        'value': value,
        'context': context ?? 'unknown',
      },
    );
  }
}