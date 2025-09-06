import 'package:flutter/material.dart';

enum CharacterArchetype {
  compassionateFriend,
  resilientExplorer,
  wiseDetective;

  String get value {
    switch (this) {
      case CharacterArchetype.compassionateFriend:
        return 'compassionate_friend';
      case CharacterArchetype.resilientExplorer:
        return 'resilient_explorer';
      case CharacterArchetype.wiseDetective:
        return 'wise_detective';
    }
  }
}

class Character {
  final String id;
  final String name;
  final String description;
  final CharacterArchetype archetype;
  final String avatarPath;
  final Color primaryColor;
  final List<String> traits;
  final Map<String, dynamic> personalityMatrix;
  final bool isUnlocked;
  final int relationshipLevel;

  const Character({
    required this.id,
    required this.name,
    required this.description,
    required this.archetype,
    required this.avatarPath,
    required this.primaryColor,
    required this.traits,
    required this.personalityMatrix,
    this.isUnlocked = false,
    this.relationshipLevel = 0,
  });

  Character copyWith({
    String? id,
    String? name,
    String? description,
    CharacterArchetype? archetype,
    String? avatarPath,
    Color? primaryColor,
    List<String>? traits,
    Map<String, dynamic>? personalityMatrix,
    bool? isUnlocked,
    int? relationshipLevel,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      archetype: archetype ?? this.archetype,
      avatarPath: avatarPath ?? this.avatarPath,
      primaryColor: primaryColor ?? this.primaryColor,
      traits: traits ?? this.traits,
      personalityMatrix: personalityMatrix ?? this.personalityMatrix,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      relationshipLevel: relationshipLevel ?? this.relationshipLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'archetype': archetype.toString(),
      'avatarPath': avatarPath,
      'primaryColor': primaryColor.value,
      'traits': traits,
      'personalityMatrix': personalityMatrix,
      'isUnlocked': isUnlocked,
      'relationshipLevel': relationshipLevel,
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      archetype: CharacterArchetype.values.firstWhere(
        (e) => e.toString() == json['archetype'],
      ),
      avatarPath: json['avatarPath'],
      primaryColor: Color(json['primaryColor']),
      traits: List<String>.from(json['traits']),
      personalityMatrix: Map<String, dynamic>.from(json['personalityMatrix']),
      isUnlocked: json['isUnlocked'] ?? false,
      relationshipLevel: json['relationshipLevel'] ?? 0,
    );
  }
}