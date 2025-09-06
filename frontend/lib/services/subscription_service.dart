import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:hive/hive.dart';

enum SubscriptionTier {
  free,
  premium,
}

enum PremiumFeature {
  unlimitedImageGeneration,
  advancedChambers,
  premiumArtStyles,
  prioritySupport,
  exportData,
  customCharacters,
}

class SubscriptionService {
  static const String _premiumProductId = 'soulbios_premium_monthly';
  static const String _premiumEntitlementId = 'premium_access';
  
  // RevenueCat API Keys (replace with actual keys)
  static const String _revenueCatApiKeyAndroid = 'goog_YOUR_ANDROID_KEY';
  static const String _revenueCatApiKeyIOS = 'appl_YOUR_IOS_KEY';
  
  static SubscriptionService? _instance;
  static SubscriptionService get instance => _instance ??= SubscriptionService._();
  
  SubscriptionService._();
  
  bool _isInitialized = false;
  SubscriptionTier _currentTier = SubscriptionTier.free;
  CustomerInfo? _customerInfo;
  List<Package> _availablePackages = [];
  
  // Free tier limits
  static const int freeImageGenerationsPerDay = 3;
  static const List<String> freeChamberTypes = ['emotion', 'fortress'];
  
  // Getters
  SubscriptionTier get currentTier => _currentTier;
  bool get isPremium => _currentTier == SubscriptionTier.premium;
  bool get isInitialized => _isInitialized;
  CustomerInfo? get customerInfo => _customerInfo;
  List<Package> get availablePackages => _availablePackages;
  
