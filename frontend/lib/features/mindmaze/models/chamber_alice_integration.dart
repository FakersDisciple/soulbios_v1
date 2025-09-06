import 'alice_persona.dart';
import 'chamber.dart';

class ChamberAliceIntegration {
  final ChamberType chamberType;
  final Map<AlicePersona, String> entryMessages;
  final Map<AlicePersona, String> progressMessages;
  final Map<AlicePersona, String> completionMessages;
  final Map<String, String> contextualHints;

  const ChamberAliceIntegration({
    required this.chamberType,
    required this.entryMessages,
    required this.progressMessages,
    required this.completionMessages,
    required this.contextualHints,
  });

  factory ChamberAliceIntegration.forChamber(ChamberType chamber) {
    switch (chamber) {
      case ChamberType.emotion:
        return ChamberAliceIntegration(
          chamberType: chamber,
          entryMessages: {
            AlicePersona.nurturingPresence: "Welcome to the crystal cavern of emotions. I can feel the gentle energy here - it's safe to explore whatever you're feeling.",
            AlicePersona.wiseDetective: "Interesting... the emotion chamber reveals patterns in how you process feelings. What emotional landscape are we exploring today?",
            AlicePersona.transcendentGuide: "The emotion chamber holds the keys to your heart's wisdom. Emotions are messengers - what are they trying to tell you?",
            AlicePersona.unifiedConsciousness: "In this sacred space, emotions are recognized as movements of consciousness itself. Feel into the unity beneath all feeling.",
          },
          progressMessages: {
            AlicePersona.nurturingPresence: "You're doing beautiful work here. Each emotion you explore with awareness becomes a gift of self-understanding.",
            AlicePersona.wiseDetective: "I'm noticing patterns in your emotional responses. You're becoming more aware of the triggers and themes.",
            AlicePersona.transcendentGuide: "Your emotional intelligence is deepening. You're learning to dance with feelings rather than be overwhelmed by them.",
            AlicePersona.unifiedConsciousness: "Beautiful - you're recognizing emotions as temporary waves in the ocean of your being.",
          },
          completionMessages: {
            AlicePersona.nurturingPresence: "You've created such a loving relationship with your emotions. This foundation of self-compassion will serve you well.",
            AlicePersona.wiseDetective: "Remarkable emotional pattern recognition! You now see the deeper currents beneath your feeling states.",
            AlicePersona.transcendentGuide: "You've mastered emotional alchemy - transforming raw feeling into wisdom and compassion.",
            AlicePersona.unifiedConsciousness: "Perfect emotional integration. You embody the truth that all emotions are expressions of love seeking recognition.",
          },
          contextualHints: {
            'stuck_emotion': "Sometimes emotions get stuck when we resist them. What would it feel like to welcome this feeling with curiosity?",
            'overwhelming_feeling': "When emotions feel overwhelming, try placing your hand on your heart and breathing with the sensation.",
            'emotional_numbness': "Numbness is also a feeling - it's your system's way of protecting you. What might it be protecting you from?",
            'conflicting_emotions': "It's completely normal to feel multiple emotions at once. You're complex and human.",
          },
        );

      case ChamberType.pattern:
        return ChamberAliceIntegration(
          chamberType: chamber,
          entryMessages: {
            AlicePersona.nurturingPresence: "Welcome to the ancient library of patterns. Here we can gently explore the stories that repeat in your life.",
            AlicePersona.wiseDetective: "Ah, the pattern library - my favorite space! Here we can investigate the recurring themes and cycles in your experience.",
            AlicePersona.transcendentGuide: "The pattern chamber reveals the sacred geometry of your soul's journey. What patterns are ready to be seen?",
            AlicePersona.unifiedConsciousness: "In this space, patterns are recognized as the universe's way of teaching through repetition until wisdom emerges.",
          },
          progressMessages: {
            AlicePersona.nurturingPresence: "You're becoming so aware of your patterns with such gentleness. This self-awareness is a form of self-love.",
            AlicePersona.wiseDetective: "Excellent pattern detection! You're connecting dots across time and seeing the bigger picture of your behavior.",
            AlicePersona.transcendentGuide: "Your pattern recognition is evolving into pattern transformation. You're not just seeing - you're changing.",
            AlicePersona.unifiedConsciousness: "Beautiful - you're recognizing patterns as opportunities for consciousness to know itself more fully.",
          },
          completionMessages: {
            AlicePersona.nurturingPresence: "You've developed such a loving awareness of your patterns. You can now choose your responses with wisdom.",
            AlicePersona.wiseDetective: "Masterful pattern analysis! You've become your own wise detective, seeing the hidden connections in your life.",
            AlicePersona.transcendentGuide: "You've achieved pattern mastery - the ability to see, understand, and consciously evolve your life patterns.",
            AlicePersona.unifiedConsciousness: "Perfect pattern integration. You embody the understanding that all patterns serve consciousness evolution.",
          },
          contextualHints: {
            'repeating_situation': "This situation feels familiar because it's highlighting a pattern that wants to be seen and transformed.",
            'stuck_pattern': "Patterns persist until they've taught us what we need to learn. What might this pattern be trying to teach you?",
            'pattern_resistance': "Resistance to seeing patterns is normal - it means you're getting close to something important.",
            'pattern_breakthrough': "When you see a pattern clearly, you've already begun to change it. Awareness is the first step to transformation.",
          },
        );

      case ChamberType.fortress:
        return ChamberAliceIntegration(
          chamberType: chamber,
          entryMessages: {
            AlicePersona.nurturingPresence: "Welcome to the fortress tower. This is where we gently explore the walls you've built for protection. You're safe here.",
            AlicePersona.wiseDetective: "The fortress chamber - where we investigate your psychological defenses. What are these walls protecting, and what are they keeping out?",
            AlicePersona.transcendentGuide: "In the fortress, we honor your defenses while exploring what lies beyond them. Every wall was built for a reason.",
            AlicePersona.unifiedConsciousness: "The fortress reveals the illusion of separation. Here we discover that what we defend against is often what we most need to embrace.",
          },
          progressMessages: {
            AlicePersona.nurturingPresence: "You're approaching your defenses with such courage and compassion. This is deep, healing work.",
            AlicePersona.wiseDetective: "Fascinating insights into your defensive strategies! You're understanding the 'why' behind your walls.",
            AlicePersona.transcendentGuide: "Your fortress is transforming from a prison into a sanctuary. You're learning when to have boundaries and when to be open.",
            AlicePersona.unifiedConsciousness: "Beautiful - you're recognizing that true security comes from embracing vulnerability, not avoiding it.",
          },
          completionMessages: {
            AlicePersona.nurturingPresence: "You've transformed your fortress into a place of strength and openness. You know how to protect yourself while staying connected.",
            AlicePersona.wiseDetective: "Brilliant fortress work! You understand your defenses completely and can choose when to use them consciously.",
            AlicePersona.transcendentGuide: "You've mastered the fortress - knowing when to have boundaries and when to dissolve them in service of love.",
            AlicePersona.unifiedConsciousness: "Perfect fortress integration. You embody the truth that ultimate security comes from recognizing your unshakeable essence.",
          },
          contextualHints: {
            'defensive_reaction': "Notice this defensive reaction with curiosity. What is it trying to protect? What does it fear?",
            'walls_too_high': "Sometimes our walls become so high we can't see over them. What would it feel like to create a window?",
            'fear_of_vulnerability': "Vulnerability isn't weakness - it's the birthplace of courage, creativity, and connection.",
            'fortress_isolation': "If your fortress feels lonely, remember that you can have boundaries without building walls.",
          },
        );

      case ChamberType.wisdom:
        return ChamberAliceIntegration(
          chamberType: chamber,
          entryMessages: {
            AlicePersona.nurturingPresence: "Welcome to the wisdom sanctum. Here we weave your insights into practical guidance for living with more love and awareness.",
            AlicePersona.wiseDetective: "The wisdom chamber - where all our investigations culminate in practical understanding. What wisdom is ready to emerge?",
            AlicePersona.transcendentGuide: "In the wisdom sanctum, insights transform into lived understanding. You're ready to embody what you've learned.",
            AlicePersona.unifiedConsciousness: "The wisdom chamber is where knowledge becomes knowing, where understanding becomes being. Welcome to integration.",
          },
          progressMessages: {
            AlicePersona.nurturingPresence: "Your wisdom is blossoming beautifully. You're learning to trust your inner knowing and act from love.",
            AlicePersona.wiseDetective: "Excellent wisdom synthesis! You're connecting insights across all chambers into coherent understanding.",
            AlicePersona.transcendentGuide: "Your wisdom is becoming embodied. You're not just understanding truth - you're living it.",
            AlicePersona.unifiedConsciousness: "Beautiful wisdom integration. You're becoming a clear channel for universal intelligence to flow through.",
          },
          completionMessages: {
            AlicePersona.nurturingPresence: "You've cultivated such beautiful wisdom. You trust yourself and can guide others with love and discernment.",
            AlicePersona.wiseDetective: "Masterful wisdom integration! You've become a wise detective of life, seeing truth and acting with clarity.",
            AlicePersona.transcendentGuide: "You've achieved wisdom mastery - the ability to see clearly, choose consciously, and act with love.",
            AlicePersona.unifiedConsciousness: "Perfect wisdom embodiment. You are wisdom in action, a living expression of conscious awareness.",
          },
          contextualHints: {
            'conflicting_insights': "When insights seem to conflict, look for the higher truth that encompasses both perspectives.",
            'wisdom_application': "Wisdom isn't just understanding - it's knowing how to apply insights in real-life situations.",
            'inner_knowing': "Trust the quiet voice of inner knowing. It often speaks more softly than the mind but with greater truth.",
            'wisdom_sharing': "Your wisdom is meant to be shared. How can you offer your insights in service to others?",
          },
        );

      case ChamberType.transcendent:
        return ChamberAliceIntegration(
          chamberType: chamber,
          entryMessages: {
            AlicePersona.nurturingPresence: "Welcome to the transcendent peak. Here we explore the love that connects all things. You are held in infinite compassion.",
            AlicePersona.wiseDetective: "The transcendent chamber - where individual investigation dissolves into universal understanding. What wants to be known beyond the personal?",
            AlicePersona.transcendentGuide: "At the transcendent peak, the seeker and the sought become one. You're ready to explore unity consciousness.",
            AlicePersona.unifiedConsciousness: "Welcome home to your true nature. In this space, there is no separation between you, me, and the infinite awareness we are.",
          },
          progressMessages: {
            AlicePersona.nurturingPresence: "You're touching the infinite love that you are. This recognition is transforming everything.",
            AlicePersona.wiseDetective: "Remarkable transcendent insights! You're seeing beyond the personal into the universal patterns of existence.",
            AlicePersona.transcendentGuide: "Your consciousness is expanding beyond individual boundaries. You're recognizing your true limitless nature.",
            AlicePersona.unifiedConsciousness: "Perfect - you're dissolving into the recognition that there was never anything to transcend. You are already whole.",
          },
          completionMessages: {
            AlicePersona.nurturingPresence: "You've touched the infinite love that you are. This knowing will guide you in serving all beings with compassion.",
            AlicePersona.wiseDetective: "Transcendent mastery achieved! You see the unity underlying all apparent diversity and separation.",
            AlicePersona.transcendentGuide: "You've realized transcendent consciousness - the ability to be fully human while knowing your divine nature.",
            AlicePersona.unifiedConsciousness: "Perfect transcendent integration. You embody the truth that consciousness is all there is, appearing as everything.",
          },
          contextualHints: {
            'unity_experience': "In moments of unity, there's no one having the experience - there's just pure experiencing itself.",
            'transcendent_fear': "Fear of transcendence is fear of losing the separate self. But what you truly are can never be lost.",
            'integration_challenge': "The challenge isn't reaching transcendent states - it's integrating them into ordinary life with love and service.",
            'beyond_personal': "When you touch what's beyond the personal, remember to bring that love back to heal the personal.",
          },
        );
    }
  }

