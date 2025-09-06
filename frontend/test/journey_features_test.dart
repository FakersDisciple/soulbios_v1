import 'package:flutter_test/flutter_test.dart';
import 'package:encarta_soulbios/models/api_models.dart';
import 'package:encarta_soulbios/services/alice_service.dart';
import 'package:encarta_soulbios/core/theme/app_colors.dart';

void main() {
  group('Journey Features Model Tests', () {

    test('PatternNode model serialization works correctly', () {
      final node = PatternNode(
        id: 'test_id',
        label: 'Test Label',
        color: AppColors.warmGold,
        connectionIds: ['conn1', 'conn2'],
        pattern: 'test_pattern',
        discoveredAt: DateTime.now(),
        isRevealed: true,
      );

      final json = node.toJson();
      final reconstructed = PatternNode.fromJson(json);

      expect(reconstructed.id, equals(node.id));
      expect(reconstructed.label, equals(node.label));
      expect(reconstructed.connectionIds, equals(node.connectionIds));
      expect(reconstructed.pattern, equals(node.pattern));
      expect(reconstructed.isRevealed, equals(node.isRevealed));
    });

    test('MemoryEntry model serialization works correctly', () {
      final memory = MemoryEntry(
        id: 'test_memory',
        content: 'Test memory content',
        timestamp: DateTime.now(),
        metadata: {'test': 'data'},
        tags: ['test', 'memory'],
        sentimentScore: 0.5,
        emotionalState: 'positive',
      );

      final json = memory.toJson();
      final reconstructed = MemoryEntry.fromJson(json);

      expect(reconstructed.id, equals(memory.id));
      expect(reconstructed.content, equals(memory.content));
      expect(reconstructed.tags, equals(memory.tags));
      expect(reconstructed.sentimentScore, equals(memory.sentimentScore));
      expect(reconstructed.emotionalState, equals(memory.emotionalState));
    });

    test('DataDestination model serialization works correctly', () {
      final destination = DataDestination(
        iconPath: 'test_icon',
        description: 'Test description',
        type: 'test_type',
        color: AppColors.naturalGreen,
      );

      final json = destination.toJson();
      final reconstructed = DataDestination.fromJson(json);

      expect(reconstructed.iconPath, equals(destination.iconPath));
      expect(reconstructed.description, equals(destination.description));
      expect(reconstructed.type, equals(destination.type));
      expect(reconstructed.color.value, equals(destination.color.value));
    });
  });
}
  gro
