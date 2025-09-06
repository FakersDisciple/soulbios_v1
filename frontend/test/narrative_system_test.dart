import 'package:flutter_test/flutter_test.dart';
import 'package:encarta_soulbios/features/mindmaze/models/chamber_narrative.dart';
import 'package:encarta_soulbios/features/mindmaze/models/character.dart';
import 'package:encarta_soulbios/services/narrative_service.dart';
import 'package:encarta_soulbios/services/character_service.dart';

void main() {
  group('Narrative System Tests', () {
    late NarrativeService narrativeService;
    late CharacterService characterService;

    setUp(() {
      narrativeService = NarrativeService();
      characterService = CharacterService();
    });

    group('NarrativeService', () {
      test('should initialize successfully', () async {
        await narrativeService.initialize();
        expect(narrativeService, isNotNull);
      });

      test('should load emotion chamber narratives for all characters', () async {
        await narrativeService.initialize();
        
        // Test Compassionate Friend narrative
        final cfNarrative = narrativeService.getNarrative(
          'emotion',
          CharacterArchetype.compassionateFriend,
        );
        expect(cfNarrative, isNotNull);
        expect(cfNarrative!.chamberId, equals('emotion'));
        expect(cfNarrative.characterArchetype, equals(CharacterArchetype.compassionateFriend));
        expect(cfNarrative.nodes.isNotEmpty, isTrue);

        // Test Resilient Explorer narrative
        final reNarrative = narrativeService.getNarrative(
          'emotion',
          CharacterArchetype.resilientExplorer,
        );
        expect(reNarrative, isNotNull);
        expect(reNarrative!.chamberId, equals('emotion'));
        expect(reNarrative.characterArchetype, equals(CharacterArchetype.resilientExplorer));

        // Test Wise Detective narrative
        final wdNarrative = narrativeService.getNarrative(
          'emotion',
          CharacterArchetype.wiseDetective,
        );
        expect(wdNarrative, isNotNull);
        expect(wdNarrative!.chamberId, equals('emotion'));
        expect(wdNarrative.characterArchetype, equals(CharacterArchetype.wiseDetective));
      });

      test('should load fortress chamber narratives for all characters', () async {
        await narrativeService.initialize();
        
        // Test all character archetypes have fortress narratives
        for (final archetype in CharacterArchetype.values) {
          final narrative = narrativeService.getNarrative('fortress', archetype);
          expect(narrative, isNotNull, reason: 'Missing fortress narrative for $archetype');
          expect(narrative!.chamberId, equals('fortress'));
          expect(narrative.characterArchetype, equals(archetype));
        }
      });

      test('should process narrative choices correctly', () async {
        await narrativeService.initialize();
        
        final narrative = narrativeService.getNarrative(
          'emotion',
          CharacterArchetype.compassionateFriend,
        )!;
        
        final initialState = NarrativeState(currentNodeId: narrative.startNodeId);
        final startNode = narrative.getNode(initialState.currentNodeId)!;
        
        expect(startNode.choices.isNotEmpty, isTrue);
        
        // Process first choice
        final firstChoice = startNode.choices.first;
        final newState = await narrativeService.processChoice(
          narrative,
          initialState,
          firstChoice.id,
        );
        
        expect(newState.currentNodeId, equals(firstChoice.targetNodeId));
        expect(newState.visitedNodes.contains(firstChoice.targetNodeId), isTrue);
        expect(newState.progressScore, greaterThan(initialState.progressScore));
      });

      test('should detect narrative completion correctly', () async {
        await narrativeService.initialize();
        
        final narrative = narrativeService.getNarrative(
          'emotion',
          CharacterArchetype.compassionateFriend,
        )!;
        
        // Test with completion node
        final completionState = NarrativeState(
          currentNodeId: narrative.completionNodeIds.first,
        );
        expect(narrativeService.isNarrativeComplete(narrative, completionState), isTrue);
        
        // Test with non-completion node
        final nonCompletionState = NarrativeState(
          currentNodeId: narrative.startNodeId,
        );
        expect(narrativeService.isNarrativeComplete(narrative, nonCompletionState), isFalse);
      });

      test('should return null for unsupported chamber-character combinations', () async {
        await narrativeService.initialize();
        
        final narrative = narrativeService.getNarrative(
          'unsupported_chamber',
          CharacterArchetype.compassionateFriend,
        );
        expect(narrative, isNull);
      });
    });

    group('CharacterService Narrative Integration', () {
      test('should provide narrative support status', () async {
        // Test supported combinations
        expect(
          await characterService.hasNarrativeSupport(
            'emotion',
            CharacterArchetype.compassionateFriend,
          ),
          isTrue,
        );
        
        expect(
          await characterService.hasNarrativeSupport(
            'fortress',
            CharacterArchetype.resilientExplorer,
          ),
          isTrue,
        );

        // Test unsupported combination
        expect(
          await characterService.hasNarrativeSupport(
            'unsupported_chamber',
            CharacterArchetype.wiseDetective,
          ),
          isFalse,
        );
      });

      test('should provide character-specific narrative intros', () {
        // Test Compassionate Friend intros
        final cfEmotionIntro = characterService.getCharacterNarrativeIntro(
          CharacterArchetype.compassionateFriend,
          'emotion',
        );
        expect(cfEmotionIntro.contains('emotional currents'), isTrue);

        final cfFortressIntro = characterService.getCharacterNarrativeIntro(
          CharacterArchetype.compassionateFriend,
          'fortress',
        );
        expect(cfFortressIntro.contains('protective walls'), isTrue);

        // Test Resilient Explorer intros
        final reEmotionIntro = characterService.getCharacterNarrativeIntro(
          CharacterArchetype.resilientExplorer,
          'emotion',
        );
        expect(reEmotionIntro.contains('energy'), isTrue);

        // Test Wise Detective intros
        final wdEmotionIntro = characterService.getCharacterNarrativeIntro(
          CharacterArchetype.wiseDetective,
          'emotion',
        );
        expect(wdEmotionIntro.contains('patterns'), isTrue);
      });

      test('should retrieve chamber narratives through service', () async {
        final narrative = await characterService.getChamberNarrative(
          'emotion',
          CharacterArchetype.compassionateFriend,
        );
        
        expect(narrative, isNotNull);
        expect(narrative!.chamberId, equals('emotion'));
        expect(narrative.characterArchetype, equals(CharacterArchetype.compassionateFriend));
      });
    });

    group('Narrative Models', () {
      test('should serialize and deserialize NarrativeNode correctly', () {
        const originalNode = NarrativeNode(
          id: 'test_node',
          type: NarrativeNodeType.dialogue,
          content: 'Test content',
          choices: [
            NarrativeChoice(
              id: 'choice_1',
              text: 'Choice text',
              targetNodeId: 'target_node',
              effects: {'progress': 10},
            ),
          ],
          nextNodeId: 'next_node',
          metadata: {'test': 'value'},
        );

        final json = originalNode.toJson();
        final deserializedNode = NarrativeNode.fromJson(json);

        expect(deserializedNode.id, equals(originalNode.id));
        expect(deserializedNode.type, equals(originalNode.type));
        expect(deserializedNode.content, equals(originalNode.content));
        expect(deserializedNode.choices.length, equals(originalNode.choices.length));
        expect(deserializedNode.nextNodeId, equals(originalNode.nextNodeId));
        expect(deserializedNode.metadata, equals(originalNode.metadata));
      });

      test('should serialize and deserialize NarrativeState correctly', () {
        const originalState = NarrativeState(
          currentNodeId: 'current_node',
          variables: {'test_var': 'test_value'},
          visitedNodes: ['node1', 'node2'],
          progressScore: 50,
        );

        final json = originalState.toJson();
        final deserializedState = NarrativeState.fromJson(json);

        expect(deserializedState.currentNodeId, equals(originalState.currentNodeId));
        expect(deserializedState.variables, equals(originalState.variables));
        expect(deserializedState.visitedNodes, equals(originalState.visitedNodes));
        expect(deserializedState.progressScore, equals(originalState.progressScore));
      });

      test('should copy NarrativeState with modifications', () {
        const originalState = NarrativeState(
          currentNodeId: 'original_node',
          progressScore: 10,
        );

        final copiedState = originalState.copyWith(
          currentNodeId: 'new_node',
          progressScore: 20,
        );

        expect(copiedState.currentNodeId, equals('new_node'));
        expect(copiedState.progressScore, equals(20));
        expect(copiedState.variables, equals(originalState.variables));
        expect(copiedState.visitedNodes, equals(originalState.visitedNodes));
      });
    });

    group('Narrative Content Validation', () {
      test('should have meaningful dialogue content for all narratives', () async {
        await narrativeService.initialize();
        
        final allNarratives = narrativeService.getAllNarratives();
        expect(allNarratives.isNotEmpty, isTrue);

        for (final narrative in allNarratives) {
          // Check start node exists and has content
          final startNode = narrative.startNode;
          expect(startNode.content.isNotEmpty, isTrue);
          expect(startNode.content.length, greaterThan(20)); // Meaningful content

          // Check all nodes have appropriate content
          for (final node in narrative.nodes.values) {
            expect(node.content.isNotEmpty, isTrue);
            
            // Dialogue nodes should have substantial content
            if (node.type == NarrativeNodeType.dialogue) {
              expect(node.content.length, greaterThan(30));
            }
            
            // Insight nodes should have insight markers
            if (node.type == NarrativeNodeType.insight) {
              expect(node.content.contains('Insight:'), isTrue);
            }
          }

          // Check completion nodes exist
          expect(narrative.completionNodeIds.isNotEmpty, isTrue);
          for (final completionId in narrative.completionNodeIds) {
            final completionNode = narrative.getNode(completionId);
            expect(completionNode, isNotNull);
            expect(completionNode!.type, equals(NarrativeNodeType.completion));
          }
        }
      });

      test('should have character-appropriate dialogue styles', () async {
        await narrativeService.initialize();
        
        // Test Compassionate Friend style
        final cfNarrative = narrativeService.getNarrative(
          'emotion',
          CharacterArchetype.compassionateFriend,
        )!;
        final cfStartContent = cfNarrative.startNode.content.toLowerCase();
        expect(
          cfStartContent.contains('sense') || 
          cfStartContent.contains('feel') || 
          cfStartContent.contains('together'),
          isTrue,
        );

        // Test Resilient Explorer style
        final reNarrative = narrativeService.getNarrative(
          'emotion',
          CharacterArchetype.resilientExplorer,
        )!;
        final reStartContent = reNarrative.startNode.content.toLowerCase();
        expect(
          reStartContent.contains('explore') || 
          reStartContent.contains('growth') || 
          reStartContent.contains('strength'),
          isTrue,
        );

        // Test Wise Detective style
        final wdNarrative = narrativeService.getNarrative(
          'emotion',
          CharacterArchetype.wiseDetective,
        )!;
        final wdStartContent = wdNarrative.startNode.content.toLowerCase();
        expect(
          wdStartContent.contains('pattern') || 
          wdStartContent.contains('investigate') || 
          wdStartContent.contains('detect'),
          isTrue,
        );
      });

      test('should have branching paths with meaningful choices', () async {
        await narrativeService.initialize();
        
        final allNarratives = narrativeService.getAllNarratives();
        
        for (final narrative in allNarratives) {
          final startNode = narrative.startNode;
          
          // Start nodes should have choices
          expect(startNode.choices.isNotEmpty, isTrue);
          expect(startNode.choices.length, greaterThanOrEqualTo(2));
          
          // Each choice should have meaningful text
          for (final choice in startNode.choices) {
            expect(choice.text.isNotEmpty, isTrue);
            expect(choice.text.length, greaterThan(10));
            expect(choice.targetNodeId.isNotEmpty, isTrue);
            
            // Target node should exist
            final targetNode = narrative.getNode(choice.targetNodeId);
            expect(targetNode, isNotNull);
          }
        }
      });
    });

    group('Performance Tests', () {
      test('should initialize narratives quickly', () async {
        final stopwatch = Stopwatch()..start();
        await narrativeService.initialize();
        stopwatch.stop();
        
        // Should initialize in under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should process choices quickly', () async {
        await narrativeService.initialize();
        
        final narrative = narrativeService.getNarrative(
          'emotion',
          CharacterArchetype.compassionateFriend,
        )!;
        
        final initialState = NarrativeState(currentNodeId: narrative.startNodeId);
        final startNode = narrative.getNode(initialState.currentNodeId)!;
        final firstChoice = startNode.choices.first;
        
        final stopwatch = Stopwatch()..start();
        await narrativeService.processChoice(narrative, initialState, firstChoice.id);
        stopwatch.stop();
        
        // Should process choice in under 10ms
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });
  });
}