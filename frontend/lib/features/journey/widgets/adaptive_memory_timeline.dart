import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/api_models.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../services/image_generation_service.dart';

enum SortOption {
  chronological,
  emotional,
  tags,
  sentiment,
}

class AdaptiveMemoryTimeline extends ConsumerStatefulWidget {
  final String? userStage;

  const AdaptiveMemoryTimeline({
    super.key,
    this.userStage,
  });

  @override
  ConsumerState<AdaptiveMemoryTimeline> createState() => _AdaptiveMemoryTimelineState();
}

class _AdaptiveMemoryTimelineState extends ConsumerState<AdaptiveMemoryTimeline> with TickerProviderStateMixin {
  List<MemoryEntry> _memories = [];
  List<Map<String, dynamic>> _generatedImages = [];
  SortOption _currentSort = SortOption.chronological;
  String? _selectedTag;
  bool _isLoading = true;
  bool _isLoadingImages = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMemories();
    _loadGeneratedImages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);
    
    try {
      final memoriesBox = Hive.box('memories');
      final memoryMaps = memoriesBox.values.cast<Map<String, dynamic>>().toList();
      
      _memories = memoryMaps
          .map((map) => MemoryEntry.fromJson(Map<String, dynamic>.from(map)))
          .toList();
      
      _sortMemories();
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sortMemories() {
    switch (_currentSort) {
      case SortOption.chronological:
        _memories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case SortOption.emotional:
        _memories.sort((a, b) {
          final aScore = a.sentimentScore ?? 0.0;
          final bScore = b.sentimentScore ?? 0.0;
          return bScore.compareTo(aScore);
        });
        break;
      case SortOption.tags:
        _memories.sort((a, b) => a.tags.length.compareTo(b.tags.length));
        break;
      case SortOption.sentiment:
        _memories.sort((a, b) {
          final aScore = (a.sentimentScore ?? 0.0).abs();
          final bScore = (b.sentimentScore ?? 0.0).abs();
          return bScore.compareTo(aScore);
        });
        break;
    }
    
    if (_selectedTag != null) {
      _memories = _memories
          .where((memory) => memory.tags.contains(_selectedTag))
          .toList();
    }
  }

  void _changeSortOption(SortOption newSort) {
    setState(() {
      _currentSort = newSort;
      _sortMemories();
    });
  }

  void _filterByTag(String? tag) {
    setState(() {
      _selectedTag = tag;
      _loadMemories(); // Reload and reapply filters
    });
  }

  Set<String> _getAllTags() {
    final allTags = <String>{};
    for (final memory in _memories) {
      allTags.addAll(memory.tags);
    }
    return allTags;
  }

  Color _getEmotionalColor(String? emotionalState, double? sentimentScore) {
    if (emotionalState != null) {
      switch (emotionalState.toLowerCase()) {
        case 'positive':
          return AppColors.naturalGreen;
        case 'negative':
          return AppColors.anxiety;
        default:
          return AppColors.calmBlue;
      }
    }
    
    if (sentimentScore != null) {
      if (sentimentScore > 0.3) return AppColors.naturalGreen;
      if (sentimentScore < -0.3) return AppColors.anxiety;
    }
    
    return AppColors.calmBlue;
  }

  Future<void> _loadGeneratedImages() async {
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
              'chamber_type': cached['chamber_type'] ?? 'unknown',
            });
          }
        }
      }

      // Sort by creation date (newest first)
      images.sort((a, b) => (b['cached_at'] as DateTime).compareTo(a['cached_at'] as DateTime));

      setState(() {
        _generatedImages = images;
        _isLoadingImages = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingImages = false;
      });
    }
  }

  String _getStageGuidance() {
    switch (widget.userStage?.toLowerCase()) {
      case 'beginner':
        return 'Focus on capturing daily experiences and emotions';
      case 'explorer':
        return 'Look for patterns and connections between memories';
      case 'integrator':
        return 'Synthesize insights from your journey';
      default:
        return 'Your memories are building your living autobiography';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with guidance
        GlassmorphicCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timeline,
                    color: AppColors.deepPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Journey Archive',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Your memories and generated scenes',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tab Bar
        GlassmorphicCard(
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.deepPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timeline, size: 16),
                    const SizedBox(width: 8),
                    Text('Memories (${_memories.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image, size: 16),
                    const SizedBox(width: 8),
                    Text('Images (${_generatedImages.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMemoriesTab(),
              _buildImagesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemoriesTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.warmGold,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort and filter controls
        GlassmorphicCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sort options
              Row(
                children: [
                  Text(
                    'Sort by:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: SortOption.values.map((option) {
                          final isSelected = _currentSort == option;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _changeSortOption(option),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.warmGold.withValues(alpha: 0.2)
                                      : AppColors.glassBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.warmGold
                                        : AppColors.glassBorder,
                                  ),
                                ),
                                child: Text(
                                  _getSortOptionName(option),
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.warmGold
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Tag filter
              if (_getAllTags().isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'Filter:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Clear filter option
                            GestureDetector(
                              onTap: () => _filterByTag(null),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _selectedTag == null
                                      ? AppColors.deepPurple.withValues(alpha: 0.2)
                                      : AppColors.glassBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _selectedTag == null
                                        ? AppColors.deepPurple
                                        : AppColors.glassBorder,
                                  ),
                                ),
                                child: Text(
                                  'All',
                                  style: TextStyle(
                                    color: _selectedTag == null
                                        ? AppColors.deepPurple
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Tag options
                            ..._getAllTags().map((tag) {
                              final isSelected = _selectedTag == tag;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => _filterByTag(tag),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.naturalGreen.withValues(alpha: 0.2)
                                          : AppColors.glassBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.naturalGreen
                                            : AppColors.glassBorder,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.naturalGreen
                                            : AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Memory cards
        Expanded(
          child: _memories.isEmpty
              ? GlassmorphicCard(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_stories,
                          color: AppColors.textTertiary,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No memories yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start capturing your moments to build your living autobiography',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _memories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: MemoryCard(
                        memory: _memories[index],
                        userStage: widget.userStage,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildImagesTab() {
    if (_isLoadingImages) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.warmGold,
        ),
      );
    }

    if (_generatedImages.isEmpty) {
      return GlassmorphicCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                color: AppColors.textTertiary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No generated images yet',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Visit chambers and generate scenes to see them here',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Gallery header
        GlassmorphicCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.image, color: AppColors.deepPurple),
              const SizedBox(width: 8),
              Text(
                '${_generatedImages.length} Generated Scene${_generatedImages.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _loadGeneratedImages,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.deepPurple,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
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
            itemCount: _generatedImages.length,
            itemBuilder: (context, index) {
              final image = _generatedImages[index];
              return _buildImageCard(image);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(Map<String, dynamic> image) {
    return GestureDetector(
      onTap: () => _showImageDetails(image),
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: image['url'],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.glassBg,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.warmGold,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.glassBg,
                  child: Center(
                    child: Icon(
                      Icons.error,
                      color: AppColors.anxiety,
                      size: 32,
                    ),
                  ),
                ),
              ),
              
              // Overlay with chamber type
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    image['chamber_type']?.toString().toUpperCase() ?? 'SCENE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Overlay with date
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatImageDate(image['cached_at']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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

  void _showImageDetails(Map<String, dynamic> image) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: AppColors.glassBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.deepPurple.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.image, color: AppColors.deepPurple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${image['chamber_type']?.toString().toUpperCase() ?? 'GENERATED'} Scene',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              
              // Image
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: image['url'],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: AppColors.warmGold,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: AppColors.anxiety, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Details
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (image['prompt'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generated from:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            image['prompt'],
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    Text(
                      'Created: ${_formatFullDate(image['cached_at'])}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatImageDate(DateTime date) {
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

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getSortOptionName(SortOption option) {
    switch (option) {
      case SortOption.chronological:
        return 'Time';
      case SortOption.emotional:
        return 'Emotion';
      case SortOption.tags:
        return 'Tags';
      case SortOption.sentiment:
        return 'Intensity';
    }
  }
}

class MemoryCard extends StatelessWidget {
  final MemoryEntry memory;
  final String? userStage;

  const MemoryCard({
    super.key,
    required this.memory,
    this.userStage,
  });

  @override
  Widget build(BuildContext context) {
    final emotionalColor = _getEmotionalColor(
      memory.emotionalState,
      memory.sentimentScore,
    );

    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with timestamp and emotional indicator
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: emotionalColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatTimestamp(memory.timestamp),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (memory.voiceNotePath != null)
                Icon(
                  Icons.mic,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Memory content
          Text(
            memory.content,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Tags and metadata
          if (memory.tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: memory.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTagColor(tag).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getTagColor(tag).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: _getTagColor(tag),
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          
          // Sentiment indicator
          if (memory.sentimentScore != null) ...[
            Row(
              children: [
                Icon(
                  memory.sentimentScore! > 0 
                      ? Icons.sentiment_satisfied
                      : memory.sentimentScore! < 0
                          ? Icons.sentiment_dissatisfied
                          : Icons.sentiment_neutral,
                  color: emotionalColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sentiment: ${(memory.sentimentScore! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getEmotionalColor(String? emotionalState, double? sentimentScore) {
    if (emotionalState != null) {
      switch (emotionalState.toLowerCase()) {
        case 'positive':
          return AppColors.naturalGreen;
        case 'negative':
          return AppColors.anxiety;
        default:
          return AppColors.calmBlue;
      }
    }
    
    if (sentimentScore != null) {
      if (sentimentScore > 0.3) return AppColors.naturalGreen;
      if (sentimentScore < -0.3) return AppColors.anxiety;
    }
    
    return AppColors.calmBlue;
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'anxiety':
        return AppColors.anxiety;
      case 'positive':
        return AppColors.naturalGreen;
      case 'sadness':
        return AppColors.calmBlue;
      case 'work':
        return AppColors.deepPurple;
      case 'family':
        return AppColors.warmGold;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}