up('Pattern Recall Accuracy Tests', () {
    test('Pattern recall accuracy with recent data', () async {
      // Simulate Alice service with pattern analysis
      final mockAliceService = MockAliceService();
      
      // Test recent pattern analysis
      await mockAliceService.analyzePatterns('user123', 'I feel anxious about work deadlines');
      final patterns = await mockAliceService.getPatternHistory('user123');
      
      expect(patterns.containsKey('anxiety'), isTrue);
      expect(patterns['anxiety']['relevance'], greaterThan(0.7));
      expect(patterns['anxiety']['context'], contains('work'));
    });

    test('Pattern recall accuracy with year-old data simulation', () async {
      final mockAliceService = MockAliceService();
      
      // Simulate year-old pattern data
      final yearAgoTimestamp = DateTime.now().subtract(const Duration(days: 365));
      await mockAliceService.storeHistoricalPattern(
        'user123',
        'responsibility_burden',
        {
          'strength': 0.8,
          'context': 'childhood_caretaking',
          'timestamp': yearAgoTimestamp.toIso8601String(),
        },
      );
      
      // Current analysis should recall historical patterns
      await mockAliceService.analyzePatterns('user123', 'I feel responsible for everyone');
      final patterns = await mockAliceService.getPatternHistory('user123');
      
      expect(patterns.containsKey('responsibility_burden'), isTrue);
      expect(patterns['responsibility_burden']['historical_connection'], isTrue);
      expect(patterns['responsibility_burden']['relevance'], greaterThan(0.7));
    });

    test('Semantic search accuracy for pattern matching', () async {
      final mockAliceService = MockAliceService();
      
      // Store various patterns with semantic variations
      final testPatterns = [
        {'text': 'I feel overwhelmed by work', 'pattern': 'work_stress'},
        {'text': 'Job pressure is getting to me', 'pattern': 'work_stress'},
        {'text': 'Career anxiety is high today', 'pattern': 'work_stress'},
        {'text': 'Family dinner was wonderful', 'pattern': 'family_connection'},
        {'text': 'Loved spending time with relatives', 'pattern': 'family_connection'},
      ];
      
      for (final pattern in testPatterns) {
        await mockAliceService.analyzePatterns('user123', pattern['text'] as String);
      }
      
      // Test semantic search
      final workStressResults = await mockAliceService.searchSimilarPatterns(
        'user123',
        'Feeling stressed about my job',
        threshold: 0.7,
      );
      
      expect(workStressResults.length, equals(3)); // Should find all work stress patterns
      
      final familyResults = await mockAliceService.searchSimilarPatterns(
        'user123',
        'Enjoyed family time',
        threshold: 0.7,
      );
      
      expect(familyResults.length, equals(2)); // Should find family connection patterns
    });

    test('Pattern relevance scoring algorithm', () async {
      final mockAliceService = MockAliceService();
      
      // Test patterns with different recency and frequency
      final patterns = [
        {
          'id': 'recent_frequent',
          'lastSeen': DateTime.now().subtract(const Duration(days: 1)),
          'frequency': 10,
          'strength': 0.8,
        },
        {
          'id': 'old_frequent',
          'lastSeen': DateTime.now().subtract(const Duration(days: 180)),
          'frequency': 15,
          'strength': 0.9,
        },
        {
          'id': 'recent_rare',
          'lastSeen': DateTime.now().subtract(const Duration(days: 2)),
          'frequency': 2,
          'strength': 0.6,
        },
      ];
      
      final scoredPatterns = mockAliceService.calculateRelevanceScores(patterns);
      
      // Recent frequent pattern should score highest
      expect(scoredPatterns['recent_frequent'], greaterThan(0.8));
      
      // Old frequent pattern should score lower due to recency
      expect(scoredPatterns['old_frequent'], lessThan(scoredPatterns['recent_frequent']));
      
      // Recent rare pattern should score moderately
      expect(scoredPatterns['recent_rare'], greaterThan(0.5));
      expect(scoredPatterns['recent_rare'], lessThan(scoredPatterns['recent_frequent']));
    });

    test('Contextual pattern matching for chamber interactions', () async {
      final mockAliceService = MockAliceService();
      
      // Store patterns with chamber context
      await mockAliceService.analyzePatterns('user123', 'Anxiety in emotion chamber');
      await mockAliceService.analyzePatterns('user123', 'Defensive patterns in fortress chamber');
      await mockAliceService.analyzePatterns('user123', 'Growth insights in wisdom chamber');
      
      // Test chamber-specific pattern retrieval
      final emotionPatterns = await mockAliceService.getChamberSpecificPatterns(
        'user123',
        'emotion',
      );
      
      expect(emotionPatterns.length, greaterThan(0));
      expect(emotionPatterns.first['context'], contains('emotion'));
      
      final fortressPatterns = await mockAliceService.getChamberSpecificPatterns(
        'user123',
        'fortress',
      );
      
      expect(fortressPatterns.length, greaterThan(0));
      expect(fortressPatterns.first['context'], contains('fortress'));
    });
  });

  group('Multi-Tenant Data Isolation Tests', () {
    test('User data isolation in pattern storage', () async {
      final mockAliceService = MockAliceService();
      
      // Store patterns for different users
      await mockAliceService.analyzePatterns('user1', 'I have anxiety about work');
      await mockAliceService.analyzePatterns('user2', 'I feel grateful for family');
      await mockAliceService.analyzePatterns('user3', 'I struggle with perfectionism');
      
      // Verify isolation
      final user1Patterns = await mockAliceService.getPatternHistory('user1');
      final user2Patterns = await mockAliceService.getPatternHistory('user2');
      final user3Patterns = await mockAliceService.getPatternHistory('user3');
      
      expect(user1Patterns.containsKey('anxiety'), isTrue);
      expect(user1Patterns.containsKey('gratitude'), isFalse);
      expect(user1Patterns.containsKey('perfectionism'), isFalse);
      
      expect(user2Patterns.containsKey('gratitude'), isTrue);
      expect(user2Patterns.containsKey('anxiety'), isFalse);
      expect(user2Patterns.containsKey('perfectionism'), isFalse);
      
      expect(user3Patterns.containsKey('perfectionism'), isTrue);
      expect(user3Patterns.containsKey('anxiety'), isFalse);
      expect(user3Patterns.containsKey('gratitude'), isFalse);
    });

    test('Memory isolation between users', () async {
      final mockAliceService = MockAliceService();
      
      // Store memories for different users
      await mockAliceService.storeMemory('user1', MemoryEntry(
        id: 'memory1',
        content: 'User 1 private memory',
        timestamp: DateTime.now(),
        metadata: {'private': true},
        tags: ['personal'],
        sentimentScore: 0.5,
        emotionalState: 'neutral',
      ));
      
      await mockAliceService.storeMemory('user2', MemoryEntry(
        id: 'memory2',
        content: 'User 2 private memory',
        timestamp: DateTime.now(),
        metadata: {'private': true},
        tags: ['personal'],
        sentimentScore: 0.7,
        emotionalState: 'positive',
      ));
      
      // Verify memories are isolated
      final user1Memories = await mockAliceService.getUserMemories('user1');
      final user2Memories = await mockAliceService.getUserMemories('user2');
      
      expect(user1Memories.length, equals(1));
      expect(user1Memories.first.content, contains('User 1'));
      
      expect(user2Memories.length, equals(1));
      expect(user2Memories.first.content, contains('User 2'));
      
      // Cross-user access should return empty
      final user3Memories = await mockAliceService.getUserMemories('user3');
      expect(user3Memories.isEmpty, isTrue);
    });

    test('Conversation history isolation', () async {
      final mockAliceService = MockAliceService();
      
      // Create conversations for different users
      await mockAliceService.storeConversation('user1', 'conv1', [
        {'role': 'user', 'content': 'User 1 message'},
        {'role': 'alice', 'content': 'Alice response to user 1'},
      ]);
      
      await mockAliceService.storeConversation('user2', 'conv2', [
        {'role': 'user', 'content': 'User 2 message'},
        {'role': 'alice', 'content': 'Alice response to user 2'},
      ]);
      
      // Verify conversation isolation
      final user1Conversations = await mockAliceService.getUserConversations('user1');
      final user2Conversations = await mockAliceService.getUserConversations('user2');
      
      expect(user1Conversations.length, equals(1));
      expect(user1Conversations.first['messages'][0]['content'], contains('User 1'));
      
      expect(user2Conversations.length, equals(1));
      expect(user2Conversations.first['messages'][0]['content'], contains('User 2'));
    });
  });
}

