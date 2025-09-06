import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../core/theme/app_colors.dart';

enum CommitmentType {
  ritual,
  reflection,
  courage,
  connection,
}

class Commitment {
  final String id;
  final String title;
  final CommitmentType type;
  final bool isCompleted;
  final DateTime createdAt;

  Commitment({
    required this.id,
    required this.title,
    required this.type,
    required this.isCompleted,
    required this.createdAt,
  });

  Commitment copyWith({bool? isCompleted}) {
    return Commitment(
      id: id,
      title: title,
      type: type,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}

class CommitmentTracking extends ConsumerStatefulWidget {
  const CommitmentTracking({super.key});

  @override
  ConsumerState<CommitmentTracking> createState() => _CommitmentTrackingState();
}

class _CommitmentTrackingState extends ConsumerState<CommitmentTracking> {
  final TextEditingController _controller = TextEditingController();
  CommitmentType _selectedType = CommitmentType.ritual;
  
  List<Commitment> _commitments = [
    Commitment(
      id: '1',
      title: 'Call mom to check in',
      type: CommitmentType.connection,
      isCompleted: false,
      createdAt: DateTime.now(),
    ),
    Commitment(
      id: '2',
      title: 'Journal about yesterday\'s meeting',
      type: CommitmentType.reflection,
      isCompleted: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  final Map<CommitmentType, Map<String, dynamic>> _typeData = {
    CommitmentType.ritual: {
      'color': AppColors.naturalGreen,
      'icon': Icons.eco,
      'label': 'Ritual',
    },
    CommitmentType.reflection: {
      'color': AppColors.deepPurple,
      'icon': Icons.psychology,
      'label': 'Reflection',
    },
    CommitmentType.courage: {
      'color': AppColors.energy,
      'icon': Icons.favorite,
      'label': 'Courage',
    },
    CommitmentType.connection: {
      'color': AppColors.warmGold,
      'icon': Icons.people,
      'label': 'Connection',
    },
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCommitment(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _commitments[index] = _commitments[index].copyWith(
        isCompleted: !_commitments[index].isCompleted,
      );
    });
    
    if (_commitments[index].isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Commitment completed!'),
          backgroundColor: _typeData[_commitments[index].type]!['color'],
        ),
      );
    }
  }

  void _addCommitment() {
    if (_controller.text.trim().isEmpty) return;
    if (_commitments.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Free tier: 3 commitments max. Upgrade for unlimited!'),
          backgroundColor: AppColors.warmGold,
        ),
      );
      return;
    }
    
    HapticFeedback.mediumImpact();
    setState(() {
      _commitments.add(
        Commitment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _controller.text.trim(),
          type: _selectedType,
          isCompleted: false,
          createdAt: DateTime.now(),
        ),
      );
    });
    
    _controller.clear();
  }

  int get completedCount => _commitments.where((c) => c.isCompleted).length;

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
                    Icons.track_changes,
                    color: AppColors.calmBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Today\'s Commitments',
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
                  color: AppColors.calmBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount/${_commitments.length}',
                  style: TextStyle(
                    color: AppColors.calmBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Commitments List
          if (_commitments.isNotEmpty) ...[
            ...List.generate(_commitments.length, (index) {
              final commitment = _commitments[index];
              final typeData = _typeData[commitment.type]!;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _toggleCommitment(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: commitment.isCompleted
                          ? typeData['color'].withValues(alpha: 0.1)
                          : AppColors.glassBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: commitment.isCompleted
                            ? typeData['color'].withValues(alpha: 0.3)
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
                            color: commitment.isCompleted
                                ? typeData['color']
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: commitment.isCompleted
                                  ? typeData['color']
                                  : AppColors.glassBorder,
                              width: 2,
                            ),
                          ),
                          child: commitment.isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Type Icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: typeData['color'].withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            typeData['icon'],
                            color: typeData['color'],
                            size: 16,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Commitment Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                commitment.title,
                                style: TextStyle(
                                  color: commitment.isCompleted
                                      ? typeData['color']
                                      : AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  decoration: commitment.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                typeData['label'],
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 20),
          ],
          
          // Add New Commitment
          if (_commitments.length < 3) ...[
            // Type Selector
            Row(
              children: _typeData.entries.map((entry) {
                final isSelected = _selectedType == entry.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedType = entry.key;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? entry.value['color'].withValues(alpha: 0.2)
                            : AppColors.glassBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? entry.value['color'].withValues(alpha: 0.5)
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            entry.value['icon'],
                            color: isSelected
                                ? entry.value['color']
                                : AppColors.textTertiary,
                            size: 16,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.value['label'],
                            style: TextStyle(
                              color: isSelected
                                  ? entry.value['color']
                                  : AppColors.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Input Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a new commitment...',
                      hintStyle: TextStyle(
                        color: AppColors.textTertiary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.glassBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.glassBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _typeData[_selectedType]!['color'],
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.glassBg,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onSubmitted: (_) => _addCommitment(),
                  ),
                ),
                const SizedBox(width: 12),
                GlassmorphicCard(
                  backgroundColor: _controller.text.trim().isNotEmpty
                      ? _typeData[_selectedType]!['color'].withValues(alpha: 0.2)
                      : AppColors.glassBg,
                  padding: const EdgeInsets.all(12),
                  onTap: _controller.text.trim().isNotEmpty ? _addCommitment : null,
                  child: Icon(
                    Icons.add,
                    color: _controller.text.trim().isNotEmpty
                        ? _typeData[_selectedType]!['color']
                        : AppColors.textTertiary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Free Tier Limit Message
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
                    Icons.star,
                    color: AppColors.warmGold,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade for Unlimited Commitments',
                          style: TextStyle(
                            color: AppColors.warmGold,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Free tier: 3 commitments max',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
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