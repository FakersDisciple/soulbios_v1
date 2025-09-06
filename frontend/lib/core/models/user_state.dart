enum DevelopmentStage {
  fortressBuilder,
  fortressInspector,
  gardener,
}

enum EmotionalState {
  calm,
  anxious,
  energy,
  flow,
}

enum PatternType {
  perfectionism,
  selfCompassion,
  peoplePleasing,
  anxiety,
  gratitude,
  courage,
  boundaries,
}

class UserState {
  final String userId;
  final DevelopmentStage developmentStage;
  final EmotionalState currentEmotionalState;
  final List<PatternType> activePatterns;
  final Map<PatternType, double> patternIntensities;
  final DateTime lastCheckIn;
  final int streakDays;

  UserState({
    required this.userId,
    required this.developmentStage,
    required this.currentEmotionalState,
    required this.activePatterns,
    required this.patternIntensities,
    required this.lastCheckIn,
    required this.streakDays,
  });

  UserState copyWith({
    String? userId,
    DevelopmentStage? developmentStage,
    EmotionalState? currentEmotionalState,
    List<PatternType>? activePatterns,
    Map<PatternType, double>? patternIntensities,
    DateTime? lastCheckIn,
    int? streakDays,
  }) {
    return UserState(
      userId: userId ?? this.userId,
      developmentStage: developmentStage ?? this.developmentStage,
      currentEmotionalState: currentEmotionalState ?? this.currentEmotionalState,
      activePatterns: activePatterns ?? this.activePatterns,
      patternIntensities: patternIntensities ?? this.patternIntensities,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}