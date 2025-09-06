import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

/// Load testing simulation for SoulBios backend
/// Tests 100+ concurrent users interacting with key endpoints
class LoadTestingSimulation {
  static const String baseUrl = 'http://localhost:8000';
  static const int maxConcurrentUsers = 150;
  static const Duration testDuration = Duration(minutes: 5);
  
  final Random _random = Random();
  final List<String> _testUserIds = [];
  final Map<String, int> _endpointCalls = {};
  final Map<String, List<int>> _responseTimes = {};
  final List<String> _errors = [];

  LoadTestingSimulation() {
    // Generate test user IDs
    for (int i = 0; i < maxConcurrentUsers; i++) {
      _testUserIds.add('test_user_$i');
    }
  }

  /// Run the complete load testing simulation
  Future<LoadTestResults> runLoadTest() async {
    print('🚀 Starting load test with $maxConcurrentUsers concurrent users');
    print('📊 Test duration: ${testDuration.inMinutes} minutes');
    
    final startTime = DateTime.now();
    final futures = <Future<void>>[];

    // Start concurrent user simulations
    for (int i = 0; i < maxConcurrentUsers; i++) {
      futures.add(_simulateUser(_testUserIds[i], startTime));
    }

    // Wait for all simulations to complete
    await Future.wait(futures);

    final endTime = DateTime.now();
    final actualDuration = endTime.difference(startTime);

    return LoadTestResults(
      totalUsers: maxConcurrentUsers,
      duration: actualDuration,
      endpointCalls: Map.from(_endpointCalls),
      responseTimes: Map.from(_responseTimes),
      errors: List.from(_errors),
    );
  }

  /// Simulate a single user's behavior
  Future<void> _simulateUser(String userId, DateTime startTime) async {
    final client = http.Client();
    
    try {
      while (DateTime.now().difference(startTime) < testDuration) {
        // Random delay between actions (1-10 seconds)
        await Future.delayed(Duration(seconds: _random.nextInt(9) + 1));
        
        // Choose random action based on realistic usage patterns
        final action = _getRandomAction();
        await _performAction(client, userId, action);
      }
    } catch (e) {
      _errors.add('User $userId error: $e');
    } finally {
      client.close();
    }
  }

  /// Get a random action based on realistic usage patterns
  UserAction _getRandomAction() {
    final actions = [
      UserAction.chat,      // 40% - Most common
      UserAction.chat,
      UserAction.chat,
      UserAction.chat,
      UserAction.analyze,   // 25% - Pattern analysis
      UserAction.analyze,
      UserAction.analyze,
      UserAction.status,    // 20% - Status checks
      UserAction.status,
      UserAction.image,     // 10% - Image generation
      UserAction.upload,    // 5% - File uploads
    ];
    
    return actions[_random.nextInt(actions.length)];
  }

  /// Perform a specific user action
  Future<void> _performAction(http.Client client, String userId, UserAction action) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      http.Response? response;
      String endpoint = '';

      switch (action) {
        case UserAction.chat:
          endpoint = '/chat/$userId';
          response = await _performChatRequest(client, userId);
          break;
          
        case UserAction.analyze:
          endpoint = '/analyze/$userId';
          response = await _performAnalyzeRequest(client, userId);
          break;
          
        case UserAction.status:
          endpoint = '/status/$userId';
          response = await _performStatusRequest(client, userId);
          break;
          
        case UserAction.image:
          endpoint = '/generate/image';
          response = await _performImageRequest(client, userId);
          break;
          
        case UserAction.upload:
          endpoint = '/upload/lifebook';
          response = await _performUploadRequest(client, userId);
          break;
      }

      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;

      // Record metrics
      _endpointCalls[endpoint] = (_endpointCalls[endpoint] ?? 0) + 1;
      _responseTimes[endpoint] ??= <int>[];
      _responseTimes[endpoint]!.add(responseTime);

      // Check for errors
      if (response != null && response.statusCode >= 400) {
        _errors.add('$endpoint returned ${response.statusCode}: ${response.body}');
      }

      // Verify response time is acceptable (< 500ms for most endpoints)
      if (responseTime > 500 && action != UserAction.image) {
        _errors.add('$endpoint slow response: ${responseTime}ms');
      }

