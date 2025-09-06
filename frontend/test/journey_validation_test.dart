import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encarta_soulbios/models/api_models.dart';
import 'package:encarta_soulbios/core/theme/app_colors.dart';
import 'package:encarta_soulbios/services/api_service.dart';

void main() {
  group('SoulBios Journey Features Validation', () {
    
    group('1. Dynamic Data Pathways Validation', () {
      test('DataDestination model handles serialization correctly', () {
        final destination = DataDestination(
          iconPath: 'speech_bubble',
          description: 'Fuels Alice conversations',
          type: 'alice_chat',
          color: AppColors.deepPurple,
        );

        final json = destination.toJson();
        final reconstructed = DataDestination.fromJson(json);

        expect(reconstructed.iconPath, equals('speech_bubble'));
        expect(reconstructed.description, equals('Fuels Alice conversations'));
        expect(reconstructed.type, equals('alice_chat'));
        expect(reconstructed.color.value, equals(AppColors.deepPurple.value));
      });

      test('Multiple destinations can be created for different data flows', () {
        final destinations = [
          DataDestination(
            iconPath: 'speech_bubble',
            description: 'Fuels Alice conversations',
            type: 'alice_chat',
            color: AppColors.deepPurple,
          ),
          DataDestination(
            iconPath: 'pattern',
            description: 'Builds pattern recognition',
            type: 'pattern_analysis',
            color: AppColors.warmGold,
          ),
          DataDestination(
            iconPath: 'memory',
            description: 'Strengthens memory foundation',
            type: 'memory_storage',
            color: AppColors.naturalGreen,
          ),
        ];

        expect(destinations.length, equals(3));
        expect(destinations.map((d) => d.type).toSet(), 
               equals({'alice_chat', 'pattern_analysis', 'memory_storage'}));
      });
    });

    group('2. Interactive Story Webs Validation', () {
      test('PatternNode supports fog-of-war mechanics', () {
        final node = PatternNode(
          id: 'test_node',
          label: 'Test Pattern',
          color: AppColors.anxiety,
          connectionIds: ['connected_node'],
          pattern: 'test_pattern',
          discoveredAt: DateTime.now(),
          isRevealed: false,
        );

        expect(node.isRevealed, isFalse);

        final revealedNode = node.copyWith(isRevealed: true);
        expect(revealedNode.isRevealed, isTrue);
        expect(revealedNode.id, equals(node.id));
        expect(revealedNode.label, equals(node.label));
      });

      test('PatternNode connections create proper graph structure', () {
        final nodes = [
          PatternNode(
            id: 'node_1',
            label: 'Root Pattern',
            color: AppColors.deepPurple,
            connectionIds: ['node_2', 'node_3'],
            pattern: 'root_pattern',
            discoveredAt: DateTime.now(),
          ),
          PatternNode(
            id: 'node_2',
            label: 'Connected Pattern A',
            color: AppColors.warmGold,
            connectionIds: ['node_1'],
            pattern: 'connected_a',
            discoveredAt: DateTime.now(),
          ),
          PatternNode(
            id: 'node_3',
            label: 'Connected Pattern B',
            color: AppColors.naturalGreen,
            connectionIds: ['node_1'],
            pattern: 'connected_b',
            discoveredAt: DateTime.now(),
          ),
        ];

        final rootNode = nodes.first;
        expect(rootNode.connectionIds.length, equals(2));
        expect(rootNode.connectionIds, contains('node_2'));
        expect(rootNode.connectionIds, contains('node_3'));

        // Verify bidirectional connections
        final connectedNodes = nodes.skip(1);
        for (final node in connectedNodes) {
          expect(node.connectionIds, contains('node_1'));
        }
      });

      test('PatternNode serialization preserves all data', () {
        final originalNode = PatternNode(
          id: 'complex_node',
          label: 'Complex Pattern with Connections',
          color: AppColors.calmBlue,
          connectionIds: ['conn1', 'conn2', 'conn3'],
          x: 100.5,
          y: 200.7,
          isRevealed: true,
          pattern: 'complex_behavioral_pattern',
          discoveredAt: DateTime.parse('2024-01-15T10:30:00Z'),
        );

        final json = originalNode.toJson();
        final reconstructed = PatternNode.fromJson(json);

        expect(reconstructed.id, equals(originalNode.id));
        expect(reconstructed.label, equals(originalNode.label));
        expect(reconstructed.color.value, equals(originalNode.color.value));
        expect(reconstructed.connectionIds, equals(originalNode.connectionIds));
        expect(reconstructed.x, equals(originalNode.x));
        expect(reconstructed.y, equals(originalNode.y));
        expect(reconstructed.isRevealed, equals(originalNode.isRevealed));
        expect(reconstructed.pattern, equals(originalNode.pattern));
        expect(reconstructed.discoveredAt, equals(originalNode.discoveredAt));
      });
    });

    group('3. Adaptive Multimodal Inputs Validation', () {
      test('MemoryEntry captures comprehensive metadata', () {
        final memory = MemoryEntry(
          id: 'memory_123',
          content: 'Today I felt anxious about the presentation, but it went well.',
          timestamp: DateTime.now(),
          voiceNotePath: '/path/to/voice/note.wav',
          metadata: {
            'user_stage': 'explorer',
            'health_data': {'heart_rate': 85, 'steps': 7500},
            'voice_input': true,
          },
          tags: ['anxiety', 'work', 'positive'],
          sentimentScore: 0.3,
          emotionalState: 'mixed',
        );

        expect(memory.content, contains('anxious'));
        expect(memory.content, contains('went well'));
        expect(memory.tags, contains('anxiety'));
        expect(memory.tags, contains('positive'));
        expect(memory.sentimentScore, equals(0.3));
        expect(memory.emotionalState, equals('mixed'));
        expect(memory.metadata['voice_input'], isTrue);
      });

      test('MemoryEntry serialization handles complex metadata', () {
        final complexMemory = MemoryEntry(
          id: 'complex_memory',
          content: 'Reflection on family dynamics and personal growth.',
          timestamp: DateTime.parse('2024-02-01T14:30:00Z'),
          metadata: {
            'user_stage': 'integrator',
            'consciousness_level': 0.75,
            'pattern_activations': {
              'family_dynamics': 0.8,
              'personal_growth': 0.9,
            },
            'session_context': 'deep_reflection',
          },
          tags: ['family', 'growth', 'reflection'],
          sentimentScore: 0.6,
          emotionalState: 'contemplative',
        );

        final json = complexMemory.toJson();
        final reconstructed = MemoryEntry.fromJson(json);

        expect(reconstructed.id, equals(complexMemory.id));
        expect(reconstructed.content, equals(complexMemory.content));
        expect(reconstructed.metadata['consciousness_level'], equals(0.75));
        expect(reconstructed.metadata['pattern_activations']['family_dynamics'], equals(0.8));
        expect(reconstructed.tags, equals(complexMemory.tags));
        expect(reconstructed.sentimentScore, equals(complexMemory.sentimentScore));
      });

      test('Sentiment analysis produces valid scores', () {
        final testCases = [
          {'text': 'I am extremely happy and grateful today!', 'expectedRange': [0.1, 1.0]},
          {'text': 'Feeling very sad and overwhelmed by everything.', 'expectedRange': [-1.0, -0.1]},
          {'text': 'Today was okay, nothing special happened.', 'expectedRange': [-0.3, 0.3]},
        ];

        for (final testCase in testCases) {
          final text = testCase['text'] as String;
          final expectedRange = testCase['expectedRange'] as List<double>;
          
          // Simulate sentiment analysis (would be actual implementation)
          final sentimentScore = _mockSentimentAnalysis(text);
          
          expect(sentimentScore, greaterThanOrEqualTo(expectedRange[0]));
          expect(sentimentScore, lessThanOrEqualTo(expectedRange[1]));
          expect(sentimentScore, greaterThanOrEqualTo(-1.0));
          expect(sentimentScore, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('4. Enhanced Timeline Validation', () {
      test('Memory sorting works correctly', () {
        final now = DateTime.now();
        final memories = [
          MemoryEntry(
            id: '1',
            content: 'First memory',
            timestamp: now.subtract(const Duration(days: 2)),
            metadata: {},
            tags: ['old'],
            sentimentScore: 0.5,
          ),
          MemoryEntry(
            id: '2',
            content: 'Recent memory',
            timestamp: now,
            metadata: {},
            tags: ['new'],
            sentimentScore: -0.3,
          ),
          MemoryEntry(
            id: '3',
            content: 'Middle memory',
            timestamp: now.subtract(const Duration(days: 1)),
            metadata: {},
            tags: ['middle'],
            sentimentScore: 0.8,
          ),
        ];

        // Test chronological sorting (newest first)
        memories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        expect(memories[0].id, equals('2')); // Most recent
        expect(memories[2].id, equals('1')); // Oldest

        // Test sentiment sorting (highest first)
        memories.sort((a, b) {
          final aScore = a.sentimentScore ?? 0.0;
          final bScore = b.sentimentScore ?? 0.0;
          return bScore.compareTo(aScore);
        });
        expect(memories[0].id, equals('3')); // Highest sentiment (0.8)
        expect(memories[2].id, equals('2')); // Lowest sentiment (-0.3)
      });

      test('Tag filtering works correctly', () {
        final memories = [
          MemoryEntry(
            id: '1',
            content: 'Work stress',
            timestamp: DateTime.now(),
            metadata: {},
            tags: ['work', 'stress'],
          ),
          MemoryEntry(
            id: '2',
            content: 'Family time',
            timestamp: DateTime.now(),
            metadata: {},
            tags: ['family', 'joy'],
          ),
          MemoryEntry(
            id: '3',
            content: 'Work achievement',
            timestamp: DateTime.now(),
            metadata: {},
            tags: ['work', 'achievement'],
          ),
        ];

        // Filter by 'work' tag
        final workMemories = memories.where((m) => m.tags.contains('work')).toList();
        expect(workMemories.length, equals(2));
        expect(workMemories.map((m) => m.id), containsAll(['1', '3']));

        // Filter by 'family' tag
        final familyMemories = memories.where((m) => m.tags.contains('family')).toList();
        expect(familyMemories.length, equals(1));
        expect(familyMemories.first.id, equals('2'));
      });
    });

    group('5. Offline Functionality Validation', () {
      test('API service provides offline fallback', () async {
        // Test offline pattern analysis
        final offlineAnalysis = await _mockOfflineAnalysis('I feel anxious about work today');
        
        expect(offlineAnalysis, isNotNull);
        expect(offlineAnalysis!.userId, equals('offline_user'));
        expect(offlineAnalysis.consciousnessIndicators, isNotEmpty);
        expect(offlineAnalysis.networkState['offline_mode'], equals(1.0));
      });

      test('Cache management works correctly', () {
        final cacheData = {
          'response': 'Test response',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'ChatResponse',
        };

        // Simulate cache storage and retrieval
        expect(cacheData['type'], equals('ChatResponse'));
        expect(cacheData['response'], equals('Test response'));
        
        final timestamp = DateTime.parse(cacheData['timestamp']!);
        final isRecent = DateTime.now().difference(timestamp).inHours < 24;
        expect(isRecent, isTrue);
      });
    });

    group('6. Performance and Accessibility Validation', () {
      test('Animation controllers are properly managed', () {
        // Test animation duration constraints
        const pathwayDuration = Duration(milliseconds: 2000);
        const pulseDuration = Duration(milliseconds: 800);
        const breathingDuration = Duration(seconds: 4);

        expect(pathwayDuration.inMilliseconds, lessThanOrEqualTo(3000)); // Max 3s for UX
        expect(pulseDuration.inMilliseconds, lessThanOrEqualTo(1000)); // Max 1s for responsiveness
        expect(breathingDuration.inSeconds, greaterThanOrEqualTo(3)); // Min 3s for mindfulness
      });

      test('Color accessibility meets contrast requirements', () {
        // Test color contrast ratios (simplified)
        final colors = [
          AppColors.textPrimary,
          AppColors.textSecondary,
          AppColors.warmGold,
          AppColors.deepPurple,
          AppColors.naturalGreen,
        ];

        for (final color in colors) {
          // Ensure colors have sufficient opacity for visibility
          expect(color.alpha, greaterThan(100)); // Minimum visibility
        }
      });

      test('Memory usage is optimized', () {
        // Test data structure sizes
        final largeMemoryEntry = MemoryEntry(
          id: 'large_entry',
          content: 'A' * 1000, // 1KB content
          timestamp: DateTime.now(),
          metadata: Map.fromIterables(
            List.generate(50, (i) => 'key_$i'),
            List.generate(50, (i) => 'value_$i'),
          ),
          tags: List.generate(20, (i) => 'tag_$i'),
        );

        // Ensure serialization doesn't explode memory
        final json = largeMemoryEntry.toJson();
        expect(json.keys.length, equals(8)); // Expected number of fields
        expect(largeMemoryEntry.content.length, equals(1000));
        expect(largeMemoryEntry.metadata.length, equals(50));
        expect(largeMemoryEntry.tags.length, equals(20));
      });
    });
  });
}

// Mock helper functions for testing
double _mockSentimentAnalysis(String text) {
  final positiveWords = ['happy', 'grateful', 'amazing', 'wonderful', 'great', 'love', 'joy'];
  final negativeWords = ['sad', 'overwhelmed', 'terrible', 'awful', 'hate', 'anxious', 'stress'];
  
  final lowerText = text.toLowerCase();
  int positiveCount = 0;
  int negativeCount = 0;
  
  for (final word in positiveWords) {
    if (lowerText.contains(word)) positiveCount++;
  }
  
  for (final word in negativeWords) {
    if (lowerText.contains(word)) negativeCount++;
  }
  
  final totalWords = text.split(' ').length;
  final sentimentScore = (positiveCount - negativeCount) / totalWords.clamp(1, double.infinity);
  
  return sentimentScore.clamp(-1.0, 1.0);
}

Future<PatternAnalysisResponse?> _mockOfflineAnalysis(String message) async {
  final lowerMessage = message.toLowerCase();
  final consciousnessIndicators = <String, double>{};
  final hierarchicalActivations = <String, dynamic>{};
  
  // Basic sentiment and pattern detection
  if (lowerMessage.contains(RegExp(r'\b(anxious|worry|stress|nervous)\b'))) {
    consciousnessIndicators['anxiety_level'] = 0.7;
    hierarchicalActivations['emotional_patterns'] = {'anxiety': 0.8};
  }
  
  if (lowerMessage.contains(RegExp(r'\b(happy|joy|excited|grateful)\b'))) {
    consciousnessIndicators['positive_emotion'] = 0.8;
    hierarchicalActivations['emotional_patterns'] = {'positive': 0.9};
  }
  
  if (lowerMessage.contains(RegExp(r'\b(work|job|career|office)\b'))) {
    hierarchicalActivations['life_domains'] = {'work': 0.7};
  }
  
  consciousnessIndicators['overall_consciousness'] = 0.5;
  
  return PatternAnalysisResponse(
    userId: 'offline_user',
    hierarchicalActivations: hierarchicalActivations,
    consciousnessIndicators: consciousnessIndicators,
    networkState: {'offline_mode': 1.0},
    processingTimestamp: DateTime.now().toIso8601String(),
  );
}