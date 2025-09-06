import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encarta_soulbios/widgets/enhanced_alice_avatar.dart';
import 'package:encarta_soulbios/providers/alice_state_provider.dart';
import 'package:encarta_soulbios/features/mindmaze/models/alice_persona.dart';

void main() {
  group('EnhancedAliceAvatar', () {
    testWidgets('renders with default persona', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedAliceAvatar(),
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedAliceAvatar), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget); // nurturingPresence icon
    });

    testWidgets('shows notification badge when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedAliceAvatar(
                showNotificationBadge: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedAliceAvatar), findsOneWidget);
      expect(find.text('!'), findsOneWidget);
    });

    testWidgets('responds to tap', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedAliceAvatar(
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EnhancedAliceAvatar));
      expect(tapped, isTrue);
    });

    testWidgets('updates when persona changes', (WidgetTester tester) async {
      final container = ProviderContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedAliceAvatar(),
            ),
          ),
        ),
      );

      // Initial state should show nurturing presence
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Update the persona
      container.read(aliceStateProvider.notifier).state = 
        container.read(aliceStateProvider).copyWith(
          persona: AlicePersona.wiseDetective,
        );

      await tester.pump();

      // Should now show wise detective icon
      expect(find.byIcon(Icons.psychology), findsOneWidget);
    });
  });
}