      // Image generation can take longer (< 10 seconds)
      if (responseTime > 10000 && action == UserAction.image) {
        _errors.add('Image generation timeout: ${responseTime}ms');
      }

    } catch (e) {
      stopwatch.stop();
      _errors.add('Action $action failed for $userId: $e');
    }
  }

  /// Perform chat request
  Future<http.Response> _performChatRequest(http.Client client, String userId) async {
    final messages = [
      'I feel anxious about work today',
      'How can I manage stress better?',
      'I had a breakthrough moment',
      'Tell me about my patterns',
      'I need emotional support',
      'What insights do you have for me?',
      'I\'m feeling overwhelmed',
      'Help me understand my behavior',
    ];

    final message = messages[_random.nextInt(messages.length)];
    
    return await client.post(
      Uri.parse('$baseUrl/chat/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'conversation_id': 'load_test_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      }),
    );
  }

  /// Perform pattern analysis request
  Future<http.Response> _performAnalyzeRequest(http.Client client, String userId) async {
    return await client.post(
      Uri.parse('$baseUrl/analyze/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'content': 'Analyze my recent patterns and provide insights',
        'analysis_type': 'comprehensive',
      }),
    );
  }

  /// Perform status check request
  Future<http.Response> _performStatusRequest(http.Client client, String userId) async {
    return await client.get(
      Uri.parse('$baseUrl/status/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Perform image generation request
  Future<http.Response> _performImageRequest(http.Client client, String userId) async {
    final prompts = [
      'A serene meditation space with soft lighting',
      'Abstract representation of emotional patterns',
      'Peaceful nature scene for reflection',
      'Consciousness journey visualization',
      'Calming geometric patterns',
    ];

    final prompt = prompts[_random.nextInt(prompts.length)];
    
    return await client.post(
      Uri.parse('$baseUrl/generate/image'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'prompt': prompt,
        'style': 'consciousness_art',
      }),
    );
  }

  /// Perform file upload request (simulated)
  Future<http.Response> _performUploadRequest(http.Client client, String userId) async {
    // Simulate PDF upload with multipart request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/lifebook'),
    );
    
    request.fields['user_id'] = userId;
    request.files.add(http.MultipartFile.fromString(
      'file',
      'Simulated PDF content for load testing',
      filename: 'test_lifebook_$userId.pdf',
    ));

    final streamedResponse = await client.send(request);
    return await http.Response.fromStream(streamedResponse);
  }
}

/// User action types for load testing
enum UserAction {
  chat,
  analyze,
  status,
  image,
  upload,
}

/// Load test results container
class LoadTestResults {
  final int totalUsers;
  final Duration duration;
  final Map<String, int> endpointCalls;
  final Map<String, List<int>> responseTimes;
  final List<String> errors;

  LoadTestResults({
    required this.totalUsers,
    required this.duration,
    required this.endpointCalls,
    required this.responseTimes,
    required this.errors,
  });