/// Mock Alice Service for testing
class MockAliceService {
  final Map<String, Map<String, dynamic>> _userPatterns = {};
  final Map<String, List<MemoryEntry>> _userMemories = {};
  final Map<String, List<Map<String, dynamic>>> _userConversations = {};
  final Map<String, Map<String, dynamic>> _historicalPatterns = {};

  Future<void> analyzePatterns(String userId, String content) async {
    _userPatterns[userId] ??= {};
    
    // Simple pattern detection for testing
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains(RegExp(r'\b(anxious|anxiety|worry|stress)\b'))) {
      _userPatterns[userId]!['anxiety'] = {
        'relevance': 0.8,
        'context': _extractContext(content),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    
    if (lowerContent.contains(RegExp(r'\b(grateful|gratitude|thankful)\b'))) {
      _userPatterns[userId]!['gratitude'] = {
        'relevance': 0.9,
        'context': _extractContext(content),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    
    if (lowerContent.contains(RegExp(r'\b(perfectionism|perfect|flawless)\b'))) {
      _userPatterns[userId]!['perfectionism'] = {
        'relevance': 0.7,
        'context': _extractContext(content),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    
    if (lowerContent.contains(RegExp(r'\b(responsible|responsibility|burden)\b'))) {
      _userPatterns[userId]!['responsibility_burden'] = {
        'relevance': 0.8,
        'context': _extractContext(content),
        'timestamp': DateTime.now().toIso8601String(),
        'historical_connection': _historicalPatterns.containsKey('${userId}_responsibility_burden'),
      };
    }
  }

  Future<Map<String, dynamic>> getPatternHistory(String userId) async {
    return _userPatterns[userId] ?? {};
  }

  Future<void> storeHistoricalPattern(String userId, String patternId, Map<String, dynamic> data) async {
    _historicalPatterns['${userId}_$patternId'] = data;
  }

  Future<List<Map<String, dynamic>>> searchSimilarPatterns(String userId, String query, {double threshold = 0.7}) async {
    final userPatterns = _userPatterns[userId] ?? {};
    final results = <Map<String, dynamic>>[];
    
    final lowerQuery = query.toLowerCase();
    
    for (final entry in userPatterns.entries) {
      final patternName = entry.key;
      final patternData = entry.value;
      
      // Simple semantic matching for testing
      double similarity = 0.0;
      
      if (lowerQuery.contains('stress') || lowerQuery.contains('job')) {
        if (patternName == 'work_stress') similarity = 0.9;
      }
      
      if (lowerQuery.contains('family') || lowerQuery.contains('relatives')) {
        if (patternName == 'family_connection') similarity = 0.9;
      }
      
      if (similarity >= threshold) {
        results.add({
          'pattern': patternName,
          'similarity': similarity,
          'data': patternData,
        });
      }
    }
    
    return results;
  }

  Map<String, double> calculateRelevanceScores(List<Map<String, dynamic>> patterns) {
    final scores = <String, double>{};
    
    for (final pattern in patterns) {
      final id = pattern['id'] as String;
      final lastSeen = pattern['lastSeen'] as DateTime;
      final frequency = pattern['frequency'] as int;
      final strength = pattern['strength'] as double;
      
      // Calculate recency score (0-1, higher for more recent)
      final daysSinceLastSeen = DateTime.now().difference(lastSeen).inDays;
      final recencyScore = 1.0 / (1.0 + daysSinceLastSeen / 30.0); // Decay over 30 days
      
      // Calculate frequency score (0-1, normalized)
      final frequencyScore = (frequency / 20.0).clamp(0.0, 1.0); // Max frequency of 20
      
      // Combined score
      scores[id] = (recencyScore * 0.4 + frequencyScore * 0.3 + strength * 0.3);
    }
    
    return scores;
  }

  Future<List<Map<String, dynamic>>> getChamberSpecificPatterns(String userId, String chamberType) async {
    final userPatterns = _userPatterns[userId] ?? {};
    final results = <Map<String, dynamic>>[];
    
    for (final entry in userPatterns.entries) {
      final patternData = entry.value;
      final context = patternData['context'] as String? ?? '';
      
      if (context.toLowerCase().contains(chamberType.toLowerCase())) {
        results.add({
          'pattern': entry.key,
          'context': context,
          'data': patternData,
        });
      }
    }
    
    return results;
  }

  Future<void> storeMemory(String userId, MemoryEntry memory) async {
    _userMemories[userId] ??= [];
    _userMemories[userId]!.add(memory);
  }

  Future<List<MemoryEntry>> getUserMemories(String userId) async {
    return _userMemories[userId] ?? [];
  }

  Future<void> storeConversation(String userId, String conversationId, List<Map<String, dynamic>> messages) async {
    _userConversations[userId] ??= [];
    _userConversations[userId]!.add({
      'id': conversationId,
      'messages': messages,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    return _userConversations[userId] ?? [];
  }

  String _extractContext(String content) {
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains('work') || lowerContent.contains('job')) {
      return 'work context';
    }
    if (lowerContent.contains('family') || lowerContent.contains('relatives')) {
      return 'family context';
    }
    if (lowerContent.contains('emotion chamber')) {
      return 'emotion chamber context';
    }
    if (lowerContent.contains('fortress chamber')) {
      return 'fortress chamber context';
    }
    
    return 'general context';
  }
}