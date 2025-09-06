import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';

class TodayPageState {
  final List<Task> tasks;
  final List<String> activeOrbLabels;
  final Map<String, String> orbJournalEntries;
  final Map<String, double> orbGlowIntensities;

  TodayPageState({
    required this.tasks,
    required this.activeOrbLabels,
    required this.orbJournalEntries,
    required this.orbGlowIntensities,
  });

  TodayPageState copyWith({
    List<Task>? tasks,
    List<String>? activeOrbLabels,
    Map<String, String>? orbJournalEntries,
    Map<String, double>? orbGlowIntensities,
  }) {
    return TodayPageState(
      tasks: tasks ?? this.tasks,
      activeOrbLabels: activeOrbLabels ?? this.activeOrbLabels,
      orbJournalEntries: orbJournalEntries ?? this.orbJournalEntries,
      orbGlowIntensities: orbGlowIntensities ?? this.orbGlowIntensities,
    );
  }
}

class TodayPageStateNotifier extends StateNotifier<TodayPageState> {
  TodayPageStateNotifier() : super(_initialState());

  static TodayPageState _initialState() {
    return TodayPageState(
      tasks: [
        Task(
          id: '1',
          type: TaskType.pinned,
          description: 'Team Meeting at 10:00 AM',
          categories: ['Responsibilities'],
        ),
        Task(
          id: '2',
          type: TaskType.routine,
          description: 'Feed the cat',
          timeHint: 'around 8:00 AM?',
          categories: ['Responsibilities'],
        ),
        Task(
          id: '3',
          type: TaskType.ritual,
          description: 'Journal about Courage',
          categories: ['Self-Care', 'Creativity'],
        ),
        Task(
          id: '4',
          type: TaskType.routine,
          description: 'Morning meditation',
          timeHint: '10 minutes',
          categories: ['Self-Care', 'Awake'],
        ),
        Task(
          id: '5',
          type: TaskType.routine,
          description: 'Creative writing session',
          timeHint: '30 minutes',
          categories: ['Creativity'],
        ),
      ],
      activeOrbLabels: [],
      orbJournalEntries: {},
      orbGlowIntensities: {},
    );
  }

  void toggleOrb(String orbLabel) {
    final currentActiveOrbs = List<String>.from(state.activeOrbLabels);
    
    if (currentActiveOrbs.contains(orbLabel)) {
      // Remove from active orbs if already active
      currentActiveOrbs.remove(orbLabel);
    } else {
      // Add to active orbs if not active
      currentActiveOrbs.add(orbLabel);
    }
    
    state = state.copyWith(activeOrbLabels: currentActiveOrbs);
  }

  void updateOrbJournalEntry(String orbLabel, String text) {
    // Store the raw text
    final updatedJournalEntries = Map<String, String>.from(state.orbJournalEntries);
    updatedJournalEntries[orbLabel] = text;
    
    // Calculate the new glow intensity using the formula: base + (length / factor)
    // The base glow should be 0.4.
    // The factor should be 500.0.
    double newIntensity = 0.4 + (text.length / 500.0);
    
    // Cap the intensity between a min of 0.4 and a max of 1.2 to prevent it from getting too dim or overwhelmingly bright.
    final updatedGlowIntensities = Map<String, double>.from(state.orbGlowIntensities);
    updatedGlowIntensities[orbLabel] = newIntensity.clamp(0.4, 1.2);
    
    // Update state to notify listeners and rebuild the UI.
    state = state.copyWith(
      orbJournalEntries: updatedJournalEntries,
      orbGlowIntensities: updatedGlowIntensities,
    );
  }

  bool isOrbActive(String orbLabel) {
    return state.activeOrbLabels.contains(orbLabel);
  }



  void toggleTaskComplete(String taskId) {
    final updatedTasks = state.tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(isCompleted: !task.isCompleted);
      }
      return task;
    }).toList();

    state = state.copyWith(tasks: updatedTasks);
  }

  void addTask(Task task) {
    state = state.copyWith(tasks: [...state.tasks, task]);
  }

  void removeTask(String taskId) {
    final updatedTasks = state.tasks.where((task) => task.id != taskId).toList();
    state = state.copyWith(tasks: updatedTasks);
  }

  List<Task> get filteredTasks {
    if (state.activeOrbLabels.isEmpty) {
      return state.tasks;
    }
    
    return state.tasks.where((task) => 
      task.categories.any((category) => state.activeOrbLabels.contains(category))
    ).toList();
  }
}

final todayPageProvider = StateNotifierProvider<TodayPageStateNotifier, TodayPageState>(
  (ref) => TodayPageStateNotifier(),
);