  /// Generate a comprehensive report
  String generateReport() {
    final buffer = StringBuffer();
    
    buffer.writeln('🔥 SOULBIOS LOAD TEST RESULTS 🔥');
    buffer.writeln('=' * 50);
    buffer.writeln('Total Users: $totalUsers');
    buffer.writeln('Test Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
    buffer.writeln('Total Errors: ${errors.length}');
    buffer.writeln();

    // Endpoint statistics
    buffer.writeln('📊 ENDPOINT STATISTICS');
    buffer.writeln('-' * 30);
    
    for (final endpoint in endpointCalls.keys) {
      final calls = endpointCalls[endpoint]!;
      final times = responseTimes[endpoint] ?? [];
      
      if (times.isNotEmpty) {
        final avgTime = times.reduce((a, b) => a + b) / times.length;
        final maxTime = times.reduce((a, b) => a > b ? a : b);
        final minTime = times.reduce((a, b) => a < b ? a : b);
        
        buffer.writeln('$endpoint:');
        buffer.writeln('  Calls: $calls');
        buffer.writeln('  Avg Response: ${avgTime.toStringAsFixed(1)}ms');
        buffer.writeln('  Min Response: ${minTime}ms');
        buffer.writeln('  Max Response: ${maxTime}ms');
        buffer.writeln();
      }
    }

    // Performance analysis
    buffer.writeln('⚡ PERFORMANCE ANALYSIS');
    buffer.writeln('-' * 30);
    
    final totalCalls = endpointCalls.values.fold(0, (sum, calls) => sum + calls);
    final callsPerSecond = totalCalls / duration.inSeconds;
    
    buffer.writeln('Total API Calls: $totalCalls');
    buffer.writeln('Calls per Second: ${callsPerSecond.toStringAsFixed(2)}');
    buffer.writeln('Success Rate: ${((totalCalls - errors.length) / totalCalls * 100).toStringAsFixed(1)}%');
    buffer.writeln();

    // Error analysis
    if (errors.isNotEmpty) {
      buffer.writeln('❌ ERROR ANALYSIS');
      buffer.writeln('-' * 30);
      
      final errorTypes = <String, int>{};
      for (final error in errors) {
        final type = error.split(':')[0];
        errorTypes[type] = (errorTypes[type] ?? 0) + 1;
      }
      
      for (final entry in errorTypes.entries) {
        buffer.writeln('${entry.key}: ${entry.value} occurrences');
      }
      buffer.writeln();
      
      // Show first 10 errors as examples
      buffer.writeln('Sample Errors:');
      for (int i = 0; i < errors.length && i < 10; i++) {
        buffer.writeln('  ${i + 1}. ${errors[i]}');
      }
      buffer.writeln();
    }

    // Recommendations
    buffer.writeln('💡 RECOMMENDATIONS');
    buffer.writeln('-' * 30);
    
    final chatTimes = responseTimes['/chat/\$userId'] ?? [];
    if (chatTimes.isNotEmpty) {
      final avgChatTime = chatTimes.reduce((a, b) => a + b) / chatTimes.length;
      if (avgChatTime > 500) {
        buffer.writeln('⚠️  Chat response time is high (${avgChatTime.toStringAsFixed(1)}ms)');
        buffer.writeln('   Consider optimizing Gemini API calls or adding caching');
      }
    }
    
    if (errors.length > totalCalls * 0.05) {
      buffer.writeln('⚠️  Error rate is high (${(errors.length / totalCalls * 100).toStringAsFixed(1)}%)');
      buffer.writeln('   Review error logs and improve error handling');
    }
    
    if (callsPerSecond < 10) {
      buffer.writeln('⚠️  Throughput is low (${callsPerSecond.toStringAsFixed(2)} calls/sec)');
      buffer.writeln('   Consider scaling backend infrastructure');
    }

    buffer.writeln();
    buffer.writeln('✅ Load test completed successfully!');
    
    return buffer.toString();
  }
}

void main() {
  group('Load Testing Simulation', () {
    test('Run 100+ concurrent user simulation', () async {
      final simulation = LoadTestingSimulation();
      
      print('Starting load test simulation...');
      final results = await simulation.runLoadTest();
      
      final report = results.generateReport();
      print(report);
      
      // Write report to file
      final file = File('load_test_report.txt');
      await file.writeAsString(report);
      
      // Assertions for test success
      expect(results.totalUsers, equals(LoadTestingSimulation.maxConcurrentUsers));
      expect(results.duration.inMinutes, greaterThanOrEqualTo(4)); // Should run for ~5 minutes
      expect(results.endpointCalls.isNotEmpty, isTrue);
      
      // Performance assertions
      final totalCalls = results.endpointCalls.values.fold(0, (sum, calls) => sum + calls);
      final errorRate = results.errors.length / totalCalls;
      
      expect(errorRate, lessThan(0.1)); // Less than 10% error rate
      expect(totalCalls, greaterThan(100)); // Should have made many calls
      
      // Response time assertions
      for (final endpoint in results.responseTimes.keys) {
        final times = results.responseTimes[endpoint]!;
        if (times.isNotEmpty && !endpoint.contains('image')) {
          final avgTime = times.reduce((a, b) => a + b) / times.length;
          expect(avgTime, lessThan(1000)); // Average response under 1 second
        }
      }
      
      print('✅ Load test simulation completed successfully');
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}