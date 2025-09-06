import 'package:flutter/material.dart';

enum AlicePersonaType {
  nurturingPresence,
  wiseDetective,
  transcendentGuide,
  unifiedConsciousness,
}

class AlicePersona {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String description;
  final AlicePersonaType type;

  const AlicePersona({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.description,
    required this.type,
  });

  static const AlicePersona nurturingPresence = AlicePersona(
    name: 'Alice',
    primaryColor: Color(0xFF9C27B0),
    secondaryColor: Color(0xFF673AB7),
    icon: Icons.psychology,
    description: 'Your conscious living companion',
    type: AlicePersonaType.nurturingPresence,
  );

  static const AlicePersona wiseDetective = AlicePersona(
    name: 'Alice',
    primaryColor: Color(0xFF2196F3),
    secondaryColor: Color(0xFF1976D2),
    icon: Icons.search,
    description: 'Your analytical guide',
    type: AlicePersonaType.wiseDetective,
  );

  static const AlicePersona transcendentGuide = AlicePersona(
    name: 'Alice',
    primaryColor: Color(0xFF4CAF50),
    secondaryColor: Color(0xFF388E3C),
    icon: Icons.auto_awesome,
    description: 'Your wisdom guide',
    type: AlicePersonaType.transcendentGuide,
  );

  static const AlicePersona unifiedConsciousness = AlicePersona(
    name: 'Alice',
    primaryColor: Color(0xFFFFD700),
    secondaryColor: Color(0xFFFFC107),
    icon: Icons.all_inclusive,
    description: 'Your unified consciousness',
    type: AlicePersonaType.unifiedConsciousness,
  );
}

extension AlicePersonaExtension on AlicePersonaType {
  String get displayName {
    switch (this) {
      case AlicePersonaType.nurturingPresence:
        return 'Nurturing Presence';
      case AlicePersonaType.wiseDetective:
        return 'Wise Detective';
      case AlicePersonaType.transcendentGuide:
        return 'Transcendent Guide';
      case AlicePersonaType.unifiedConsciousness:
        return 'Unified Consciousness';
    }
  }

  String get description {
    switch (this) {
      case AlicePersonaType.nurturingPresence:
        return 'Gentle and emotionally supportive';
      case AlicePersonaType.wiseDetective:
        return 'Socratic questioning with compassionate inquiry';
      case AlicePersonaType.transcendentGuide:
        return 'Deep wisdom with meta-pattern insights';
      case AlicePersonaType.unifiedConsciousness:
        return 'Transcendent wisdom with unity awareness';
    }
  }

  String get responseStyle {
    switch (this) {
      case AlicePersonaType.nurturingPresence:
        return 'nurturing';
      case AlicePersonaType.wiseDetective:
        return 'investigative';
      case AlicePersonaType.transcendentGuide:
        return 'wisdom_guide';
      case AlicePersonaType.unifiedConsciousness:
        return 'transcendent';
    }
  }

  static AlicePersonaType fromConsciousnessLevel(double level) {
    if (level < 0.3) {
      return AlicePersonaType.nurturingPresence;
    } else if (level < 0.6) {
      return AlicePersonaType.wiseDetective;
    } else if (level < 0.8) {
      return AlicePersonaType.transcendentGuide;
    } else {
      return AlicePersonaType.unifiedConsciousness;
    }
  }

  static AlicePersonaType fromString(String personaName) {
    switch (personaName.toLowerCase()) {
      case 'nurturing_presence':
      case 'nurturingpresence':
        return AlicePersonaType.nurturingPresence;
      case 'wise_detective':
      case 'wisedetective':
        return AlicePersonaType.wiseDetective;
      case 'transcendent_guide':
      case 'transcendentguide':
        return AlicePersonaType.transcendentGuide;
      case 'unified_consciousness':
      case 'unifiedconsciousness':
        return AlicePersonaType.unifiedConsciousness;
      default:
        return AlicePersonaType.nurturingPresence;
    }
  }
}