import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_service.dart';
import '../models/api_models.dart';
import '../features/mindmaze/models/mindmaze_insight.dart';
import '../features/mindmaze/models/chamber.dart';
import '../features/mindmaze/models/alice_context_state.dart';
import '../features/mindmaze/models/chamber_alice_integration.dart';
import '../features/mindmaze/models/alice_persona.dart';

// Alice service provider
final aliceServiceProvider = Provider<AliceService>((ref) {
  final userService = ref.watch(userServiceProvider.notifier);
  return AliceService(userService);
});

class AliceService {
  final UserService _userService;
  AliceContextState? _currentContext;
  final Map<ChamberType, ChamberAliceIntegration> _chamberIntegrations = {};

  AliceService(this._userService) {
    _initializeChamberIntegrations();
  }

  /// Initialize chamber integrations
  void _initializeChamberIntegrations() {
    for (final chamberType in ChamberType.values) {
      _chamberIntegrations[chamberType] = ChamberAliceIntegration.forChamber(chamberType);
    }
  }

  /// Get current Alice context state
  AliceContextState? get currentContext => _currentContext;

  /// Update Alice's context when user enters the hub
  Future<AliceContextState> updateContextForHub({
    List<String>? customSuggestions,
    bool hasNewInsights = false,
    int unreadMessages = 0,
  }) async {
    final persona = await _getCurrentPersona();
    
    _currentContext = AliceContextState.hub(
      persona: persona,
      suggestions: customSuggestions,
      hasNewInsights: hasNewInsights,
      unreadMessages: unreadMessages,
    );
    
    return _currentContext!;
  }

  /// Update Alice's context when user enters a specific chamber
  Future<AliceContextState> updateContextForChamber({
    required ChamberType chamber,
    List<String>? customSuggestions,
    bool hasNewInsights = false,
    int unreadMessages = 0,
    Map<String, dynamic>? metadata,
  }) async {
    final persona = await _getCurrentPersona();
    
    _currentContext = AliceContextState.chamber(
      persona: persona,
      chamber: chamber,
      suggestions: customSuggestions,
      hasNewInsights: hasNewInsights,
      unreadMessages: unreadMessages,
      metadata: metadata,
    );
    
    return _currentContext!;
  }

  /// Update Alice's context when user is in the entrance/onboarding
  Future<AliceContextState> updateContextForEntrance({
    List<String>? customSuggestions,
    bool hasNewInsights = false,
  }) async {
    final persona = await _getCurrentPersona();
    
    _currentContext = AliceContextState.entrance(
      persona: persona,
      suggestions: customSuggestions,
      hasNewInsights: hasNewInsights,
    );
    
    return _currentContext!;
  }

  /// Update Alice's context when user is in chat
  Future<AliceContextState> updateContextForChat({
    bool hasNewInsights = false,
    int unreadMessages = 0,
  }) async {
    final persona = await _getCurrentPersona();
    
    _currentContext = AliceContextState.chat(
      persona: persona,
      hasNewInsights: hasNewInsights,
      unreadMessages: unreadMessages,
    );
    
    return _currentContext!;
  }

  /// Get chamber-specific entry message
  String getChamberEntryMessage({
    required ChamberType chamber,
    AlicePersona? persona,
    int? previousVisits,
  }) {
    final integration = _chamberIntegrations[chamber];
    if (integration == null) return "Welcome to this chamber of discovery.";
    
    return integration.getEntryMessage(
      persona: persona ?? _getCurrentPersonaSync(),
      previousVisits: previousVisits,
    );
  }

  /// Get chamber-specific progress message
  String getChamberProgressMessage({
    required ChamberType chamber,
    required double completionPercentage,
    AlicePersona? persona,
  }) {
    final integration = _chamberIntegrations[chamber];
    if (integration == null) return "You're making progress in your exploration.";
    
    return integration.getProgressMessage(
      completionPercentage: completionPercentage,
      persona: persona ?? _getCurrentPersonaSync(),
    );
  }

  /// Get chamber-specific completion message
  String getChamberCompletionMessage({
    required ChamberType chamber,
    AlicePersona? persona,
  }) {
    final integration = _chamberIntegrations[chamber];
    if (integration == null) return "You've completed this chamber successfully.";
    
    return integration.getCompletionMessage(
      persona: persona ?? _getCurrentPersonaSync(),
    );
  }

