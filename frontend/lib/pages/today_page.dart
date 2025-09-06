import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/energy_orb.dart';
import '../widgets/task_item.dart';
import '../providers/today_state.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  void showDetailLogSheet(BuildContext context, String orbLabel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final todayNotifier = ref.read(todayPageProvider.notifier);
          final todayState = ref.watch(todayPageProvider);

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: LightModeColors.taskPanelBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    decoration: BoxDecoration(
                      color: LightModeColors.taskTextSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Activity for $orbLabel',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: LightModeColors.taskTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track your progress and reflect on your $orbLabel activities.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: LightModeColors.taskTextSecondary,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // Journal Entry TextField
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: LightModeColors.ritualTaskBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: LightModeColors.taskCheckboxBorder
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: TextField(
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText:
                                'Write about your $orbLabel activities, thoughts, and reflections...',
                            hintStyle: TextStyle(
                              color: LightModeColors.taskTextSecondary,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                          style: TextStyle(
                            color: LightModeColors.taskTextPrimary,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          onChanged: (newText) {
                            todayNotifier.updateOrbJournalEntry(
                                orbLabel, newText);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayState = ref.watch(todayPageProvider);
    final todayNotifier = ref.read(todayPageProvider.notifier);

    return Scaffold(
      backgroundColor: LightModeColors.softDarkGray,
      body: SafeArea(
        child: Column(
          children: [
            // Sky Panel (Top Section) - Energy Orbs
            Expanded(
              flex: 40,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Energy Center',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Balance your inner energies',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 20.0,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        EnergyOrb(
                          glowColor: LightModeColors.warmYellowGlow,
                          icon: Icons.lightbulb,
                          label: 'Awake',
                          isActive: todayNotifier.isOrbActive('Awake'),
                          isDimmed: todayState.activeOrbLabels.isNotEmpty &&
                              !todayNotifier.isOrbActive('Awake'),
                          onTap: () => todayNotifier.toggleOrb('Awake'),
                          onAddTap: () => showDetailLogSheet(context, 'Awake'),
                        ),
                        EnergyOrb(
                          glowColor: LightModeColors.softPinkGlow,
                          icon: Icons.favorite,
                          label: 'Self-Care',
                          isActive: todayNotifier.isOrbActive('Self-Care'),
                          isDimmed: todayState.activeOrbLabels.isNotEmpty &&
                              !todayNotifier.isOrbActive('Self-Care'),
                          onTap: () => todayNotifier.toggleOrb('Self-Care'),
                          onAddTap: () =>
                              showDetailLogSheet(context, 'Self-Care'),
                        ),
                        EnergyOrb(
                          glowColor: LightModeColors.calmBlueGlow,
                          icon: Icons.work,
                          label: 'Responsibilities',
                          isActive:
                              todayNotifier.isOrbActive('Responsibilities'),
                          isDimmed: todayState.activeOrbLabels.isNotEmpty &&
                              !todayNotifier.isOrbActive('Responsibilities'),
                          onTap: () =>
                              todayNotifier.toggleOrb('Responsibilities'),
                          onAddTap: () =>
                              showDetailLogSheet(context, 'Responsibilities'),
                        ),
                        EnergyOrb(
                          glowColor: LightModeColors.vibrantGreenGlow,
                          icon: Icons.brush,
                          label: 'Creativity',
                          isActive: todayNotifier.isOrbActive('Creativity'),
                          isDimmed: todayState.activeOrbLabels.isNotEmpty &&
                              !todayNotifier.isOrbActive('Creativity'),
                          onTap: () => todayNotifier.toggleOrb('Creativity'),
                          onAddTap: () =>
                              showDetailLogSheet(context, 'Creativity'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Ground Panel (Bottom Section) - Commitments List
            Expanded(
              flex: 60,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: LightModeColors.taskPanelBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Text(
                        'Today\'s Commitments',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: LightModeColors.taskTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: ListView.builder(
                          key: ValueKey(todayState.activeOrbLabels.join(',')),
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: 16,
                          ),
                          itemCount: todayNotifier.filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = todayNotifier.filteredTasks[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index <
                                        todayNotifier.filteredTasks.length - 1
                                    ? 12
                                    : 0,
                              ),
                              child: TaskItem(
                                task: task,
                                onToggleComplete: () =>
                                    todayNotifier.toggleTaskComplete(task.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Chat Bubble Input
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: LightModeColors.ritualTaskBackground,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: LightModeColors.taskCheckboxBorder
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Add a new commitment...',
                                  hintStyle: TextStyle(
                                    color: LightModeColors.taskTextSecondary,
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                style: TextStyle(
                                  color: LightModeColors.taskTextPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: LightModeColors.lightPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                // TODO: Implement add task functionality
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
