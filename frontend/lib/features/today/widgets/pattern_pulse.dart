import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_state.dart';

class PatternData {
  final PatternType type;
  final String name;
  final double intensity;
  final Color color;
  final String insight;
  final IconData icon;

  PatternData({
    required this.type,
    required this.name,
    required this.intensity,
    required this.color,
    required this.insight,
    required this.icon,
  });
}

class PatternPulse extends ConsumerWidget {
  const PatternPulse({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patterns = [
      PatternData(
        type: PatternType.perfectionism,
        name: 'Perfectionism',
        intensity: 0.8,
        color: AppColors.perfectionism,
        insight: 'Your perfectionism peaked during work calls this week',
        icon: Icons.star,
      ),
      PatternData(
        type: PatternType.selfCompassion,
        name: 'Self-Compassion',
        intensity: 0.4,
        color: AppColors.selfCompassion,
        insight: 'Emerging through your morning reflections',
        icon: Icons.favorite,
      ),
      PatternData(
        type: PatternType.peoplePleasing,
        name: 'People-Pleasing',
        intensity: 0.2,
        color: AppColors.peoplePleasing,
        insight: 'Dormant - great progress on boundaries!',
        icon: Icons.people,
      ),
    ];

    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: AppColors.deepPurple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Pattern Pulse',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Patterns List
          ...patterns.map((pattern) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        pattern.icon,
                        color: pattern.color,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pattern.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _getIntensityLabel(pattern.intensity),
                        style: TextStyle(
                          color: pattern.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Intensity Bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.glassBg,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pattern.intensity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: pattern.color,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: pattern.color.withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Pattern Insight
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pattern.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pattern.color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: pattern.color,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pattern.insight,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          // Pro Upgrade Hint
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warmGold.withValues(alpha: 0.1),
                  AppColors.deepPurple.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.warmGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.warmGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Deep Pattern Analysis',
                        style: TextStyle(
                          color: AppColors.warmGold,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'See how patterns connect across months and predict stress cycles',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.warmGold,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getIntensityLabel(double intensity) {
    if (intensity >= 0.7) return 'Most Active';
    if (intensity >= 0.4) return 'Emerging';
    return 'Dormant';
  }
}