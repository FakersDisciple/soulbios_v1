import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/enhanced_today_state.dart';
import '../widgets/enhanced_energy_orb.dart';
import '../widgets/animated_background.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/breathing_widget.dart';
import '../models/task.dart';
import 'package:intl/intl.dart';

class EnhancedTodayPage extends ConsumerStatefulWidget {
  const EnhancedTodayPage({super.key});

  @override
  ConsumerState<EnhancedTodayPage> createState() => _EnhancedTodayPageState();
}

class _EnhancedTodayPageState extends ConsumerState<EnhancedTodayPage> {
  late TextEditingController _logController;

  @override
  void initState() {
    super.initState();
    _logController = TextEditingController();
  }

  @override
  void dispose() {
    _logController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(enhancedTodayProvider);
    final notifier = ref.read(enhancedTodayProvider.notifier);

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header with breathing animation
                const SizedBox(height: 32),
                BreathingWidget(
                  duration: const Duration(seconds: 6),
                  child: Column(
                    children: [
                      const Text(
                        'Today',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How are you showing up?',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Orbs Section with enhanced spacing
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: state.orbStates.values.map((orbState) {
                    return Semantics(
                      label:
                          '${orbState.label} orb, ${orbState.activity}, ${(orbState.intensity * 100).round()}% intensity',
                      hint:
                          'Tap to view details and manage ${orbState.label.toLowerCase()} activities',
                      child: BreathingWidget(
                        duration: Duration(
                          milliseconds:
                              3000 + (orbState.intensity * 2000).round(),
                        ),
                        enabled: orbState.intensity > 0.7,
                        child: EnhancedEnergyOrb(
                          orbState: orbState,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _showOrbDetails(context, orbState);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 48),

                // Enhanced sections with glassmorphic cards
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildLogInputSection(context, ref, state, notifier),
                        const SizedBox(height: 24),
                        _buildCommitmentsSection(context, ref, state, notifier),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogInputSection(
    BuildContext context,
    WidgetRef ref,
    EnhancedTodayState state,
    EnhancedTodayStateNotifier notifier,
  ) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'What\'s happening right now?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Text input
          TextField(
            controller: _logController,
            onChanged: (value) {
              notifier.updateLogInput(value);
              setState(() {}); // Update button state
            },
            maxLines: 3,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'I\'m feeling... I notice... I\'m grateful for...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.purple,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 16),

          // Enhanced log button with haptic feedback
          SizedBox(
            width: double.infinity,
            child: GlassmorphicCard(
              backgroundColor: _logController.text.trim().isNotEmpty
                  ? Colors.purple.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.symmetric(vertical: 16),
              onTap: _logController.text.trim().isNotEmpty
                  ? () {
                      HapticFeedback.mediumImpact();
                      notifier.addLog();
                      _logController.clear();
                      setState(() {}); // Update button state
                    }
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send,
                    size: 18,
                    color: _logController.text.trim().isNotEmpty
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Log Moment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _logController.text.trim().isNotEmpty
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent logs
          if (state.logs.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Recent moments:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ...state.logs.take(3).map((log) => _buildLogItem(log)),
          ],
        ],
      ),
    );
  }

  Widget _buildLogItem(log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(12),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        blur: 5.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              log.text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('HH:mm').format(log.timestamp),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                if (log.patterns.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: log.patterns.map((pattern) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pattern,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentsSection(
    BuildContext context,
    WidgetRef ref,
    EnhancedTodayState state,
    EnhancedTodayStateNotifier notifier,
  ) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Today\'s Commitments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${notifier.completedCommitmentsCount}/${notifier.totalCommitmentsCount}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Commitments list
          ...state.commitments.map((commitment) {
            return _buildCommitmentItem(commitment, notifier);
          }),

          const SizedBox(height: 16),

          // Add commitment button
          GlassmorphicCard(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add commitment',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentItem(
      Task commitment, EnhancedTodayStateNotifier notifier) {
    final icon = notifier.getCommitmentIcon(commitment.type);
    final color = notifier.getCommitmentColor(commitment.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        backgroundColor: commitment.isCompleted
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        onTap: () {
          HapticFeedback.lightImpact();
          notifier.toggleCommitment(commitment.id);
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: commitment.isCompleted
                    ? Colors.green
                    : color.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                commitment.isCompleted ? Icons.check : icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commitment.description,
                    style: TextStyle(
                      color: commitment.isCompleted
                          ? Colors.green.shade300
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: commitment.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Text(
                    commitment.type.name,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrbDetails(BuildContext context, orbState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrbDetailSheet(
        orbState: orbState,
        notifier: ref.read(enhancedTodayProvider.notifier),
        state: ref.watch(enhancedTodayProvider),
      ),
    );
  }
}

// Simplified orb detail sheet for now
class _OrbDetailSheet extends StatelessWidget {
  final orbState;
  final EnhancedTodayStateNotifier notifier;
  final EnhancedTodayState state;

  const _OrbDetailSheet({
    required this.orbState,
    required this.notifier,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final intensityPercent = (orbState.intensity * 100).round();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2D1B69).withValues(alpha: 0.95),
            const Color(0xFF1E1B4B).withValues(alpha: 0.98),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: orbState.color.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: orbState.color.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    orbState.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orbState.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Activity: ${orbState.activity}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Intensity: $intensityPercent%',
                        style: TextStyle(
                          color: orbState.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orbState.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
