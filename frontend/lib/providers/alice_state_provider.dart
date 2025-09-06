import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/mindmaze/models/character.dart';
import '../features/mindmaze/models/alice_persona.dart';
import '../services/character_service.dart';

class AliceState {
  final String currentMood;
  final List<String> notifications;
  final bool isInChamber;
  final String? currentChamber;
  final Character? activeCharacter;
  final Map<String, dynamic> contextData;
  final int activityLevel;
  final DateTime lastInteraction;
  final AlicePersona persona;
  final bool isAvailable;
  final String? contextualMessage;

  const AliceState({
    this.currentMood = 'neutral',
    this.notifications = const [],
    this.isInChamber = false,
    this.currentChamber,
    this.activeCharacter,
    this.contextData = const {},
    this.activityLevel = 0,
    required this.lastInteraction,
    required this.persona,
    this.isAvailable = true,
    this.contextualMessage,
  });

  bool get shouldShowNotificationBadge => notifications.isNotEmpty;
  int get unreadNotificationsCount => notifications.length;

  AliceState copyWith({
    String? currentMood,
    List<String>? notifications,
    bool? isInChamber,
    String? currentChamber,
    Character? activeCharacter,
    Map<String, dynamic>? contextData,
    int? activityLevel,
    DateTime? lastInteraction,
    AlicePersona? persona,
    bool? isAvailable,
    String? contextualMessage,
  }) {
    return AliceState(
      currentMood: currentMood ?? this.currentMood,
      notifications: notifications ?? this.notifications,
      isInChamber: isInChamber ?? this.isInChamber,
      currentChamber: currentChamber ?? this.currentChamber,
      activeCharacter: activeCharacter ?? this.activeCharacter,
      contextData: contextData ?? this.contextData,
      activityLevel: activityLevel ?? this.activityLevel,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      persona: persona ?? this.persona,
      isAvailable: isAvailable ?? this.isAvailable,
      contextualMessage: contextualMessage ?? this.contextualMessage,
    );
  }
}

class AliceStateNotifier extends StateNotifier<AliceState> {
  AliceStateNotifier() : super(AliceState(
    lastInteraction: DateTime.now(),
    persona: AlicePersona.nurturingPresence,
  ));

  void markAllNotificationsAsRead() {
    state = state.copyWith(notifications: []);
  }

  void enterChamber({String? chamber, int? previousVisits, Map<String, dynamic>? metadata}) {
    state = state.copyWith(
      isInChamber: true,
      currentChamber: chamber,
      lastInteraction: DateTime.now(),
    );
  }

  void exitChamber({String? chamber, double? completionPercentage}) {
    state = state.copyWith(
      isInChamber: false,
      currentChamber: null,
      lastInteraction: DateTime.now(),
    );
  }

  void updateChamberProgress({
    String? chamber, 
    double? progress, 
    double? completionPercentage,
    String? activityType,
    Map<String, dynamic>? activityData,
  }) {
    final updatedContext = Map<String, dynamic>.from(state.contextData);
    if (chamber != null && progress != null) {
      updatedContext['${chamber}_progress'] = progress;
    }
    if (chamber != null && completionPercentage != null) {
      updatedContext['${chamber}_completion'] = completionPercentage;
    }
    if (activityData != null) {
      updatedContext.addAll(activityData);
    }
    
    state = state.copyWith(
      contextData: updatedContext,
      lastInteraction: DateTime.now(),
    );
  }

  void completeChamber({String? chamber, Map<String, dynamic>? completionData}) {
    final updatedContext = Map<String, dynamic>.from(state.contextData);
    if (chamber != null) {
      updatedContext['${chamber}_completed'] = true;
    }
    if (completionData != null) {
      updatedContext.addAll(completionData);
    }
    
    state = state.copyWith(
      contextData: updatedContext,
      lastInteraction: DateTime.now(),
    );
  }

  void setActiveCharacter(Character character, {Map<String, dynamic>? context}) {
    state = state.copyWith(
      activeCharacter: character,
      lastInteraction: DateTime.now(),
    );
  }

  void recordActivity({String? activityType}) {
    state = state.copyWith(
      activityLevel: state.activityLevel + 1,
      lastInteraction: DateTime.now(),
    );
  }

  Future<String> getContextualHint({String? hintKey, Map<String, dynamic>? context}) async {
    // Simulate API call for contextual hint
    await Future.delayed(const Duration(milliseconds: 500));
    
    final hints = [
      "Trust your intuition in this moment.",
      "Consider what your inner wisdom is telling you.",
      "Take a deep breath and center yourself.",
      "What would your best self do here?",
      "Remember, growth happens outside your comfort zone.",
    ];
    
    return hints[DateTime.now().millisecond % hints.length];
  }

  void updateMood(String mood) {
    state = state.copyWith(
      currentMood: mood,
      lastInteraction: DateTime.now(),
    );
  }

  void addNotification(String notification) {
    final updatedNotifications = [...state.notifications, notification];
    state = state.copyWith(
      notifications: updatedNotifications,
      lastInteraction: DateTime.now(),
    );
  }
}

final aliceStateProvider = StateNotifierProvider<AliceStateNotifier, AliceState>(
  (ref) => AliceStateNotifier(),
);

// Character state provider
class CharacterState {
  final List<Character> availableCharacters;
  final Character? selectedCharacter;
  final bool isLoading;

  const CharacterState({
    this.availableCharacters = const [],
    this.selectedCharacter,
    this.isLoading = false,
  });

  CharacterState copyWith({
    List<Character>? availableCharacters,
    Character? selectedCharacter,
    bool? isLoading,
  }) {
    return CharacterState(
      availableCharacters: availableCharacters ?? this.availableCharacters,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CharacterStateNotifier extends StateNotifier<CharacterState> {
  CharacterStateNotifier() : super(const CharacterState());

  void setAvailableCharacters(List<Character> characters) {
    state = state.copyWith(availableCharacters: characters);
  }

  void selectCharacter(Character character) {
    state = state.copyWith(selectedCharacter: character);
  }
}

final characterStateProvider = StateNotifierProvider<CharacterStateNotifier, CharacterState>(
  (ref) => CharacterStateNotifier(),
);

final characterServiceProvider = Provider((ref) => CharacterService());