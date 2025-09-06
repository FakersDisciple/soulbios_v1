import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/log_entry.dart';
import '../models/orb_state.dart';

class EnhancedTodayState {
  final List<Task> commitments;
  final List<LogEntry> logs;
  final Map<String, OrbState> orbStates;
  final String currentLogInput;

  EnhancedTodayState({
    required this.commitments,
    required this.logs,
    required this.orbStates,
    required this.currentLogInput,
  });

  EnhancedTodayState copyWith({
    List<Task>? commitments,
    List<LogEntry>? logs,
    Map<String, OrbState>? orbStates,
    String? currentLogInput,
  }) {
    return EnhancedTodayState(
      commitments: commitments ?? this.commitments,
      logs: logs ?? this.logs,
      orbStates: orbStates ?? this.orbStates,
      currentLogInput: currentLogInput ?? this.currentLogInput,
    );
  }
}

class EnhancedTodayStateNotifier extends StateNotifier<EnhancedTodayState> {
  EnhancedTodayStateNotifier() : super(_initialState());

  static EnhancedTodayState _initialState() {
    return EnhancedTodayState(
      commitments: [
        Task(
          id: '1',
          type: TaskType.ritual,
          description: 'Morning meditation',
          categories: ['Mind'],
          isCompleted: true,
        ),
        Task(
          id: '2',
          type: TaskType.reflection,
          description: 'Journal about yesterday',
          categories: ['Heart'],
          isCompleted: false,
        ),
        Task(
          id: '3',
          type: TaskType.courage,
          description: 'Practice saying no to one request',
          categories: ['Soul'],
          isCompleted: false,
        ),
        Task(
          id: '4',
          type: TaskType.connection,
          description: 'Alice check-in before bed',
          categories: ['Heart'],
          isCompleted: false,
        ),
      ],
      logs: [],
      orbStates: {
        'Mind': OrbState(
          label: 'Mind',
          intensity: 0.6,
          color: const Color(0xFF8B5CF6),
          activity: 'Reflective',
          icon: Icons.psychology,
        ),
        'Heart': OrbState(
          label: 'Heart',
          intensity: 0.8,
          color: const Color(0xFFEC4899),
          activity: 'Open',
          icon: Icons.favorite,
        ),
        'Soul': OrbState(
          label: 'Soul',
          intensity: 0.4,
          color: const Color(0xFF06B6D4),
          activity: 'Seeking',
          icon: Icons.auto_awesome,
        ),
      },
      currentLogInput: '',
    );
  }

  void updateLogInput(String text) {
    state = state.copyWith(currentLogInput: text);
  }

  void updateOrbIntensity(String orbLabel, double intensity) {
    final updatedOrbStates = Map<String, OrbState>.from(state.orbStates);
    final currentOrb = updatedOrbStates[orbLabel];
    if (currentOrb != null) {
      updatedOrbStates[orbLabel] = currentOrb.copyWith(
        intensity: intensity.clamp(0.2, 1.0),
      );
      state = state.copyWith(orbStates: updatedOrbStates);
    }
  }

  void addLog() {
    if (state.currentLogInput.trim().isEmpty) return;

    final newLog = LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: state.currentLogInput,
      timestamp: DateTime.now(),
      patterns: _detectPatterns(state.currentLogInput),
    );

    final updatedLogs = [newLog, ...state.logs];
    _updateOrbsFromActivity(state.currentLogInput);
    