  /// Get contextual hint for a specific situation
  String? getContextualHint({
    required ChamberType chamber,
    required String hintKey,
  }) {
    final integration = _chamberIntegrations[chamber];
    return integration?.getContextualHint(hintKey);
  }

  /// Update context with new insights notification
  void notifyNewInsights({int count = 1}) {
    if (_currentContext != null) {
      _currentContext = _currentContext!.copyWith(
        hasNewInsights: true,
        unreadMessages: _currentContext!.unreadMessages + count,
      );
    }
  }

  /// Mark insights as read
  void markInsightsAsRead() {
    if (_currentContext != null) {
      _currentContext = _currentContext!.copyWith(
        hasNewInsights: false,
        unreadMessages: 0,
      );
    }
  }

  /// Update context when user completes a chamber activity
  Future<void> onChamberActivityCompleted({
    required ChamberType chamber,
    required String activityType,
    Map<String, dynamic>? activityData,
  }) async {
    // Update last interaction
    if (_currentContext != null) {
      _currentContext = _currentContext!.copyWith(
        lastInteraction: 'completed_${activityType}_in_${chamber.toString()}',
        locationMetadata: {
          ..._currentContext!.locationMetadata,
          'last_activity': activityType,
          'last_activity_time': DateTime.now().toIso8601String(),
          if (activityData != null) ...activityData,
        },
      );
    }

    // Generate contextual insight based on the activity
    await _generateActivityInsight(chamber, activityType, activityData);
  }

  /// Generate insight based on chamber activity
  Future<void> _generateActivityInsight(
    ChamberType chamber,
    String activityType,
    Map<String, dynamic>? activityData,
  ) async {
    try {
      // This could trigger insight generation based on the activity
      final message = "I just completed a $activityType activity in the ${chamber.toString().split('.').last} chamber.";
      
      final response = await _userService.chatWithAlice(
        message,
        metadata: {
          'source': 'chamber_activity_insight',
          'chamber': chamber.toString(),
          'activity_type': activityType,
          ...?activityData,
        },
      );

      if (response != null) {
        // Notify that new insights are available
        notifyNewInsights();
      }
    } catch (e) {
      // Silently handle errors in insight generation
      debugPrint('Error generating activity insight: $e');
    }
  }

  /// Get current persona based on user's consciousness level
  Future<AlicePersona> _getCurrentPersona() async {
    try {
      // Try to get recent conversation to determine consciousness level
      final conversations = await _userService.getConversations(limit: 1);
      if (conversations != null && conversations.conversations.isNotEmpty) {
        final lastConversation = conversations.conversations.first;
        if (lastConversation.consciousnessLevel != null) {
          // Parse consciousness level and convert to persona
          final level = double.tryParse(lastConversation.consciousnessLevel!) ?? 0.0;
          final personaType = AlicePersonaExtension.fromConsciousnessLevel(level);
          return _getPersonaFromType(personaType);
        }
      }

      // Fallback: analyze patterns to determine consciousness level
      final analysis = await _userService.analyzePatterns(
        "Current consciousness assessment",
        metadata: {'source': 'persona_determination'},
      );
      
      if (analysis != null) {
        final level = analysis.consciousnessIndicators['overall_consciousness'] ?? 0.0;
        final personaType = AlicePersonaExtension.fromConsciousnessLevel(level);
        return _getPersonaFromType(personaType);
      }
    } catch (e) {
      debugPrint('Error determining persona: $e');
    }

    // Default to nurturing presence
    return AlicePersona.nurturingPresence;
  }

  AlicePersona _getPersonaFromType(AlicePersonaType type) {
    switch (type) {
      case AlicePersonaType.nurturingPresence:
        return AlicePersona.nurturingPresence;
      case AlicePersonaType.wiseDetective:
        return AlicePersona.wiseDetective;
      case AlicePersonaType.transcendentGuide:
        return AlicePersona.transcendentGuide;
      case AlicePersonaType.unifiedConsciousness:
        return AlicePersona.unifiedConsciousness;
    }
  }

