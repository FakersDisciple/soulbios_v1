import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../core/theme/app_colors.dart';
import '../widgets/glassmorphic_card.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isPurchasing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = SubscriptionService.instance;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E).withValues(alpha: 0.8),
              const Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // Current status
                          if (subscriptionService.isPremium)
                            _buildPremiumStatus()
                          else
                            _buildFreeStatus(),
                          
                          const SizedBox(height: 24),
                          
                          // Premium features
                          _buildPremiumFeatures(),
                          
                          const SizedBox(height: 24),
                          
                          // Pricing
                          if (!subscriptionService.isPremium) _buildPricing(),
                          
                          const SizedBox(height: 24),
                          
                          // Usage stats
                          _buildUsageStats(),
                          
                          const SizedBox(height: 24),
                          
                          // Action buttons
                          _buildActionButtons(),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.diamond,
            color: AppColors.warmGold,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'SoulBios Premium',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatus() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.naturalGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: AppColors.naturalGreen,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Premium Active',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have unlimited access to all SoulBios features',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFreeStatus() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warmGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.diamond,
              color: AppColors.warmGold,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Free Tier',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to unlock unlimited features and premium content',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures() {
    final features = SubscriptionService.instance.getPremiumFeatures();
    
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Premium Features',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.naturalGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
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
              )),
        ],
      ),
    );
  }

  Widget _buildPricing() {
    final price = SubscriptionService.instance.getPremiumPrice();
    
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Simple Pricing',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.warmGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.warmGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  price ?? '\$4.99',
                  style: TextStyle(
                    color: AppColors.warmGold,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'per month',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cancel anytime • No commitment',
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
    );
  }

  Widget _buildUsageStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: SubscriptionService.instance.getUsageStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final stats = snapshot.data!;
        final todayGens = stats['todayImageGenerations'] ?? 0;
        final remainingGens = stats['remainingFreeGenerations'] ?? 0;
        
        return GlassmorphicCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Usage Today',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Images Generated',
                      '$todayGens',
                      Icons.image,
                      AppColors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      'Remaining (Free)',
                      SubscriptionService.instance.isPremium ? '∞' : '$remainingGens',
                      Icons.battery_charging_full,
                      AppColors.naturalGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final subscriptionService = SubscriptionService.instance;
    
    return Column(
      children: [
        if (!subscriptionService.isPremium) ...[
          // Purchase button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPurchasing ? null : _handlePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isPurchasing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.diamond, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Upgrade to Premium',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Restore purchases button
          TextButton(
            onPressed: _isPurchasing ? null : _handleRestore,
            child: Text(
              'Restore Purchases',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ] else ...[
          // Manage subscription button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleManageSubscription,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warmGold,
                side: BorderSide(color: AppColors.warmGold),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Manage Subscription',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 20),
        
        // Terms and privacy
        Text(
          'By subscribing, you agree to our Terms of Service and Privacy Policy',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _handlePurchase() async {
    setState(() => _isPurchasing = true);
    
    try {
      final success = await SubscriptionService.instance.purchasePremium();
      
      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Purchase failed. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Purchase failed: ${e.toString()}');
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isPurchasing = true);
    
    try {
      final success = await SubscriptionService.instance.restorePurchases();
      
      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('No purchases found to restore.');
      }
    } catch (e) {
      _showErrorDialog('Restore failed: ${e.toString()}');
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  Future<void> _handleManageSubscription() async {
    try {
      await SubscriptionService.instance.manageSubscription();
    } catch (e) {
      _showErrorDialog('Unable to open subscription management.');
    }
  }

  void _showSuccessDialog() {
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
              Icon(Icons.check_circle, color: AppColors.naturalGreen),
              const SizedBox(width: 8),
              Text(
                'Welcome to Premium!',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Text(
            'You now have unlimited access to all SoulBios features. Enjoy your premium experience!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close subscription screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.naturalGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Get Started'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
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
              Icon(Icons.error, color: AppColors.anxiety),
              const SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }
}