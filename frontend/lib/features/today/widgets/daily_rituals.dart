import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../core/theme/app_colors.dart';

class DailyRitual {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final Duration estimatedTime;

  DailyRitual({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isCompleted,
    required this.estimatedTime,
  });

  DailyRitual copyWith({bool? isCompleted}) {
    return DailyRitual(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: color,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedTime: estimatedTime,
    );
  }
}

class DailyRituals extends ConsumerStatefulWidget {
  const DailyRituals({super.key});

  @override
  ConsumerState<DailyRituals> createState() => _DailyRitualsState();
}

class _DailyRitualsState extends ConsumerState<DailyRituals>
    with TickerProviderStateMixin {
  late List<DailyRitual> _rituals;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _rituals = [
      DailyRitual(
        id: '1',
        title: 'Morning Reflection',
        description: 'Notice your first thought',
        icon: Icons.psychology,
        color: AppColors.softTeal,
        isCompleted: false,
        estimatedTime: const Duration(minutes: 5),
      ),
      DailyRitual(
        id: '2',
        title: 'Courage Moment',
        description: 'One small brave action',
        icon: Icons.favorite,
        color: AppColors.energy,
        isCompleted: false,
        estimatedTime: const Duration(minutes: 2),
      ),
      DailyRitual(
        id: '3',
        title: 'Evening Gratitude',
        description: 'Three appreciation moments',
        icon: Icons.auto_awesome,
        color: AppColors.warmGold,
        isCompleted: true,
        estimatedTime: const Duration(minutes: 3),
      ),
    ];
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _toggleRitual(int index) {
    HapticFeedback.lightImpact();
    
    setState(() {
      _rituals[index] = _rituals[index].copyWith(
        isCompleted: !_rituals[index].isCompleted,
      );
    });

    if (_rituals[index].isCompleted) {
      _celebrationController.forward().then((_) {
        _celebrationController.reverse();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🌱 ${_rituals[index].title} completed!'),
          backgroundColor: _rituals[index].color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  int get completedCount => _rituals.where((r) => r.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.eco,
                    color: AppColors.naturalGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Today\'s Growth Rituals',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.naturalGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount/${_rituals.length}',
                  style: TextStyle(
                    color: AppColors.naturalGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: completedCount / _rituals.length,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.naturalGreen,
                      AppColors.softTeal,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Rituals List
          ...List.generate(_rituals.length, (index) {
            final ritual = _rituals[index];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _toggleRitual(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ritual.isCompleted
                        ? ritual.color.withValues(alpha: 0.1)
                        : AppColors.glassBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ritual.isCompleted
                          ? ritual.color.withValues(alpha: 0.3)
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Completion Checkbox
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: ritual.isCompleted
                              ? ritual.color
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ritual.isCompleted
                                ? ritual.color
                                : AppColors.glassBorder,
                            width: 2,
                          ),
                        ),
                        child: ritual.isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Ritual Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ritual.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          ritual.icon,
                          color: ritual.color,
                          size: 20,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Ritual Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ritual.title,
                              style: TextStyle(
                                color: ritual.isCompleted
                                    ? ritual.color
                                    : AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: ritual.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ritual.description,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Time Estimate
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.glassBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${ritual.estimatedTime.inMinutes}m',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          // Celebration Animation
          if (completedCount == _rituals.length) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_celebrationController.value * 0.1),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.naturalGreen.withValues(alpha: 0.2),
                          AppColors.softTeal.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.naturalGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.celebration,
                          color: AppColors.naturalGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All rituals complete! Your consciousness is growing 🌱',
                            style: TextStyle(
                              color: AppColors.naturalGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}