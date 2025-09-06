import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../screens/subscription_screen.dart';
import '../core/theme/app_colors.dart';

class PremiumGateWidget extends ConsumerWidget {
  final PremiumFeature feature;
  final Widget child;
  final String? customTitle;
  final String? customDescription;
  final VoidCallback? onUpgradePressed;
  final bool showUpgradeButton;

  const PremiumGateWidget({
    super.key,
    required this.feature,
    required this.child,
    this.customTitle,
    this.customDescription,
    this.onUpgradePressed,
    this.showUpgradeButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionService = SubscriptionService.instance;
    
    // If user has access to the feature, show the child widget
    if (subscriptionService.hasFeatureAccess(feature)) {
      return child;
    }
    
    // Otherwise, show the premium gate
    return _buildPremiumGate(context);
  }

  Widget _buildPremiumGate(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepPurple.withValues(alpha: 0.1),
            AppColors.warmGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Blurred child widget in background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  child,
                  // Blur overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Premium gate content
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warmGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.warmGold,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.diamond,
                      color: AppColors.warmGold,
                      size: 32,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    customTitle ?? _getFeatureTitle(),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    customDescription ?? _getFeatureDescription(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Upgrade button
                  if (showUpgradeButton)
                    ElevatedButton(
                      onPressed: onUpgradePressed ?? () => _showUpgradeDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warmGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.diamond, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Upgrade to Premium',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFeatureTitle() {
    switch (feature) {
      case PremiumFeature.unlimitedImageGeneration:
        return 'Unlimited Image Generation';
      case PremiumFeature.advancedChambers:
        return 'Advanced Chambers';
      case PremiumFeature.premiumArtStyles:
        return 'Premium Art Styles';
      case PremiumFeature.prioritySupport:
        return 'Priority Support';
      case PremiumFeature.exportData:
        return 'Export Your Data';
      case PremiumFeature.customCharacters:
        return 'Custom Characters';
    }
  }

  String _getFeatureDescription() {
    switch (feature) {
      case PremiumFeature.unlimitedImageGeneration:
        return 'Generate unlimited AI scenes and images. Free users are limited to 3 per day.';
      case PremiumFeature.advancedChambers:
        return 'Access Growth, Wisdom, and Transformation chambers for deeper exploration.';
      case PremiumFeature.premiumArtStyles:
        return 'Unlock exclusive art styles and filters for your generated images.';
      case PremiumFeature.prioritySupport:
        return 'Get priority customer support and faster response times.';
      case PremiumFeature.exportData:
        return 'Export your memories, insights, and generated content.';
      case PremiumFeature.customCharacters:
        return 'Create and customize your own AI characters and personas.';
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.glassBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.diamond, color: AppColors.warmGold),
              const SizedBox(width: 8),
              Text(
                'Upgrade to Premium',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock this feature and more with SoulBios Premium:',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ...SubscriptionService.instance.getPremiumFeatures().take(4).map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.naturalGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Starting at ${SubscriptionService.instance.getPremiumPrice()}',
                style: TextStyle(
                  color: AppColors.warmGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe Later',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmGold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        );
      },
    );
  }
}

/// Widget for showing usage limits with upgrade prompt
class UsageLimitWidget extends ConsumerWidget {
  final String title;
  final String description;
  final int currentUsage;
  final int maxUsage;
  final VoidCallback? onUpgradePressed;

  const UsageLimitWidget({
    super.key,
    required this.title,
    required this.description,
    required this.currentUsage,
    required this.maxUsage,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionService = SubscriptionService.instance;
    
    if (subscriptionService.isPremium) {
      return const SizedBox.shrink(); // Don't show for premium users
    }

    final progress = maxUsage > 0 ? currentUsage / maxUsage : 0.0;
    final isAtLimit = currentUsage >= maxUsage;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAtLimit ? AppColors.anxiety : AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAtLimit ? Icons.warning : Icons.info_outline,
                color: isAtLimit ? AppColors.anxiety : AppColors.warmGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.glassBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAtLimit ? AppColors.anxiety : AppColors.warmGold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$currentUsage/$maxUsage',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          if (isAtLimit) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpgradePressed ?? () => _showUpgradeDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warmGold,
                  foregroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.diamond, size: 16),
                    const SizedBox(width: 8),
                    Text('Upgrade for Unlimited Access'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.glassBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.diamond, color: AppColors.warmGold),
              const SizedBox(width: 8),
              Text(
                'Limit Reached',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Text(
            'You\'ve reached your daily limit. Upgrade to Premium for unlimited access to all features.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe Later',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmGold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        );
      },
    );
  }
}

