import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_state.dart';

class EmotionalQuickSelect extends ConsumerStatefulWidget {
  const EmotionalQuickSelect({super.key});

  @override
  ConsumerState<EmotionalQuickSelect> createState() => _EmotionalQuickSelectState();
}

class _EmotionalQuickSelectState extends ConsumerState<EmotionalQuickSelect> {
  EmotionalState? _selectedState;

  final Map<EmotionalState, Map<String, dynamic>> _emotionalStates = {
    EmotionalState.calm: {
      'emoji': '😌',
      'label': 'Calm',
      'color': AppColors.calm,
      'description': 'Peaceful and centered',
    },
    EmotionalState.anxious: {
      'emoji': '😟',
      'label': 'Anxious',
      'color': AppColors.anxious,
      'description': 'Worried or unsettled',
    },
    EmotionalState.energy: {
      'emoji': '🔥',
      'label': 'Energy',
      'color': AppColors.energy,
      'description': 'Motivated and driven',
    },
    EmotionalState.flow: {
      'emoji': '🌊',
      'label': 'Flow',
      'color': AppColors.flow,
      'description': 'In the zone',
    },
  };

  void _selectEmotionalState(EmotionalState state) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedState = state;
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Feeling ${_emotionalStates[state]!['label']} - Alice is learning about your patterns',
        ),
        backgroundColor: _emotionalStates[state]!['color'],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmotionalCard(EmotionalState state) {
    final stateData = _emotionalStates[state]!;
    final isSelected = _selectedState == state;
    
    return GestureDetector(
      onTap: () => _selectEmotionalState(state),
      child: AspectRatio(
        aspectRatio: 1.0, // Perfect square
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? stateData['color'].withValues(alpha: 0.2)
              : AppColors.glassBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? stateData['color'].withValues(alpha: 0.5)
                : AppColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: stateData['color'].withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stateData['emoji'],
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              stateData['label'],
              style: TextStyle(
                color: isSelected
                    ? stateData['color']
                    : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling right now?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Emotional State Grid - Fixed Layout
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildEmotionalCard(EmotionalState.calm),
                    const SizedBox(height: 12),
                    _buildEmotionalCard(EmotionalState.energy),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _buildEmotionalCard(EmotionalState.anxious),
                    const SizedBox(height: 12),
                    _buildEmotionalCard(EmotionalState.flow),
                  ],
                ),
              ),
            ],
          ),
          
          if (_selectedState != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _emotionalStates[_selectedState]!['color']
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _emotionalStates[_selectedState]!['color']
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insights,
                    color: _emotionalStates[_selectedState]!['color'],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alice is tracking this pattern to help you understand your emotional rhythms',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}