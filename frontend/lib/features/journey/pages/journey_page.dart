import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/animated_background.dart';

import '../../../widgets/breathing_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/api_models.dart';
import '../../../services/user_service.dart';
import '../widgets/alice_chat_widget.dart';
import '../widgets/enhanced_memory_capture.dart';
import '../widgets/story_web_visualizer.dart';
import '../widgets/adaptive_memory_timeline.dart';

class JourneyPage extends ConsumerWidget {
  const JourneyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final userState = ref.watch(userServiceProvider);
      final userStage = userState.status?.userId ?? 'explorer'; // Default stage
      final isPro = false; // TODO: Implement pro status check
      
      return Scaffold(
        body: AnimatedBackground(
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: BreathingWidget(
                      duration: const Duration(seconds: 7),
                      child: Column(
                        children: [
                          Text(
                            'Journey',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Living Autobiography',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Error-safe widgets
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildSafeWidget(
                          () => const AliceChatWidget(),
                          'Alice Chat',
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildSafeWidget(
                          () => EnhancedMemoryCapture(
                            userStage: userStage,
                            onMemorySaved: () {
                              ref.invalidate(userServiceProvider);
                            },
                          ),
                          'Memory Capture',
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildSafeWidget(
                          () => StoryWebVisualizer(
                            nodes: _generateSamplePatternNodes(),
                            isPro: isPro,
                            onUpgradeRequested: () {
                              _showProUpgradeDialog(context);
                            },
                          ),
                          'Story Web Visualizer',
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: _buildSafeWidget(
                      () => AdaptiveMemoryTimeline(
                        userStage: userStage,
                      ),
                      'Memory Timeline',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return _buildErrorPage(context);
    }
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
              Icons.auto_stories,
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

  Widget _buildErrorPage(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_stories,
                  color: AppColors.textSecondary,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  'Journey',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Living Autobiography is loading...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PatternNode> _generateSamplePatternNodes() {
    // Generate sample pattern nodes for demonstration
    // In production, these would come from the backend analysis
    return [
      PatternNode(
        id: 'node_1',
        label: 'Overwhelming Responsibility',
        color: AppColors.anxiety,
        connectionIds: ['node_2', 'node_3'],
        pattern: 'caretaking_burden',
        discoveredAt: DateTime.now().subtract(const Duration(days: 5)),
        isRevealed: true,
      ),
      PatternNode(
        id: 'node_2',
        label: 'Childhood Caretaking',
        color: AppColors.deepPurple,
        connectionIds: ['node_1', 'node_4'],
        pattern: 'early_responsibility',
        discoveredAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      PatternNode(
        id: 'node_3',
        label: 'Work Perfectionism',
        color: AppColors.warmGold,
        connectionIds: ['node_1'],
        pattern: 'performance_anxiety',
        discoveredAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      PatternNode(
        id: 'node_4',
        label: 'Fear of Letting Others Down',
        color: AppColors.calmBlue,
        connectionIds: ['node_2'],
        pattern: 'people_pleasing',
        discoveredAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  void _showProUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glassBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppColors.warmGold,
            ),
            const SizedBox(width: 12),
            Text(
              'Upgrade to Pro',
              style: TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Unlock interactive story webs, advanced pattern analysis, and deeper AI insights to accelerate your consciousness journey.',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement pro upgrade flow
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Upgrade Now',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }


}