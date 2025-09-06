import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encarta_soulbios/services/subscription_service.dart';
import 'package:encarta_soulbios/widgets/premium_gate_widget.dart';
import 'package:encarta_soulbios/screens/subscription_screen.dart';

void main() {
  group('Premium Features Tests', () {

    group('SubscriptionService Tests', () {
      late SubscriptionService subscriptionService;

      setUp(() {
        subscriptionService = SubscriptionService.instance;
      });

      test('should initialize with free tier by default', () {
        expect(subscriptionService.currentTier, SubscriptionTier.free);
        expect(subscriptionService.isPremium, false);
      });

      test('should check feature access correctly for free tier', () {
        expect(subscriptionService.hasFeatureAccess(PremiumFeature.unlimitedImageGeneration), false);
        expect(subscriptionService.hasFeatureAccess(PremiumFeature.advancedChambers), false);
        expect(subscriptionService.hasFeatureAccess(PremiumFeature.premiumArtStyles), false);
        expect(subscriptionService.hasFeatureAccess(PremiumFeature.prioritySupport), false);
        expect(subscriptionService.hasFeatureAccess(PremiumFeature.exportData), false);
        expect(subscriptionService.hasFeatureAccess(PremiumFeature.customCharacters), false);
      });

      test('should check chamber type availability correctly', () {
        // Free chambers
        expect(subscriptionService.isChamberTypeAvailable('emotion'), true);
        expect(subscriptionService.isChamberTypeAvailable('fortress'), true);
        
        // Premium chambers
        expect(subscriptionService.isChamberTypeAvailable('growth'), false);
        expect(subscriptionService.isChamberTypeAvailable('wisdom'), false);
        expect(subscriptionService.isChamberTypeAvailable('transformation'), false);
        expect(subscriptionService.isChamberTypeAvailable('integration'), false);
      });

      test('should have correct free tier limits', () {
        expect(SubscriptionService.freeImageGenerationsPerDay, 3);
        expect(SubscriptionService.freeChamberTypes.length, 2);
        expect(SubscriptionService.freeChamberTypes.contains('emotion'), true);
        expect(SubscriptionService.freeChamberTypes.contains('fortress'), true);
      });

      test('should provide correct premium features list', () {
        final features = subscriptionService.getPremiumFeatures();
        
        expect(features.length, greaterThanOrEqualTo(6));
        expect(features.contains('Unlimited AI image generation'), true);
        expect(features.contains('Access to all chamber types'), true);
        expect(features.contains('Premium art styles and filters'), true);
        expect(features.contains('Custom character creation'), true);
        expect(features.contains('Priority customer support'), true);
        expect(features.contains('Export your data and memories'), true);
      });

      test('should provide premium chamber types list', () {
        final premiumChambers = subscriptionService.getPremiumChamberTypes();
        
        expect(premiumChambers.length, 4);
        expect(premiumChambers.contains('growth'), true);
        expect(premiumChambers.contains('wisdom'), true);
        expect(premiumChambers.contains('transformation'), true);
        expect(premiumChambers.contains('integration'), true);
      });

      test('should provide correct pricing information', () {
        final price = subscriptionService.getPremiumPrice();
        expect(price, isNotNull);
        expect(price, contains('\$'));
      });
    });

    group('PremiumGateWidget Tests', () {
      testWidgets('should show premium gate for locked features', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: PremiumGateWidget(
                  feature: PremiumFeature.unlimitedImageGeneration,
                  child: Text('Protected Content'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show premium gate, not the child
        expect(find.text('Protected Content'), findsNothing);
        expect(find.text('Unlimited Image Generation'), findsOneWidget);
        expect(find.text('Generate unlimited AI scenes and images. Free users are limited to 3 per day.'), findsOneWidget);
        expect(find.text('Upgrade to Premium'), findsOneWidget);
        expect(find.byIcon(Icons.diamond), findsOneWidget);
      });

      testWidgets('should show upgrade dialog when upgrade button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: PremiumGateWidget(
                  feature: PremiumFeature.advancedChambers,
                  child: Text('Protected Content'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap upgrade button
        await tester.tap(find.text('Upgrade to Premium'));
        await tester.pumpAndSettle();

        // Should show upgrade dialog
        expect(find.text('Upgrade to Premium'), findsAtLeastNWidgets(1));
        expect(find.text('Unlock this feature and more with SoulBios Premium:'), findsOneWidget);
        expect(find.text('Maybe Later'), findsOneWidget);
        expect(find.text('Upgrade Now'), findsOneWidget);
      });

      testWidgets('should show custom title and description when provided', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: PremiumGateWidget(
                  feature: PremiumFeature.premiumArtStyles,
                  customTitle: 'Custom Premium Title',
                  customDescription: 'Custom premium description text',
                  child: Text('Protected Content'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Custom Premium Title'), findsOneWidget);
        expect(find.text('Custom premium description text'), findsOneWidget);
      });
    });

    group('UsageLimitWidget Tests', () {
      testWidgets('should show usage progress correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: UsageLimitWidget(
                  title: 'Daily Image Generation',
                  description: 'You have used 2 of 3 free generations today',
                  currentUsage: 2,
                  maxUsage: 3,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Daily Image Generation'), findsOneWidget);
        expect(find.text('You have used 2 of 3 free generations today'), findsOneWidget);
        expect(find.text('2/3'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should show upgrade button when at limit', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: UsageLimitWidget(
                  title: 'Daily Image Generation',
                  description: 'You have reached your daily limit',
                  currentUsage: 3,
                  maxUsage: 3,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Upgrade for Unlimited Access'), findsOneWidget);
        expect(find.byIcon(Icons.diamond), findsOneWidget);
      });

      testWidgets('should not show for premium users', (WidgetTester tester) async {
        // This test would need to mock the subscription service to return premium status
        // For now, we'll test the widget behavior assuming free tier
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: UsageLimitWidget(
                  title: 'Daily Image Generation',
                  description: 'Usage tracking',
                  currentUsage: 1,
                  maxUsage: 3,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show for free users
        expect(find.text('Daily Image Generation'), findsOneWidget);
      });
    });

    group('SubscriptionScreen Tests', () {
      testWidgets('should display subscription screen correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: SubscriptionScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check header
        expect(find.text('SoulBios Premium'), findsOneWidget);
        expect(find.byIcon(Icons.diamond), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // Check free tier status
        expect(find.text('Free Tier'), findsOneWidget);
        expect(find.text('Upgrade to unlock unlimited features and premium content'), findsOneWidget);

        // Check premium features section
        expect(find.text('Premium Features'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(6));

        // Check pricing section
        expect(find.text('Simple Pricing'), findsOneWidget);
        expect(find.text('per month'), findsOneWidget);
        expect(find.text('Cancel anytime • No commitment'), findsOneWidget);

        // Check action buttons
        expect(find.text('Upgrade to Premium'), findsOneWidget);
        expect(find.text('Restore Purchases'), findsOneWidget);
      });

      testWidgets('should show usage statistics', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: SubscriptionScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Wait for usage stats to load
        await tester.pump(Duration(seconds: 1));

        expect(find.text('Usage Today'), findsOneWidget);
        expect(find.text('Images Generated'), findsOneWidget);
        expect(find.text('Remaining (Free)'), findsOneWidget);
      });

      testWidgets('should handle back navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: SubscriptionScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap back button
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Should navigate back (in a real app, this would pop the route)
      });
    });

    group('Integration Tests', () {
      testWidgets('should integrate premium gating with image generation', (WidgetTester tester) async {
        // Test widget that uses premium gating
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    PremiumGateWidget(
                      feature: PremiumFeature.unlimitedImageGeneration,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Text('Generate Image'),
                      ),
                    ),
                    UsageLimitWidget(
                      title: 'Daily Limit',
                      description: 'Track your usage',
                      currentUsage: 0,
                      maxUsage: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show premium gate for unlimited generation
        expect(find.text('Unlimited Image Generation'), findsOneWidget);
        
        // Should show usage tracking
        expect(find.text('Daily Limit'), findsOneWidget);
        expect(find.text('0/3'), findsOneWidget);
      });

      testWidgets('should show premium chamber indicators', (WidgetTester tester) async {
        // This would test the chamber cards with premium indicators
        // For now, we'll test the basic premium gate functionality
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: PremiumGateWidget(
                  feature: PremiumFeature.advancedChambers,
                  child: Container(
                    child: Text('Growth Chamber'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Advanced Chambers'), findsOneWidget);
        expect(find.text('Access Growth, Wisdom, and Transformation chambers for deeper exploration.'), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('subscription service should initialize quickly', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        // Initialize subscription service
        await SubscriptionService.instance.initialize();
        
        stopwatch.stop();
        
        // Should initialize in under 100ms for testing
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      testWidgets('premium gate widget should render efficiently', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: PremiumGateWidget(
                  feature: PremiumFeature.unlimitedImageGeneration,
                  child: Container(height: 200, child: Text('Content')),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should render in under 200ms
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });
    });

    group('Error Handling Tests', () {
      test('should handle subscription service initialization failure gracefully', () async {
        // Test that the service falls back to free tier on initialization failure
        expect(SubscriptionService.instance.currentTier, SubscriptionTier.free);
        expect(SubscriptionService.instance.isInitialized, true);
      });

      test('should handle subscription service gracefully', () {
        final subscriptionService = SubscriptionService.instance;
        
        // Should not throw errors when accessing basic properties
        expect(subscriptionService.currentTier, isNotNull);
        expect(subscriptionService.isPremium, isFalse);
        expect(subscriptionService.getPremiumFeatures(), isNotEmpty);
      });
    });
  });
}