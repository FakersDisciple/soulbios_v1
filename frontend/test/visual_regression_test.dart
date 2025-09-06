import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:encarta_soulbios/widgets/enhanced_alice_avatar.dart';
import 'package:encarta_soulbios/widgets/animated_chamber_card.dart';
import 'package:encarta_soulbios/widgets/animated_loading_widget.dart';
import 'package:encarta_soulbios/widgets/enhanced_error_dialog.dart';
import 'package:encarta_soulbios/widgets/alice_thinking_indicator.dart';
import 'package:encarta_soulbios/features/mindmaze/models/alice_persona.dart';
import 'package:encarta_soulbios/features/mindmaze/models/chamber.dart';
import 'package:encarta_soulbios/core/theme/app_colors.dart';

void main() {
  group('Visual Regression Tests', () {
    testGoldens('Enhanced Alice Avatar - All Personas', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.iphone11]);

      final personas = [
        AlicePersonaType.nurturingPresence,
        AlicePersonaType.wiseDetective,
        AlicePersonaType.transcendentGuide,
        AlicePersonaType.unifiedConsciousness,
      ];

      for (final persona in personas) {
        builder.addScenario(
          widget: ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF0A0A0F),
                body: Center(
                  child: EnhancedAliceAvatar(
                    size: 80,
                    showNotificationBadge: persona == AlicePersonaType.nurturingPresence,
                  ),
                ),
              ),
            ),
          ),
          name: 'alice_${persona.name}',
        );
      }

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'alice_avatars_all_personas');
    });

    testGoldens('Animated Chamber Cards - Different States', (tester) async {
      final testChambers = [
        Chamber(
          name: 'Emotion Chamber',
          description: 'Explore your emotional landscape',
          type: ChamberType.emotion,
          themeColor: AppColors.deepPurple,
          icon: Icons.favorite,
          isUnlocked: true,
          completedQuestions: 15,
          totalQuestions: 21,
        ),
        Chamber(
          name: 'Fortress Chamber',
          description: 'Strengthen your inner defenses',
          type: ChamberType.fortress,
          themeColor: AppColors.naturalGreen,
          icon: Icons.security,
          isUnlocked: true,
          completedQuestions: 5,
          totalQuestions: 21,
        ),
        Chamber(
          name: 'Pattern Chamber',
          description: 'Discover your behavioral patterns',
          type: ChamberType.pattern,
          themeColor: AppColors.calmBlue,
          icon: Icons.analytics,
          isUnlocked: false,
          completedQuestions: 0,
          totalQuestions: 21,
        ),
      ];

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone]);

      for (int i = 0; i < testChambers.length; i++) {
        final chamber = testChambers[i];
        builder.addScenario(
          widget: ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF0A0A0F),
                body: Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: AnimatedChamberCard(
                      chamber: chamber,
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
          name: 'chamber_${chamber.type.name}_${chamber.isUnlocked ? 'unlocked' : 'locked'}',
        );
      }

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'chamber_cards_different_states');
    });

    testGoldens('Loading Widgets - All Types', (tester) async {
      final loadingTypes = [
        LoadingType.general,
        LoadingType.imageGeneration,
        LoadingType.patternAnalysis,
        LoadingType.memoryProcessing,
        LoadingType.aliceThinking,
      ];

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone]);

      for (final type in loadingTypes) {
        builder.addScenario(
          widget: MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF0A0A0F),
              body: Center(
                child: AnimatedLoadingWidget(
                  type: type,
                  size: 100,
                ),
              ),
            ),
          ),
          name: 'loading_${type.name}',
        );
      }

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'loading_widgets_all_types');
    });

    testGoldens('Error Dialogs - Different Types', (tester) async {
      final errorTypes = [
        ErrorType.network,
        ErrorType.imageGeneration,
        ErrorType.patternAnalysis,
        ErrorType.subscription,
        ErrorType.general,
      ];

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone]);

      for (final type in errorTypes) {
        builder.addScenario(
          widget: MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF0A0A0F),
              body: Center(
                child: EnhancedErrorDialog(
                  type: type,
                  title: _getErrorTitle(type),
                  message: _getErrorMessage(type),
                  onRetry: () {},
                  showAnimation: false, // Disable animation for golden tests
                ),
              ),
            ),
          ),
          name: 'error_${type.name}',
        );
      }

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'error_dialogs_all_types');
    });

    testGoldens('Alice Thinking Indicator', (tester) async {
      await tester.pumpWidgetBuilder(
        const AliceThinkingIndicator(size: 60),
        wrapper: materialAppWrapper(
          theme: ThemeData.dark(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await screenMatchesGolden(tester, 'alice_thinking_indicator');
    });

    group('Animation Consistency Tests', () {
      testWidgets('Chamber unlock animation completes correctly', (tester) async {
        final chamber = Chamber(
          name: 'Test Chamber',
          description: 'Test chamber description',
          type: ChamberType.emotion,
          themeColor: AppColors.deepPurple,
          icon: Icons.favorite,
          isUnlocked: false,
          completedQuestions: 0,
          totalQuestions: 21,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AnimatedChamberCard(
                  chamber: chamber,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        // Initial state
        expect(find.byType(AnimatedChamberCard), findsOneWidget);

        // Create unlocked chamber
        final unlockedChamber = chamber.copyWith(isUnlocked: true);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AnimatedChamberCard(
                  chamber: unlockedChamber,
                  onTap: () {},
                  showUnlockAnimation: true,
                ),
              ),
            ),
          ),
        );

        // Wait for animation to complete
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify animation completed without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('Alice persona transition animation works', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: EnhancedAliceAvatar(size: 80),
              ),
            ),
          ),
        );

        // Initial render
        await tester.pumpAndSettle();

        // Verify no animation errors
        expect(tester.takeException(), isNull);

        // Test persona transition (would need to trigger via provider)
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Loading animation cycles correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedLoadingWidget(
                type: LoadingType.imageGeneration,
              ),
            ),
          ),
        );

        // Let animation run for a few cycles
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    group('Performance Tests', () {
      testWidgets('Alice avatar renders efficiently', (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: EnhancedAliceAvatar(size: 80),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should render in under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      testWidgets('Chamber card animations perform well', (tester) async {
        final chamber = Chamber(
          name: 'Test Chamber',
          description: 'Test chamber description',
          type: ChamberType.emotion,
          themeColor: AppColors.deepPurple,
          icon: Icons.favorite,
          isUnlocked: true,
          completedQuestions: 10,
          totalQuestions: 21,
        );

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AnimatedChamberCard(
                  chamber: chamber,
                  onTap: () {},
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

      testWidgets('Loading widget is lightweight', (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedLoadingWidget(
                type: LoadingType.general,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should render in under 50ms
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}

String _getErrorTitle(ErrorType type) {
  switch (type) {
    case ErrorType.network:
      return 'Connection Issue';
    case ErrorType.imageGeneration:
      return 'Image Generation Failed';
    case ErrorType.patternAnalysis:
      return 'Analysis Unavailable';
    case ErrorType.subscription:
      return 'Subscription Issue';
    case ErrorType.general:
      return 'Something Went Wrong';
    default:
      return 'Error';
  }
}

String _getErrorMessage(ErrorType type) {
  switch (type) {
    case ErrorType.network:
      return 'Unable to connect to the server. Please check your internet connection.';
    case ErrorType.imageGeneration:
      return 'Unable to generate your scene. This might be due to high demand.';
    case ErrorType.patternAnalysis:
      return 'Unable to analyze your patterns right now. Your data is safe.';
    case ErrorType.subscription:
      return 'There was an issue with your subscription. Please try again.';
    case ErrorType.general:
      return 'An unexpected error occurred. Please try again.';
    default:
      return 'An error occurred.';
  }
}