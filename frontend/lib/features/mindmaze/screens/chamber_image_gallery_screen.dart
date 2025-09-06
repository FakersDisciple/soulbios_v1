import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';
import '../../../services/image_generation_service.dart';

class ChamberImageGalleryScreen extends ConsumerStatefulWidget {
  final String chamberType;
  final String chamberName;
  final Color chamberColor;

  const ChamberImageGalleryScreen({
    super.key,
    required this.chamberType,
    required this.chamberName,
    required this.chamberColor,
  });

  @override
  ConsumerState<ChamberImageGalleryScreen> createState() => _ChamberImageGalleryScreenState();
}

class _ChamberImageGalleryScreenState extends ConsumerState<ChamberImageGalleryScreen> {
  List<Map<String, dynamic>> _cachedImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedImages();
  }

  Future<void> _loadCachedImages() async {
    try {
      final cacheBox = Hive.box('image_cache');
      final List<Map<String, dynamic>> images = [];

      for (final key in cacheBox.keys) {
        final cached = cacheBox.get(key) as Map<String, dynamic>?;
        if (cached != null) {
          final cachedAt = DateTime.parse(cached['cached_at']);
          final isExpired = DateTime.now().difference(cachedAt).inDays > 7;
          
          if (!isExpired) {
            images.add({
              'id': key,
              'url': cached['url'],
              'cached_at': cachedAt,
              'prompt': cached['prompt'] ?? 'Generated scene',
            });
          }
        }
      }

      // Sort by creation date (newest first)
      images.sort((a, b) => (b['cached_at'] as DateTime).compareTo(a['cached_at'] as DateTime));

      setState(() {
        _cachedImages = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: widget.chamberColor,
        title: Text('${widget.chamberName} Gallery'),
        actions: [
          IconButton(
            onPressed: _clearCache,
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Cache',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cachedImages.isEmpty
              ? _buildEmptyState()
              : _buildImageGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'No images generated yet',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate your first chamber scene to see it here',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Chamber'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.chamberColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.image, color: widget.chamberColor),
              const SizedBox(width: 8),
              Text(
                '${_cachedImages.length} Generated Scene${_cachedImages.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _loadCachedImages,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: widget.chamberColor,
                ),
              ),
            ],
          ),
        ),
        
        // Image grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: _cachedImages.length,
            itemBuilder: (context, index) {
              final image = _cachedImages[index];
              return _buildImageCard(image, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(Map<String, dynamic> image, int index) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(image, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.chamberColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: image['url'],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade800,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade800,
                  child: const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ),
              ),
              
              // Overlay with info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDate(image['cached_at']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (image['prompt'] != null)
                        Text(
                          image['prompt'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(Map<String, dynamic> image, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: _cachedImages,
          initialIndex: initialIndex,
          chamberColor: widget.chamberColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Image Cache'),
          content: const Text(
            'This will remove all cached images from your device. You can always generate new ones.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Clear Cache',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final imageService = ref.read(imageGenerationServiceProvider);
      await imageService.clearImageCache();
      
      setState(() {
        _cachedImages.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image cache cleared'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;
  final Color chamberColor;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.chamberColor,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('${_currentIndex + 1} of ${widget.images.length}'),
        actions: [
          IconButton(
            onPressed: _shareImage,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final image = widget.images[index];
          return InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: image['url'],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.images[_currentIndex]['prompt'] != null)
              Text(
                'Prompt: ${widget.images[_currentIndex]['prompt']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Generated: ${_formatDate(widget.images[_currentIndex]['cached_at'])}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _shareImage() {
    // In a full implementation, this would share the image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image sharing feature coming soon!'),
      ),
    );
  }
}