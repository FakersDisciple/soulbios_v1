import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../core/theme/app_colors.dart';

class ValuesAlignmentCheck extends ConsumerWidget {
  const ValuesAlignmentCheck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Alignment Score',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.naturalGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '7/10',
                  style: TextStyle(
                    color: AppColors.naturalGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Alignment Items
          _buildAlignmentItem(
            'Freedom',
            'Morning creative time',
            true,
            AppColors.naturalGreen,
          ),
          const SizedBox(height: 12),
          _buildAlignmentItem(
            'Family',
            'Missed dinner again',
            false,
            AppColors.warmGold,
          ),
          const SizedBox(height: 12),
          _buildAlignmentItem(
            'Adventure',
            'Stuck in routine',
            false,
            AppColors.energy,
          ),
          
          const SizedBox(height: 20),
          
          // Insight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.deepPurple.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.deepPurple,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your work fortress is blocking family connection values',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignmentItem(String value, String action, bool isAligned, Color color) {
    return Row(
      children: [
        Icon(
          isAligned ? Icons.check_circle : Icons.warning,
          color: isAligned ? AppColors.naturalGreen : AppColors.warmGold,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$value: ',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            action,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}