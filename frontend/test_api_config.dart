import 'lib/services/api_service.dart';
import 'lib/utils/config_debug.dart';

void main() async {
  print('Testing SoulBios API Configuration...\n');
  
  // Print current configuration
  ConfigDebug.printConfig();
  
  // Test health check
  try {
    print('\nTesting health check...');
    final health = await ApiService.healthCheck();
    print('✅ Health check successful!');
    print('Service: ${health['service']}');
    print('Status: ${health['status']}');
    print('Version: ${health['version']}');
  } catch (e) {
    print('❌ Health check failed: $e');
  }
  
  // Test basic connectivity
  try {
    print('\nTesting basic connectivity...');
    final isOnline = await ApiService.isOnline();
    print('Online status: ${isOnline ? "✅ ONLINE" : "❌ OFFLINE"}');
  } catch (e) {
    print('❌ Connectivity test failed: $e');
  }
}