import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/animated_background.dart';
import '../../../widgets/breathing_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/vibe_provider.dart';
import '../widgets/alice_check_in.dart';
import '../widgets/vibe_log_orbs.dart';
import '../widgets/daily_rituals.dart';
import '../widgets/pattern_pulse.dart';
import '../widgets/moment_capture.dart';
import '../widgets/commitment_tracking.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVibeColors = ref.watch(activeVibeColorsProvider);
    
    return Scaffold(
      body: AnimatedBackground(
        activeVibeColors: activeVibeColors,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 100, // Extra space for floating nav
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Header with breathing animation
                BreathingWidget(
                  duration: const Duration(seconds: 6),
                  child: Column(
                    children: [
                      Text(
                        'Today',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Daily Conscious Start',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Vibe Log Orbs (replaces Emotional Quick Select)
                const VibeLogOrbs(),
                
                const SizedBox(height: 20),
                
                // Commitment Tracking
                const CommitmentTracking(),
                
                const SizedBox(height: 20),
                
                // Daily Rituals
                const DailyRituals(),
                
                const SizedBox(height: 20),
                
                // Alice Check-In
                const AliceCheckIn(),
                
                const SizedBox(height: 20),
                
                // Pattern Pulse
                const PatternPulse(),
                
                const SizedBox(height: 20),
                
                // Moment Capture
                const MomentCapture(),
                
                const SizedBox(height: 100), // Bottom padding for nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }
}