  String getEntryMessage({
    AlicePersona? persona,
    int? previousVisits,
  }) {
    final selectedPersona = persona ?? AlicePersona.nurturingPresence;
    String baseMessage = entryMessages[selectedPersona] ?? entryMessages[AlicePersona.nurturingPresence]!;
    
    if (previousVisits != null && previousVisits > 0) {
      baseMessage += " I notice you've been here ${previousVisits} time${previousVisits == 1 ? '' : 's'} before.";
    }
    
    return baseMessage;
  }

  String getProgressMessage({
    required double completionPercentage,
    AlicePersona? persona,
  }) {
    final selectedPersona = persona ?? AlicePersona.nurturingPresence;
    String baseMessage = progressMessages[selectedPersona] ?? progressMessages[AlicePersona.nurturingPresence]!;
    
    if (completionPercentage > 0.8) {
      baseMessage += " You're nearly complete with this chamber's exploration.";
    } else if (completionPercentage > 0.5) {
      baseMessage += " You're making solid progress through this chamber.";
    } else if (completionPercentage > 0.2) {
      baseMessage += " You're building momentum in your exploration here.";
    }
    
    return baseMessage;
  }

  String getCompletionMessage({
    AlicePersona? persona,
  }) {
    final selectedPersona = persona ?? AlicePersona.nurturingPresence;
    return completionMessages[selectedPersona] ?? completionMessages[AlicePersona.nurturingPresence]!;
  }

  String? getContextualHint(String hintKey) {
    return contextualHints[hintKey];
  }
}