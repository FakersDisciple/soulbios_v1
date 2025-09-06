import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ConfigDebug {
  static void printConfig() {
    if (kDebugMode) {
      print('=== SoulBios API Configuration ===');
      print('Debug Mode: ${kDebugMode ? "YES" : "NO"}');
      print('Base URL: ${ApiService.baseUrl}');
      print('API Key: ${ApiService.apiKey.substring(0, 8)}...');
      print('==================================');
    }
  }

  static Map<String, dynamic> getConfigInfo() {
    return {
      'debug_mode': kDebugMode,
      'base_url': ApiService.baseUrl,
      'api_key_preview': '${ApiService.apiKey.substring(0, 8)}...',
      'is_production': !kDebugMode,
      'expected_production_url': 'https://soulbios-v1-747hyhhxdq-uc.a.run.app',
      'is_using_production_url': ApiService.baseUrl == 'https://soulbios-v1-747hyhhxdq-uc.a.run.app',
    };
  }
}