import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/animated_background.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../widgets/breathing_widget.dart';
import '../../../core/theme/app_colors.dart';

class HorizonPage extends ConsumerWidget {
  const HorizonPage({super.key});

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
                  duration: const Duration(seconds: 9),
                  child: Column(
                    children: [
                      Text(
                        'Horizon',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Future Self Architecture',
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
                
                // Future Self Visualization
                GlassmorphicCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.landscape,
                            color: AppColors.softTeal,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Your 1-Year-Future Self',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildFutureSection('I see myself...', 'Leading a creative team, working from a home studio'),
                      const SizedBox(height: 16),
                      _buildFutureSection('My typical day includes...', 'Morning meditation, creative work, evening family time'),
                      const SizedBox(height: 16),
                      _buildFutureSection('I feel proud that I...', 'Built something meaningful that helps others grow'),
                      const SizedBox(height: 16),
                      _buildFutureSection('People know me as someone who...', 'Brings calm wisdom to challenging situations'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Goal Bridge
                GlassmorphicCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timeline,
                            color: AppColors.naturalGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Bridge to Your Future',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Text(
                        'Big Dream: Write a novel',
                        style: TextStyle(
                          color: AppColors.warmGold,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildGoalStep('This Month', 'Join writing group', true),
                      _buildGoalStep('This Week', 'Write 3 pages', false),
                      _buildGoalStep('Today', '30-minute morning write', false),
                      
                      const SizedBox(height: 20),
                      
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress: 4/10',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.glassBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.4,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.naturalGreen,
                                      AppColors.softTeal,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Pro Feature Teaser
                GlassmorphicCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.warmGold,
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unlock Multiple Timeline Modeling',
                        style: TextStyle(
                          color: AppColors.warmGold,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'See probability paths for different life directions and get AI guidance on which timeline aligns with your authentic self',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.deepPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.deepPurple.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildTimelinePreview('Timeline A: Creative Leader', '78%', AppColors.naturalGreen),
                            const SizedBox(height: 8),
                            _buildTimelinePreview('Timeline B: Entrepreneur', '23%', AppColors.warmGold),
                            const SizedBox(height: 8),
                            _buildTimelinePreview('Timeline C: Teacher/Mentor', '91%', AppColors.softTeal),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFutureSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.softTeal,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.glassBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalStep(String timeframe, String action, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.naturalGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isCompleted ? AppColors.naturalGreen : AppColors.glassBorder,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeframe,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  action,
                  style: TextStyle(
                    color: isCompleted ? AppColors.naturalGreen : AppColors.textSecondary,
                    fontSize: 14,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePreview(String title, String probability, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          probability,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}