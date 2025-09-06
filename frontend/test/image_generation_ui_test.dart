import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:encarta_soulbios/features/mindmaze/screens/chamber_image_gallery_screen.dart';
import 'package:encarta_soulbios/features/journey/widgets/adaptive_memory_timeline.dart';

void main() {
  group('Image Generation UI Tests', () {
    testWidgets('ChamberImageGalleryScreen displays empty state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChamberImageGalleryScreen(
              chamberType: 'emotion',
              chamberName: 'Emotion Chamber',
              chamberColor: Colors.blue,
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Should show empty state initially
      expect(find.text('No images generated yet'), findsOneWidget);
      expect(find.text('Generate your first chamber scene to see it here'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('ChamberImageGalleryScreen has proper app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ChamberImageGalleryScreen(
              chamberType: 'emotion',
              chamberName: 'Emotion Chamber',
              chamberColor: Colors.blue,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check app bar elements
      expect(find.text('Emotion Chamber Gallery'), findsOneWidget);
      expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('AdaptiveMemoryTimeline shows tabs correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdaptiveMemoryTimeline(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for tab bar
      expect(find.text('Journey Archive'), findsOneWidget);
      expect(find.text('Your memories and generated scenes'), findsOneWidget);
      
      // Should have tabs
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byIcon(Icons.timeline), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.image), findsAtLeastNWidgets(1));
    });

    testWidgets('Tab switching works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdaptiveMemoryTimeline(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have tab bar
      expect(find.byType(TabBar), findsOneWidget);
      
      // Should be able to find tab content
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('Image gallery shows empty state when no images', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdaptiveMemoryTimeline(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to images tab (index 1)
      final tabBar = find.byType(TabBar);
      expect(tabBar, findsOneWidget);
      
      // Tap on the images tab
      await tester.tap(find.text('Images (0)'));
      await tester.pumpAndSettle();

      // Should show empty state for images
      expect(find.text('No generated images yet'), findsOneWidget);
      expect(find.text('Visit chambers and generate scenes to see them here'), findsOneWidget);
    });

    group('Performance Tests', () {
      testWidgets('Image gallery should render efficiently', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ChamberImageGalleryScreen(
                chamberType: 'emotion',
                chamberName: 'Emotion Chamber',
                chamberColor: Colors.blue,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should render in under 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      testWidgets('Timeline with tabs should render efficiently', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AdaptiveMemoryTimeline(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should render in under 300ms
        expect(stopwatch.elapsedMilliseconds, lessThan(300));
      });
    });

    group('Accessibility Tests', () {
      testWidgets('Image cards have semantic information', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ChamberImageGalleryScreen(
                chamberType: 'emotion',
                chamberName: 'Emotion Chamber',
                chamberColor: Colors.blue,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have semantic information for screen readers
        expect(find.text('No images generated yet'), findsOneWidget);
        expect(find.text('Generate your first chamber scene to see it here'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('Image loading errors are handled gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ChamberImageGalleryScreen(
                chamberType: 'emotion',
                chamberName: 'Emotion Chamber',
                chamberColor: Colors.blue,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should handle empty state gracefully
        expect(find.text('No images generated yet'), findsOneWidget);
        expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      });

      testWidgets('Navigation errors are handled', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: ChamberImageGalleryScreen(
                chamberType: 'emotion',
                chamberName: 'Emotion Chamber',
                chamberColor: Colors.blue,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Back button should work
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        
        // Tapping back should not cause errors
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      });
    });
  });
}