  /// Synchronous version of getting current persona (uses cached value or default)
  AlicePersona _getCurrentPersonaSync() {
    return _currentContext?.currentPersona ?? AlicePersona.nurturingPresence;
  }

  // Generate insights from user patterns
  Future<List<MindMazeInsight>> generateInsights({int limit = 5}) async {
    try {
      // Get recent conversations to analyze patterns
      final conversations = await _userService.getConversations(limit: 20);
      if (conversations == null || conversations.conversations.isEmpty) {
        return _getDefaultInsights();
      }

      // Analyze patterns from recent conversations
      final insights = <MindMazeInsight>[];
      
      for (final conversation in conversations.conversations.take(3)) {
        if (conversation.role == 'user') {
          final analysis = await _userService.analyzePatterns(
            conversation.message,
            metadata: {'source': 'insight_generation'},
          );
          
          if (analysis != null) {
            final insight = _createInsightFromAnalysis(conversation, analysis);
            if (insight != null) {
              insights.add(insight);
            }
          }
        }
      }

      // Fill with default insights if we don't have enough
      while (insights.length < 3) {
        insights.addAll(_getDefaultInsights().take(3 - insights.length));
      }

      return insights.take(limit).toList();
    } catch (e) {
      // Fallback to default insights
      return _getDefaultInsights();
    }
  }

  // Create insight from pattern analysis
  MindMazeInsight? _createInsightFromAnalysis(
    ConversationItem conversation, 
    PatternAnalysisResponse analysis
  ) {
    final consciousnessLevel = analysis.consciousnessIndicators['overall_consciousness'] ?? 0.0;
    
    // Generate insight text based on consciousness level
    String insightText;
    ChamberType chamber;
    String pattern;

    if (consciousnessLevel < 0.3) {
      insightText = "Your awareness is growing - notice how emotions guide your responses";
      chamber = ChamberType.emotion;
      pattern = "emotional_awareness_emerging";
    } else if (consciousnessLevel < 0.6) {
      insightText = "Patterns are becoming visible - you're recognizing recurring themes in your life";
      chamber = ChamberType.pattern;
      pattern = "pattern_recognition_active";
    } else if (consciousnessLevel < 0.8) {
      insightText = "Your defenses are softening - you're becoming more open to growth";
      chamber = ChamberType.fortress;
      pattern = "defensive_patterns_dissolving";
    } else {
      insightText = "Wisdom is integrating - you're seeing the bigger picture of your journey";
      chamber = ChamberType.wisdom;
      pattern = "wisdom_integration_active";
    }

    return MindMazeInsight(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: insightText,
      chamber: chamber,
      discoveredAt: DateTime.now(),
      pattern: pattern,
    );
  }

  // Default insights for fallback
  List<MindMazeInsight> _getDefaultInsights() {
    return [
      MindMazeInsight(
        id: "default_1",
        text: "Your perfectionism protects against criticism but costs you creativity",
        chamber: ChamberType.emotion,
        discoveredAt: DateTime.now().subtract(const Duration(hours: 2)),
        pattern: "perfectionism_fortress",
      ),
      MindMazeInsight(
        id: "default_2",
        text: "Fear often masks excitement about new possibilities",
        chamber: ChamberType.pattern,
        discoveredAt: DateTime.now().subtract(const Duration(days: 1)),
        pattern: "fear_excitement_correlation",
      ),
      MindMazeInsight(
        id: "default_3",
        text: "Your need for control stems from childhood uncertainty",
        chamber: ChamberType.fortress,
        discoveredAt: DateTime.now().subtract(const Duration(days: 2)),
        pattern: "control_childhood_link",
      ),
    ];
  }

