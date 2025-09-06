import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/animated_background.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../widgets/breathing_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/interactive_compass.dart';
import '../widgets/values_alignment_check.dart';
import '../widgets/conflict_detector.dart';

class CompassPage extends ConsumerWidget {
  const CompassPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AnimatedBackground(
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
                
                // Header
                BreathingWidget(
                  duration: const Duration(seconds: 8),
                  child: Column(
                    children: [
                      Text(
                        'Compass',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Values Navigation System',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Error-safe widget loading
                _buildSafeWidget(
                  () => const InteractiveCompass(),
                  'Interactive Compass',
                ),
                
                const SizedBox(height: 30),
                
                _buildSafeWidget(
                  () => const ValuesAlignmentCheck(),
                  'Values Alignment Check',
                ),
                
                const SizedBox(height: 20),
                
                _buildSafeWidget(
                  () => const ConflictDetector(),
                  'Conflict Detector',
                ),
                
                const SizedBox(height: 100), // Bottom padding for nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafeWidget(Widget Function() builder, String widgetName) {
    try {
      return builder();
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              '$widgetName Loading...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This feature is initializing',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
  }
}