    state = state.copyWith(
      logs: updatedLogs,
      currentLogInput: '',
    );
  }

  List<String> _detectPatterns(String text) {
    final patterns = <String>[];
    final lowerText = text.toLowerCase();

    if (lowerText.contains('perfect') || lowerText.contains('mistake')) {
      patterns.add('perfectionism');
    }
    if (lowerText.contains('please') || lowerText.contains('others first')) {
      patterns.add('people-pleasing');
    }
    if (lowerText.contains('worried') || lowerText.contains('anxious')) {
      patterns.add('anxiety');
    }
    if (lowerText.contains('grateful') || lowerText.contains('thankful')) {
      patterns.add('gratitude');
    }
    if (lowerText.contains('sad') || lowerText.contains('down')) {
      patterns.add('sadness');
    }
    if (lowerText.contains('happy') || lowerText.contains('joy')) {
      patterns.add('joy');
    }
    if (lowerText.contains('angry') || lowerText.contains('frustrated')) {
      patterns.add('anger');
    }
    if (lowerText.contains('love') || lowerText.contains('care')) {
      patterns.add('love');
    }

    return patterns;
  }

  void _updateOrbsFromActivity(String text) {
    final lowerText = text.toLowerCase();
    final updatedOrbStates = Map<String, OrbState>.from(state.orbStates);

    // Mind orb - thinking, planning, analyzing
    if (lowerText.contains('think') || 
        lowerText.contains('plan') || 
        lowerText.contains('analyze') ||
        lowerText.contains('understand') ||
        lowerText.contains('learn')) {
      final currentMind = updatedOrbStates['Mind']!;
      updatedOrbStates['Mind'] = currentMind.copyWith(
        intensity: (currentMind.intensity + 0.1).clamp(0.4, 1.0),
        activity: 'Active',
      );
    }

    // Heart orb - emotions, feelings, relationships
    if (lowerText.contains('feel') || 
        lowerText.contains('love') || 
        lowerText.contains('sad') || 
        lowerText.contains('happy') ||
        lowerText.contains('emotion') ||
        lowerText.contains('heart')) {
      final currentHeart = updatedOrbStates['Heart']!;
      updatedOrbStates['Heart'] = currentHeart.copyWith(
        intensity: (currentHeart.intensity + 0.1).clamp(0.4, 1.0),
        activity: 'Engaged',
      );
    }

    // Soul orb - meaning, purpose, growth
    if (lowerText.contains('purpose') || 
        lowerText.contains('meaning') || 
        lowerText.contains('grow') ||
        lowerText.contains('spiritual') ||
        lowerText.contains('soul') ||
        lowerText.contains('deeper')) {
      final currentSoul = updatedOrbStates['Soul']!;
      updatedOrbStates['Soul'] = currentSoul.copyWith(
        intensity: (currentSoul.intensity + 0.1).clamp(0.4, 1.0),
        activity: 'Awakening',
      );
    }

    state = state.copyWith(orbStates: updatedOrbStates);
  }

  void toggleCommitment(String id) {
    final updatedCommitments = state.commitments.map((commitment) {
      if (commitment.id == id) {
        return commitment.copyWith(isCompleted: !commitment.isCompleted);
      }
      return commitment;
    }).toList();

    state = state.copyWith(commitments: updatedCommitments);
  }

  void addCommitment(String text, TaskType type) {
    if (text.trim().isEmpty) return;

    final newCommitment = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      description: text,
      categories: _getCategoriesForType(type),
      isCompleted: false,
    );

    final updatedCommitments = [...state.commitments, newCommitment];
    state = state.copyWith(commitments: updatedCommitments);
  }

  List<String> _getCategoriesForType(TaskType type) {
    switch (type) {
      case TaskType.ritual:
        return ['Soul'];
      case TaskType.reflection:
        return ['Mind'];
      case TaskType.courage:
        return ['Soul'];
      case TaskType.connection:
        return ['Heart'];
      default:
        return ['Mind'];
    }
  }

  IconData getCommitmentIcon(TaskType type) {
    switch (type) {
      case TaskType.ritual:
        return Icons.nature;
      case TaskType.reflection:
        return Icons.psychology;
      case TaskType.courage:
        return Icons.favorite;
      case TaskType.connection:
        return Icons.auto_awesome;
      default:
        return Icons.circle_outlined;
    }
  }

  Color getCommitmentColor(TaskType type) {
    switch (type) {
      case TaskType.ritual:
        return const Color(0xFF10B981);
      case TaskType.reflection:
        return const Color(0xFF8B5CF6);
      case TaskType.courage:
        return const Color(0xFFEC4899);
      case TaskType.connection:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  int get completedCommitmentsCount {
    return state.commitments.where((c) => c.isCompleted).length;
  }

  int get totalCommitmentsCount {
    return state.commitments.length;
  }
}

final enhancedTodayProvider = StateNotifierProvider<EnhancedTodayStateNotifier, EnhancedTodayState>(
  (ref) => EnhancedTodayStateNotifier(),
);