  // Get chamber progress from API
  Future<List<Chamber>> getChamberProgress() async {
    try {
      await _userService.refreshStatus();
      // Get user status through the service method
      final status = _userService.getUserStatus();
      if (status == null) {
        return _getDefaultChambers();
      }

      // Calculate progress based on user conversations and patterns
      final totalConversations = status.totalConversations;
      final totalPatterns = status.totalPatterns;
      
      // Simple progress calculation (in production, this would be more sophisticated)
      final emotionProgress = (totalConversations * 0.4).clamp(0, 21).toInt();
      final patternProgress = (totalPatterns * 0.6).clamp(0, 21).toInt();
      final fortressProgress = (emotionProgress > 15 ? (totalConversations * 0.2).clamp(0, 21).toInt() : 0);
      final wisdomProgress = (patternProgress > 15 ? (totalPatterns * 0.3).clamp(0, 21).toInt() : 0);
      final transcendentProgress = (wisdomProgress > 15 ? (totalConversations * 0.1).clamp(0, 21).toInt() : 0);

      return [
        Chamber(
          type: ChamberType.emotion,
          name: "Emotion Chamber",
          description: "Crystal cavern of feelings and emotional awareness",
          themeColor: const Color(0xFF3B82F6), // Blue
          icon: Icons.favorite,
          completedQuestions: emotionProgress,
          isUnlocked: true,
        ),
        Chamber(
          type: ChamberType.pattern,
          name: "Pattern Library",
          description: "Ancient library of behavioral patterns",
          themeColor: const Color(0xFF8B5CF6), // Purple
          icon: Icons.library_books,
          completedQuestions: patternProgress,
          isUnlocked: emotionProgress >= 10,
        ),
        Chamber(
          type: ChamberType.fortress,
          name: "Fortress Tower",
          description: "Shadow work and defensive patterns",
          themeColor: const Color(0xFF6B7280), // Grey
          icon: Icons.security,
          completedQuestions: fortressProgress,
          isUnlocked: patternProgress >= 10,
        ),
        Chamber(
          type: ChamberType.wisdom,
          name: "Wisdom Sanctum",
          description: "Synthesis of insights into practical wisdom",
          themeColor: const Color(0xFFF97316), // Orange
          icon: Icons.lightbulb,
          completedQuestions: wisdomProgress,
          isUnlocked: fortressProgress >= 10,
        ),
        Chamber(
          type: ChamberType.transcendent,
          name: "Transcendent Peak",
          description: "Unity consciousness and integration",
          themeColor: const Color(0xFFFFFFFF), // White
          icon: Icons.star,
          completedQuestions: transcendentProgress,
          isUnlocked: wisdomProgress >= 10,
        ),
      ];
    } catch (e) {
      return _getDefaultChambers();
    }
  }

  // Default chambers for fallback
  List<Chamber> _getDefaultChambers() {
    return [
      const Chamber(
        type: ChamberType.emotion,
        name: "Emotion Chamber",
        description: "Crystal cavern of feelings and emotional awareness",
        themeColor: Color(0xFF3B82F6),
        icon: Icons.favorite,
        completedQuestions: 0,
        isUnlocked: true,
      ),
      const Chamber(
        type: ChamberType.pattern,
        name: "Pattern Library",
        description: "Ancient library of behavioral patterns",
        themeColor: Color(0xFF8B5CF6),
        icon: Icons.library_books,
        completedQuestions: 0,
        isUnlocked: false,
      ),
      const Chamber(
        type: ChamberType.fortress,
        name: "Fortress Tower",
        description: "Shadow work and defensive patterns",
        themeColor: Color(0xFF6B7280),
        icon: Icons.security,
        completedQuestions: 0,
        isUnlocked: false,
      ),
      const Chamber(
        type: ChamberType.wisdom,
        name: "Wisdom Sanctum",
        description: "Synthesis of insights into practical wisdom",
        themeColor: Color(0xFFF97316),
        icon: Icons.lightbulb,
        completedQuestions: 0,
        isUnlocked: false,
      ),
      const Chamber(
        type: ChamberType.transcendent,
        name: "Transcendent Peak",
        description: "Unity consciousness and integration",
        themeColor: Color(0xFFFFFFFF),
        icon: Icons.star,
        completedQuestions: 0,
        isUnlocked: false,
      ),
    ];
  }

  // Process chamber question with Alice AI
  Future<ChatResponse?> processChamberQuestion({
    required ChamberType chamber,
    required String question,
    required String userAnswer,
  }) async {
    final metadata = {
      'source': 'chamber_question',
      'chamber': chamber.toString(),
      'question': question,
      'user_answer': userAnswer,
    };

    final message = "In the ${chamber.toString().split('.').last} chamber, "
        "I was asked: '$question' and I answered: '$userAnswer'. "
        "What insight can you share about this?";

    return await _userService.chatWithAlice(message, metadata: metadata);
  }
}