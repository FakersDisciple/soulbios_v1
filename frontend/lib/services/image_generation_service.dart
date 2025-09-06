import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/api_models.dart';
import 'api_service.dart';

final imageGenerationServiceProvider = Provider<ImageGenerationService>((ref) {
  return ImageGenerationService();
});

class ImageGenerationService {
  static final ImageGenerationService _instance = ImageGenerationService._internal();
  factory ImageGenerationService() => _instance;
  ImageGenerationService._internal();

  // Generate image with confirmation dialog
  Future<ImageGenerationResponse?> generateImageWithConfirmation({
    required BuildContext context,
    required String userId,
    required String prompt,
    String? chamberType,
    String? characterArchetype,
    String style = 'mystical',
  }) async {
    try {
      // First, get the enhanced prompt without confirmation
      final previewResponse = await ApiService.generateImage(
        userId: userId,
        prompt: prompt,
        chamberType: chamberType,
        characterArchetype: characterArchetype,
        style: style,
        confirmed: false,
      );

      if (previewResponse.requiresConfirmation) {
        // Show confirmation dialog with enhanced prompt
        final confirmed = await _showConfirmationDialog(
          context,
          previewResponse.promptUsed,
        );

        if (!confirmed) {
          return null;
        }

        // Generate with confirmation
        return await ApiService.generateImage(
          userId: userId,
          prompt: prompt,
          chamberType: chamberType,
          characterArchetype: characterArchetype,
          style: style,
          confirmed: true,
        );
      }

      return previewResponse;
    } catch (e) {
      _showErrorDialog(context, 'Image generation failed: $e');
      return null;
    }
  }

  // Show confirmation dialog
  Future<bool> _showConfirmationDialog(BuildContext context, String enhancedPrompt) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generate Scene Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI will generate an image based on this enhanced prompt:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  enhancedPrompt,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This may take a few moments to generate.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Generate Image'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Image Generation Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 16),
              const Text(
                'You can try again or continue without an image.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show loading dialog during generation
  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating your scene image...'),
              SizedBox(height: 8),
              Text(
                'This may take up to 30 seconds',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hide loading dialog
  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Cache generated image locally
  Future<void> cacheImageLocally(String imageId, String imageUrl) async {
    try {
      final cacheBox = Hive.box('image_cache');
      await cacheBox.put(imageId, {
        'url': imageUrl,
        'cached_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently handle cache errors
    }
  }

  // Get cached image
  Future<String?> getCachedImage(String imageId) async {
    try {
      final cacheBox = Hive.box('image_cache');
      final cached = cacheBox.get(imageId) as Map<String, dynamic>?;
      
      if (cached != null) {
        final cachedAt = DateTime.parse(cached['cached_at']);
        final isExpired = DateTime.now().difference(cachedAt).inDays > 7;
        
        if (!isExpired) {
          return cached['url'];
        } else {
          // Remove expired cache
          await cacheBox.delete(imageId);
        }
      }
    } catch (e) {
      // Silently handle cache errors
    }
    return null;
  }

  // Clear image cache
  Future<void> clearImageCache() async {
    try {
      final cacheBox = Hive.box('image_cache');
      await cacheBox.clear();
    } catch (e) {
      // Silently handle cache errors
    }
  }

  // Get chamber-specific prompt suggestions
  List<String> getChamberPromptSuggestions(String chamberType) {
    switch (chamberType.toLowerCase()) {
      case 'emotion':
        return [
          'A flowing river of emotions with warm, colorful energy',
          'An emotional landscape with gentle hills and flowing streams',
          'A heart-centered sanctuary with soft, nurturing light',
          'Emotional currents flowing through a mystical garden',
        ];
      case 'fortress':
        return [
          'A protective stone fortress with hidden inner gardens',
          'Ancient walls surrounding a peaceful inner sanctuary',
          'A defensive castle with bridges leading to connection',
          'Protective barriers transforming into welcoming pathways',
        ];
      case 'growth':
        return [
          'A tree of potential with branches reaching toward light',
          'Expanding pathways leading to new possibilities',
          'A garden of transformation with blooming potential',
          'Upward spiraling energy representing personal growth',
        ];
      case 'wisdom':
        return [
          'An ancient library filled with glowing knowledge',
          'Mystical symbols floating in a chamber of understanding',
          'A wise owl perched in a tree of ancient wisdom',
          'Glowing insights emerging from deep contemplation',
        ];
      default:
        return [
          'A mystical chamber filled with consciousness energy',
          'A sacred space for inner exploration and growth',
          'An ethereal environment supporting self-discovery',
          'A transformative space where insights emerge naturally',
        ];
    }
  }

  // Get character-specific style suggestions
  Map<String, String> getCharacterStyleSuggestions() {
    return {
      'compassionate_friend': 'warm, nurturing, soft lighting, comforting presence',
      'resilient_explorer': 'adventurous, dynamic, bold colors, energetic movement',
      'wise_detective': 'analytical, mysterious, deep shadows, investigative mood',
    };
  }
}