  /// Initialize RevenueCat SDK
  Future<void> initialize({String? userId}) async {
    try {
      // Configure RevenueCat
      PurchasesConfiguration configuration;
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(_revenueCatApiKeyAndroid);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        configuration = PurchasesConfiguration(_revenueCatApiKeyIOS);
      } else {
        // For other platforms, use a default key or skip initialization
        _isInitialized = true;
        _currentTier = SubscriptionTier.free;
        return;
      }
      
      if (userId != null) {
        await Purchases.logIn(userId);
      }
      
      await Purchases.configure(configuration);
      
      // Get current customer info
      await _refreshCustomerInfo();
      
      // Load available packages
      await _loadPackages();
      
      _isInitialized = true;
      
      debugPrint('SubscriptionService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize SubscriptionService: $e');
      // Fallback to free tier
      _isInitialized = true;
      _currentTier = SubscriptionTier.free;
    }
  }
  
  /// Refresh customer info and update subscription status
  Future<void> _refreshCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      _updateSubscriptionTier();
    } catch (e) {
      debugPrint('Failed to refresh customer info: $e');
    }
  }
  
  /// Load available packages from RevenueCat
  Future<void> _loadPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        _availablePackages = offerings.current!.availablePackages;
      }
    } catch (e) {
      debugPrint('Failed to load packages: $e');
    }
  }
  
  /// Update subscription tier based on customer info
  void _updateSubscriptionTier() {
    if (_customerInfo?.entitlements.active.containsKey(_premiumEntitlementId) == true) {
      _currentTier = SubscriptionTier.premium;
    } else {
      _currentTier = SubscriptionTier.free;
    }
  }
  
  /// Check if user has access to a specific premium feature
  bool hasFeatureAccess(PremiumFeature feature) {
    if (isPremium) return true;
    
    // Some features might be available in free tier with limitations
    switch (feature) {
      case PremiumFeature.unlimitedImageGeneration:
        return false; // Free tier has daily limits
      case PremiumFeature.advancedChambers:
        return false; // Only basic chambers in free tier
      case PremiumFeature.premiumArtStyles:
        return false; // Premium only
      case PremiumFeature.prioritySupport:
        return false; // Premium only
      case PremiumFeature.exportData:
        return false; // Premium only
      case PremiumFeature.customCharacters:
        return false; // Premium only
    }
  }
  
  /// Check if user can generate an image (respects daily limits for free tier)
  Future<bool> canGenerateImage() async {
    if (isPremium) return true;
    
    // Check daily usage for free tier
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    try {
      final usageBox = Hive.box('usage_tracking');
      final todayUsage = usageBox.get('image_gen_$todayKey', defaultValue: 0) as int;
      
      return todayUsage < freeImageGenerationsPerDay;
    } catch (e) {
      debugPrint('Error checking image generation limit: $e');
      return false;
    }
  }
  
  /// Record image generation usage
  Future<void> recordImageGeneration() async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    try {
      final usageBox = Hive.box('usage_tracking');
      final currentUsage = usageBox.get('image_gen_$todayKey', defaultValue: 0) as int;
      await usageBox.put('image_gen_$todayKey', currentUsage + 1);
    } catch (e) {
      debugPrint('Error recording image generation: $e');
    }
  }
  
  /// Get remaining free image generations for today
  Future<int> getRemainingFreeGenerations() async {
    if (isPremium) return -1; // Unlimited
    
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    try {
      final usageBox = Hive.box('usage_tracking');
      final todayUsage = usageBox.get('image_gen_$todayKey', defaultValue: 0) as int;
      
      return (freeImageGenerationsPerDay - todayUsage).clamp(0, freeImageGenerationsPerDay);
    } catch (e) {
      debugPrint('Error getting remaining generations: $e');
      return 0;
    }
  }
  
  /// Check if chamber type is available in current tier
  bool isChamberTypeAvailable(String chamberType) {
    if (isPremium) return true;
    return freeChamberTypes.contains(chamberType.toLowerCase());
  }
  
  /// Get list of premium chamber types
  List<String> getPremiumChamberTypes() {
    return ['growth', 'wisdom', 'transformation', 'integration'];
  }
  
  /// Purchase premium subscription
  Future<bool> purchasePremium() async {
    if (!_isInitialized) {
      throw Exception('SubscriptionService not initialized');
    }
    
    try {
      // Find the premium package
      final premiumPackage = _availablePackages.firstWhere(
        (package) => package.storeProduct.identifier == _premiumProductId,
        orElse: () => throw Exception('Premium package not found'),
      );
      
      // Make the purchase
      final customerInfo = await Purchases.purchasePackage(premiumPackage);
      
      // Update local state
      _customerInfo = customerInfo;
      _updateSubscriptionTier();
      
      return isPremium;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }
  
  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (!_isInitialized) {
      throw Exception('SubscriptionService not initialized');
    }
    
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      _updateSubscriptionTier();
      
      return isPremium;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }
  
  /// Get premium features list for display
  List<String> getPremiumFeatures() {
    return [
      'Unlimited AI image generation',
      'Access to all chamber types',
      'Premium art styles and filters',
      'Custom character creation',
      'Priority customer support',
      'Export your data and memories',
      'Advanced analytics and insights',
      'Early access to new features',
    ];
  }
  
  /// Get subscription price for display
  String? getPremiumPrice() {
    try {
      final premiumPackage = _availablePackages.firstWhere(
        (package) => package.storeProduct.identifier == _premiumProductId,
        orElse: () => throw Exception('Premium package not found'),
      );
      
      return premiumPackage.storeProduct.priceString;
    } catch (e) {
      return '\$4.99/month'; // Fallback price
    }
  }
  
  /// Check if user is in trial period
  bool get isInTrialPeriod {
    if (_customerInfo?.entitlements.active.isEmpty ?? true) return false;
    
    final premiumEntitlement = _customerInfo!.entitlements.active[_premiumEntitlementId];
    return premiumEntitlement?.periodType == PeriodType.trial;
  }
  
  /// Get trial end date
  DateTime? get trialEndDate {
    if (!isInTrialPeriod) return null;
    
    final premiumEntitlement = _customerInfo!.entitlements.active[_premiumEntitlementId];
    final expirationDateString = premiumEntitlement?.expirationDate;
    if (expirationDateString != null) {
      return DateTime.tryParse(expirationDateString);
    }
    return null;
  }
  
  /// Cancel subscription (redirect to platform settings)
  Future<void> manageSubscription() async {
    try {
      // For RevenueCat 6.x, we need to handle this differently
      // This would typically open the platform's subscription management
      debugPrint('Manage subscription - redirect to platform settings');
    } catch (e) {
      debugPrint('Failed to show manage subscriptions: $e');
    }
  }
  
  /// Get usage statistics for display
  Future<Map<String, dynamic>> getUsageStats() async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    try {
      final usageBox = Hive.box('usage_tracking');
      final todayImageGens = usageBox.get('image_gen_$todayKey', defaultValue: 0) as int;
      
      // Calculate weekly usage
      int weeklyImageGens = 0;
      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        weeklyImageGens += usageBox.get('image_gen_$dateKey', defaultValue: 0) as int;
      }
      
      return {
        'todayImageGenerations': todayImageGens,
        'weeklyImageGenerations': weeklyImageGens,
        'remainingFreeGenerations': await getRemainingFreeGenerations(),
        'subscriptionTier': _currentTier.name,
        'isTrialActive': isInTrialPeriod,
        'trialEndDate': trialEndDate?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting usage stats: $e');
      return {};
    }
  }
  
  /// Dispose resources
  void dispose() {
    // RevenueCat doesn't require explicit disposal
  }
}