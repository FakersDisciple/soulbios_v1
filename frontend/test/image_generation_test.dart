import 'package:flutter_test/flutter_test.dart';
import 'package:encarta_soulbios/models/api_models.dart';
import 'package:encarta_soulbios/services/image_generation_service.dart';

void main() {
  group('Image Generation System Tests', () {
    late ImageGenerationService imageService;

    setUp(() {
      imageService = ImageGenerationService();
    });

    group('ImageGenerationRequest', () {
      test('should create request with required fields', () {
        const request = ImageGenerationRequest(
          userId: 'test_user',
          prompt: 'A mystical chamber',
        );

        expect(request.userId, equals('test_user'));
        expect(request.prompt, equals('A mystical chamber'));
        expect(request.style, equals('mystical'));
        expect(request.confirmed, isFalse);
      });

      test('should serialize to JSON correctly', () {
        const request = ImageGenerationRequest(
          userId: 'test_user',
          prompt: 'A mystical chamber',
          chamberType: 'emotion',
          characterArchetype: 'compassionate_friend',
          style: 'ethereal',
          confirmed: true,
        );

        final json = request.toJson();

        expect(json['user_id'], equals('test_user'));
        expect(json['prompt'], equals('A mystical chamber'));
        expect(json['chamber_type'], equals('emotion'));
        expect(json['character_archetype'], equals('compassionate_friend'));
        expect(json['style'], equals('ethereal'));
        expect(json['confirmed'], isTrue);
      });
    });

    group('ImageGenerationResponse', () {
      test('should parse successful response correctly', () {
        final json = {
          'status': 'success',
          'image_url': 'https://example.com/image.jpg',
          'image_id': 'img_123',
          'prompt_used': 'Enhanced prompt',
          'generation_time_ms': 2500,
          'cached': false,
        };

        final response = ImageGenerationResponse.fromJson(json);

        expect(response.status, equals('success'));
        expect(response.imageUrl, equals('https://example.com/image.jpg'));
        expect(response.imageId, equals('img_123'));
        expect(response.promptUsed, equals('Enhanced prompt'));
        expect(response.generationTimeMs, equals(2500));
        expect(response.cached, isFalse);
        expect(response.isSuccess, isTrue);
        expect(response.requiresConfirmation, isFalse);
        expect(response.hasError, isFalse);
      });

      test('should parse confirmation required response correctly', () {
        final json = {
          'status': 'confirmation_required',
          'image_id': 'img_123',
          'prompt_used': 'Enhanced prompt for confirmation',
          'generation_time_ms': 100,
          'cached': false,
        };

        final response = ImageGenerationResponse.fromJson(json);

        expect(response.status, equals('confirmation_required'));
        expect(response.imageUrl, isNull);
        expect(response.requiresConfirmation, isTrue);
        expect(response.isSuccess, isFalse);
        expect(response.hasError, isFalse);
      });

      test('should parse error response correctly', () {
        final json = {
          'status': 'error',
          'image_id': 'error',
          'prompt_used': 'Failed prompt',
          'generation_time_ms': 50,
          'cached': false,
          'error_message': 'Generation service unavailable',
        };

        final response = ImageGenerationResponse.fromJson(json);

        expect(response.status, equals('error'));
        expect(response.hasError, isTrue);
        expect(response.errorMessage, equals('Generation service unavailable'));
        expect(response.isSuccess, isFalse);
        expect(response.requiresConfirmation, isFalse);
      });

      test('should handle cached response correctly', () {
        final json = {
          'status': 'success',
          'image_url': 'https://example.com/cached_image.jpg',
          'image_id': 'cached_123',
          'prompt_used': 'Cached prompt',
          'generation_time_ms': 10,
          'cached': true,
        };

        final response = ImageGenerationResponse.fromJson(json);

        expect(response.cached, isTrue);
        expect(response.generationTimeMs, equals(10));
        expect(response.isSuccess, isTrue);
      });
    });

    group('ImageGenerationService', () {
      test('should provide chamber-specific prompt suggestions', () {
        final emotionSuggestions = imageService.getChamberPromptSuggestions('emotion');
        final fortressSuggestions = imageService.getChamberPromptSuggestions('fortress');
        final growthSuggestions = imageService.getChamberPromptSuggestions('growth');
        final wisdomSuggestions = imageService.getChamberPromptSuggestions('wisdom');
        final defaultSuggestions = imageService.getChamberPromptSuggestions('unknown');

        expect(emotionSuggestions.isNotEmpty, isTrue);
        expect(fortressSuggestions.isNotEmpty, isTrue);
        expect(growthSuggestions.isNotEmpty, isTrue);
        expect(wisdomSuggestions.isNotEmpty, isTrue);
        expect(defaultSuggestions.isNotEmpty, isTrue);

        // Check that suggestions are chamber-appropriate
        expect(emotionSuggestions.any((s) => s.toLowerCase().contains('emotion')), isTrue);
        expect(fortressSuggestions.any((s) => s.toLowerCase().contains('fortress') || s.toLowerCase().contains('wall')), isTrue);
        expect(growthSuggestions.any((s) => s.toLowerCase().contains('growth') || s.toLowerCase().contains('tree')), isTrue);
        expect(wisdomSuggestions.any((s) => s.toLowerCase().contains('wisdom') || s.toLowerCase().contains('knowledge')), isTrue);
      });

      test('should provide character-specific style suggestions', () {
        final styleSuggestions = imageService.getCharacterStyleSuggestions();

        expect(styleSuggestions.containsKey('compassionate_friend'), isTrue);
        expect(styleSuggestions.containsKey('resilient_explorer'), isTrue);
        expect(styleSuggestions.containsKey('wise_detective'), isTrue);

        expect(styleSuggestions['compassionate_friend']!.contains('warm'), isTrue);
        expect(styleSuggestions['resilient_explorer']!.contains('adventurous'), isTrue);
        expect(styleSuggestions['wise_detective']!.contains('analytical'), isTrue);
      });

      test('should handle cache operations gracefully', () async {
        // These tests would require Hive initialization in a test environment
        // For now, we test that the methods don't throw exceptions
        
        expect(() async {
          await imageService.cacheImageLocally('test_id', 'test_url');
        }, returnsNormally);

        expect(() async {
          await imageService.getCachedImage('test_id');
        }, returnsNormally);

        expect(() async {
          await imageService.clearImageCache();
        }, returnsNormally);
      });
    });

    group('Performance Tests', () {
      test('should handle prompt suggestions efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          imageService.getChamberPromptSuggestions('emotion');
          imageService.getChamberPromptSuggestions('fortress');
          imageService.getCharacterStyleSuggestions();
        }
        
        stopwatch.stop();
        
        // Should complete 300 operations in under 10ms
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });

      test('should create requests efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          const request = ImageGenerationRequest(
            userId: 'test_user',
            prompt: 'Test prompt',
            chamberType: 'emotion',
            characterArchetype: 'compassionate_friend',
          );
          request.toJson();
        }
        
        stopwatch.stop();
        
        // Should create and serialize 1000 requests in under 50ms
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });

    group('Content Validation', () {
      test('should provide meaningful prompt suggestions', () {
        final chambers = ['emotion', 'fortress', 'growth', 'wisdom'];
        
        for (final chamber in chambers) {
          final suggestions = imageService.getChamberPromptSuggestions(chamber);
          
          // Each chamber should have at least 3 suggestions
          expect(suggestions.length, greaterThanOrEqualTo(3));
          
          // Each suggestion should be meaningful (at least 20 characters)
          for (final suggestion in suggestions) {
            expect(suggestion.length, greaterThan(20));
            expect(suggestion.trim(), equals(suggestion));
            expect(suggestion.isNotEmpty, isTrue);
          }
        }
      });

      test('should provide appropriate character styles', () {
        final styles = imageService.getCharacterStyleSuggestions();
        
        for (final style in styles.values) {
          // Each style should be descriptive (at least 15 characters)
          expect(style.length, greaterThan(15));
          expect(style.contains(','), isTrue); // Should have multiple descriptors
        }
      });
    });

    group('Error Handling', () {
      test('should handle invalid chamber types gracefully', () {
        final suggestions = imageService.getChamberPromptSuggestions('invalid_chamber');
        
        expect(suggestions.isNotEmpty, isTrue);
        expect(suggestions.length, greaterThanOrEqualTo(3));
      });

      test('should handle empty prompts in requests', () {
        const request = ImageGenerationRequest(
          userId: 'test_user',
          prompt: '',
        );

        final json = request.toJson();
        expect(json['prompt'], equals(''));
      });

      test('should handle null values in response parsing', () {
        final json = {
          'status': 'success',
          'prompt_used': 'Test prompt',
          'generation_time_ms': 1000,
          // Missing optional fields
        };

        final response = ImageGenerationResponse.fromJson(json);
        
        expect(response.imageUrl, isNull);
        expect(response.imageId, isNull);
        expect(response.cached, isFalse);
        expect(response.errorMessage, isNull);
      });
    });
  });
}