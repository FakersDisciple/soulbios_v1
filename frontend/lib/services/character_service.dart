import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/mindmaze/models/character.dart';
import '../features/mindmaze/models/chamber_narrative.dart';
import 'narrative_service.dart';

final characterServiceProvider = Provider<CharacterService>((ref) {
  return CharacterService();
});

class CharacterService {
  static final CharacterService _instance = CharacterService._internal();
  factory CharacterService() => _instance;
  CharacterService._internal();

  final List<Character> _characters = [
    Character(
      id: 'compassionate_friend',
      name: 'Aria',
      description: 'A warm and empathetic companion who offers comfort and understanding.',
      archetype: CharacterArchetype.compassionateFriend,
      avatarPath: 'assets/characters/aria.png',
      primaryColor: const Color(0xFFE91E63),
      traits: ['Empathetic', 'Supportive', 'Nurturing', 'Patient'],
      personalityMatrix: {
        'empathy': 0.9,
        'logic': 0.6,
        'creativity': 0.7,
        'assertiveness': 0.4,
      },
      isUnlocked: true,
    ),
    Character(
      id: 'resilient_explorer',
      name: 'Zara',
      description: 'An adventurous spirit who encourages growth and exploration.',
      archetype: CharacterArchetype.resilientExplorer,
      avatarPath: 'assets/characters/zara.png',
      primaryColor: const Color(0xFF4CAF50),
      traits: ['Adventurous', 'Resilient', 'Optimistic', 'Encouraging'],
      personalityMatrix: {
        'empathy': 0.7,
        'logic': 0.7,
        'creativity': 0.9,
        'assertiveness': 0.8,
      },
      isUnlocked: false,
    ),
    Character(
      id: 'wise_detective',
      name: 'Sage',
      description: 'A thoughtful analyst who helps uncover deeper insights.',
      archetype: CharacterArchetype.wiseDetective,
      avatarPath: 'assets/characters/sage.png',
      primaryColor: const Color(0xFF2196F3),
      traits: ['Analytical', 'Wise', 'Perceptive', 'Methodical'],
      personalityMatrix: {
        'empathy': 0.6,
        'logic': 0.9,
        'creativity': 0.8,
        'assertiveness': 0.7,
      },
      isUnlocked: false,
    ),
  ];

  List<Character> getAllCharacters() {
    return List.unmodifiable(_characters);
  }

  List<Character> getUnlockedCharacters() {
    return _characters.where((character) => character.isUnlocked).toList();
  }

  Character? getCharacterById(String id) {
    try {
      return _characters.firstWhere((character) => character.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> unlockCharacter(String characterId) async {
    final index = _characters.indexWhere((char) => char.id == characterId);
    if (index != -1) {
      _characters[index] = _characters[index].copyWith(isUnlocked: true);
    }
  }

  Future<void> updateRelationshipLevel(String characterId, int level) async {
    final index = _characters.indexWhere((char) => char.id == characterId);
    if (index != -1) {
      _characters[index] = _characters[index].copyWith(relationshipLevel: level);
    }
  }

  Color getCharacterColor(CharacterArchetype archetype) {
    switch (archetype) {
      case CharacterArchetype.compassionateFriend:
        return const Color(0xFFE91E63);
      case CharacterArchetype.resilientExplorer:
        return const Color(0xFF4CAF50);
      case CharacterArchetype.wiseDetective:
        return const Color(0xFF2196F3);
    }
  }

  IconData getCharacterIcon(CharacterArchetype archetype) {
    switch (archetype) {
      case CharacterArchetype.compassionateFriend:
        return Icons.favorite;
      case CharacterArchetype.resilientExplorer:
        return Icons.explore;
      case CharacterArchetype.wiseDetective:
        return Icons.psychology;
    }
  }

  Future<String> getCharacterChamberNarrative(CharacterArchetype archetype, String chamberType) async {
    // Simulate API call for character-specific chamber narrative
    await Future.delayed(const Duration(milliseconds: 300));
    
    switch (archetype) {
      case CharacterArchetype.compassionateFriend:
        return "Let's explore this together with kindness and understanding.";
      case CharacterArchetype.resilientExplorer:
        return "This challenge is an opportunity for growth and discovery!";
      case CharacterArchetype.wiseDetective:
        return "Let's analyze this situation and uncover the deeper patterns.";
    }
  }

  Future<ChamberNarrative?> getChamberNarrative(String chamberId, CharacterArchetype archetype) async {
    await NarrativeService().initialize();
    return NarrativeService().getNarrative(chamberId, archetype);
  }

  Future<bool> hasNarrativeSupport(String chamberId, CharacterArchetype archetype) async {
    final narrative = await getChamberNarrative(chamberId, archetype);
    return narrative != null;
  }

  String getCharacterNarrativeIntro(CharacterArchetype archetype, String chamberType) {
    switch (archetype) {
      case CharacterArchetype.compassionateFriend:
        switch (chamberType.toLowerCase()) {
          case 'emotion':
            return "I sense the emotional currents in this space. Let's explore your feelings with gentle curiosity.";
          case 'fortress':
            return "I can feel the protective walls around your heart. They've served you well - let's honor them while exploring what lies beyond.";
          default:
            return "I'm here to offer comfort and understanding as we journey together.";
        }
      case CharacterArchetype.resilientExplorer:
        switch (chamberType.toLowerCase()) {
          case 'emotion':
            return "Every emotion is energy waiting to be transformed! Let's turn these feelings into fuel for your growth.";
          case 'fortress':
            return "I see a mighty fortress built from your experiences! What adventures await beyond these walls?";
          default:
            return "Ready for an adventure? Every challenge is just another opportunity to discover your strength!";
        }
      case CharacterArchetype.wiseDetective:
        switch (chamberType.toLowerCase()) {
          case 'emotion':
            return "Fascinating emotional patterns detected. Each feeling is a clue in the mystery of your consciousness.";
          case 'fortress':
            return "Intriguing defensive architecture. Let's investigate what your psyche is protecting and why.";
          default:
            return "The patterns are revealing themselves. Let's investigate what your mind is trying to show you.";
        }
    }
  }
}