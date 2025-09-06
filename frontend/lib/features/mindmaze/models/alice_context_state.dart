import 'alice_persona.dart';
import 'chamber.dart';

enum AliceContextType {
  hub,
  chamber,
  entrance,
  chat,
}

class AliceContextState {
  final AliceContextType contextType;
  final AlicePersona currentPersona;
  final ChamberType? currentChamber;
  final List<String> suggestions;
  final bool hasNewInsights;
  final int unreadMessages;
  final String? lastInteraction;
  final Map<String, dynamic> locationMetadata;

  const AliceContextState({
    required this.contextType,
    required this.currentPersona,
    this.currentChamber,
    required this.suggestions,
    required this.hasNewInsights,
    required this.unreadMessages,
    this.lastInteraction,
    required this.locationMetadata,
  });

  // Factory constructors for different contexts
  factory AliceContextState.hub({
    required AlicePersona persona,
    List<String>? suggestions,
    bool hasNewInsights = false,
    int unreadMessages = 0,
  }) {
    return AliceContextState(
      contextType: AliceContextType.hub,
      currentPersona: persona,
      suggestions: suggestions ?? _getDefaultHubSuggestions(),
      hasNewInsights: hasNewInsights,
      unreadMessages: unreadMessages,
      locationMetadata: {'location': 'hub'},
    );
  }

  factory AliceContextState.chamber({
    required AlicePersona persona,
    required ChamberType chamber,
    List<String>? suggestions,
    bool hasNewInsights = false,
    int unreadMessages = 0,
    Map<String, dynamic>? metadata,
  }) {
    return AliceContextState(
      contextType: AliceContextType.chamber,
      currentPersona: persona,
      currentChamber: chamber,
      suggestions: suggestions ?? _getDefaultChamberSuggestions(chamber),
      hasNewInsights: hasNewInsights,
      unreadMessages: unreadMessages,
      locationMetadata: {
        'location': 'chamber',
        'chamber_type': chamber.toString(),
        ...?metadata,
      },
    );
  }

  factory AliceContextState.entrance({
    required AlicePersona persona,
    List<String>? suggestions,
    bool hasNewInsights = false,
  }) {
    return AliceContextState(
      contextType: AliceContextType.entrance,
      currentPersona: persona,
      suggestions: suggestions ?? _getDefaultEntranceSuggestions(),
      hasNewInsights: hasNewInsights,
      unreadMessages: 0,
      locationMetadata: {'location': 'entrance'},
    );
  }

  factory AliceContextState.chat({
    required AlicePersona persona,
    bool hasNewInsights = false,
    int unreadMessages = 0,
  }) {
    return AliceContextState(
      contextType: AliceContextType.chat,
      currentPersona: persona,
      suggestions: _getDefaultChatSuggestions(),
      hasNewInsights: hasNewInsights,
      unreadMessages: unreadMessages,
      locationMetadata: {'location': 'chat'},
    );
  }

  // Copy with method for updates
  AliceContextState copyWith({
    AliceContextType? contextType,
    AlicePersona? currentPersona,
    ChamberType? currentChamber,
    List<String>? suggestions,
    bool? hasNewInsights,
    int? unreadMessages,
    String? lastInteraction,
    Map<String, dynamic>? locationMetadata,
  }) {
    return AliceContextState(
      contextType: contextType ?? this.contextType,
      currentPersona: currentPersona ?? this.currentPersona,
      currentChamber: currentChamber ?? this.currentChamber,
      suggestions: suggestions ?? this.suggestions,
      hasNewInsights: hasNewInsights ?? this.hasNewInsights,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      locationMetadata: locationMetadata ?? this.locationMetadata,
    );
  }

  // Helper methods for getting default suggestions
  static List<String> _getDefaultHubSuggestions() {
    return [
      "What chamber should I explore today?",
      "How am I progressing on my journey?",
      "Show me my recent insights",
      "I want to understand my patterns better",
    ];
  }

  static List<String> _getDefaultChamberSuggestions(ChamberType chamber) {
    switch (chamber) {
      case ChamberType.emotion:
        return [
          "I'm feeling overwhelmed today",
          "Help me understand this emotion",
          "Why do I react this way?",
          "I want to process what happened",
        ];
      case ChamberType.pattern:
        return [
          "I keep doing the same thing",
          "This situation feels familiar",
          "Help me see the pattern here",
          "Why does this keep happening?",
        ];
      case ChamberType.fortress:
        return [
          "I feel defensive about this",
          "What am I protecting myself from?",
          "This triggers my walls",
          "Help me understand my defenses",
        ];
      case ChamberType.wisdom:
        return [
          "What's the deeper lesson here?",
          "How can I integrate this insight?",
          "What would wisdom look like?",
          "Help me see the bigger picture",
        ];
      case ChamberType.transcendent:
        return [
          "I feel connected to something larger",
          "This experience transcends my usual self",
          "Help me understand this unity",
          "What is consciousness showing me?",
        ];
    }
  }

  static List<String> _getDefaultEntranceSuggestions() {
    return [
      "I'm new here, where should I start?",
      "What is this journey about?",
      "I'm ready to explore myself",
      "Help me understand how this works",
    ];
  }

  static List<String> _getDefaultChatSuggestions() {
    return [
      "I want to talk about what's on my mind",
      "Help me process my day",
      "I'm struggling with something",
      "I had an interesting realization",
    ];
  }

  // Get contextual greeting based on current state
  String getContextualGreeting() {
    switch (contextType) {
      case AliceContextType.hub:
        return _getHubGreeting();
      case AliceContextType.chamber:
        return _getChamberGreeting();
      case AliceContextType.entrance:
        return _getEntranceGreeting();
      case AliceContextType.chat:
        return _getChatGreeting();
    }
  }

  String _getHubGreeting() {
    if (hasNewInsights) {
      return "I've been reflecting on our recent conversations and have some insights to share with you.";
    }
    return "Welcome back to your inner landscape. What would you like to explore today?";
  }

  String _getChamberGreeting() {
    final chamberName = currentChamber?.toString().split('.').last ?? 'chamber';
    return "You've entered the $chamberName chamber. I can sense the energy of this space with you.";
  }

  String _getEntranceGreeting() {
    return "Welcome to your journey of self-discovery. I'm Alice, and I'll be your companion as we explore the depths of your consciousness together.";
  }

  String _getChatGreeting() {
    return "I'm here with you. What's alive in your experience right now?";
  }
}