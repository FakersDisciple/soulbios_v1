import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:hive/hive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/api_models.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../widgets/animated_loading_widget.dart';
import '../../../widgets/enhanced_error_dialog.dart';
import '../../../services/user_service.dart';
import 'data_pathway_visualizer.dart';

class EnhancedMemoryCapture extends ConsumerStatefulWidget {
  final String? userStage;
  final VoidCallback? onMemorySaved;

  const EnhancedMemoryCapture({
    super.key,
    this.userStage,
    this.onMemorySaved,
  });

  @override
  ConsumerState<EnhancedMemoryCapture> createState() => _EnhancedMemoryCaptureState();
}

class _EnhancedMemoryCaptureState extends ConsumerState<EnhancedMemoryCapture>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  
  late AnimationController _breathingController;
  late AnimationController _saveController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _saveAnimation;
  
  bool _isListening = false;
  bool _isSaving = false;
  bool _speechEnabled = false;
  // Health integration disabled for now
  // bool _healthEnabled = false;
  String _lastWords = '';
  Map<String, dynamic>? _healthData;
  List<DataDestination> _currentDestinations = [];
  bool _showPathways = false;

  @override
  void initState() {
    super.initState();
    
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _saveController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _breathingAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    _saveAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _saveController,
      curve: Curves.easeInOut,
    ));

    _initializeSpeech();
  }

  @override
  void dispose() {
    _textController.dispose();
    _breathingController.dispose();
    _saveController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          setState(() {
            _isListening = status == 'listening';
          });
        },
        onError: (error) {
          setState(() {
            _isListening = false;
          });
        },
      );
    } catch (e) {
      _speechEnabled = false;
    }
  }

  // Health integration disabled for now - can be enabled later
  // Future<void> _initializeHealth() async {
  //   // Health integration implementation
  // }

  // Health suggestion method disabled for now
  // void _suggestBasedOnHealth() { ... }

  void _startListening() async {
    if (!_speechEnabled || _isListening) return;
    
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            _textController.text += (_textController.text.isEmpty ? '' : ' ') + _lastWords;
          }
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
  }

  Future<void> _saveMemory() async {
    if (_textController.text.trim().isEmpty || _isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    _saveController.forward().then((_) => _saveController.reverse());
    
    try {
      // Create memory entry
      final memory = MemoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _textController.text.trim(),
        timestamp: DateTime.now(),
        metadata: {
          'user_stage': widget.userStage ?? 'unknown',
          'health_data': _healthData,
          'voice_input': _lastWords.isNotEmpty,
        },
        tags: _extractTags(_textController.text),
        sentimentScore: _analyzeSentiment(_textController.text),
        emotionalState: _detectEmotionalState(_textController.text),
      );
      
      // Save to local storage
      final memoriesBox = Hive.box('memories');
      await memoriesBox.put(memory.id, memory.toJson());
      
      // Send to backend for analysis
      final userService = ref.read(userServiceProvider.notifier);
      final response = await userService.analyzePatterns(
        memory.content,
        metadata: memory.metadata,
      );
      
      if (response != null) {
        // Generate data destinations based on analysis
        _currentDestinations = _generateDestinations(response);
        
        setState(() {
          _showPathways = true;
        });
        
        // Clear form after successful save
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _textController.clear();
              _lastWords = '';
              _showPathways = false;
            });
          }
        });
      }
      
      widget.onMemorySaved?.call();
      
    } catch (e) {
      // Handle save error - use mounted check for async context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save memory: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  List<String> _extractTags(String content) {
    // Simple tag extraction based on keywords
    final tags = <String>[];
    final lowerContent = content.toLowerCase();
    
    if (lowerContent.contains(RegExp(r'\b(anxious|worry|stress|nervous)\b'))) {
      tags.add('anxiety');
    }
    if (lowerContent.contains(RegExp(r'\b(happy|joy|excited|grateful)\b'))) {
      tags.add('positive');
    }
    if (lowerContent.contains(RegExp(r'\b(sad|down|depressed|low)\b'))) {
      tags.add('sadness');
    }
    if (lowerContent.contains(RegExp(r'\b(work|job|career|office)\b'))) {
      tags.add('work');
    }
    if (lowerContent.contains(RegExp(r'\b(family|parent|child|sibling)\b'))) {
      tags.add('family');
    }
    
    return tags;
  }

  double _analyzeSentiment(String content) {
    // Simple sentiment analysis
    final positiveWords = ['happy', 'joy', 'love', 'great', 'amazing', 'wonderful', 'grateful'];
    final negativeWords = ['sad', 'angry', 'hate', 'terrible', 'awful', 'worried', 'anxious'];
    
    final lowerContent = content.toLowerCase();
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in positiveWords) {
      if (lowerContent.contains(word)) positiveCount++;
    }
    
    for (final word in negativeWords) {
      if (lowerContent.contains(word)) negativeCount++;
    }
    
    final totalWords = content.split(' ').length;
    final sentimentScore = (positiveCount - negativeCount) / totalWords.clamp(1, double.infinity);
    
    return sentimentScore.clamp(-1.0, 1.0);
  }

  String _detectEmotionalState(String content) {
    final sentiment = _analyzeSentiment(content);
    
    if (sentiment > 0.3) return 'positive';
    if (sentiment < -0.3) return 'negative';
    return 'neutral';
  }

  List<DataDestination> _generateDestinations(PatternAnalysisResponse analysis) {
    final destinations = <DataDestination>[];
    
    // Add destinations based on analysis results
    if (analysis.consciousnessIndicators.isNotEmpty) {
      destinations.add(DataDestination(
        iconPath: 'speech_bubble',
        description: 'Fuels Alice conversations',
        type: 'alice_chat',
        color: AppColors.deepPurple,
      ));
    }
    
    if (analysis.hierarchicalActivations.isNotEmpty) {
      destinations.add(DataDestination(
        iconPath: 'pattern',
        description: 'Builds pattern recognition',
        type: 'pattern_analysis',
        color: AppColors.warmGold,
      ));
    }
    
    destinations.add(DataDestination(
      iconPath: 'memory',
      description: 'Strengthens memory foundation',
      type: 'memory_storage',
      color: AppColors.naturalGreen,
    ));
    
    return destinations;
  }

  String _getStagePrompt() {
    switch (widget.userStage?.toLowerCase()) {
      case 'beginner':
        return 'What happened today? How did it make you feel?';
      case 'explorer':
        return 'What patterns are you noticing in your experiences?';
      case 'integrator':
        return 'How does this connect to your deeper understanding?';
      default:
        return 'What happened? How did it feel? What did you learn?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GlassmorphicCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: AppColors.warmGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Capture This Moment',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_healthData != null)
                    Icon(
                      Icons.favorite,
                      color: AppColors.naturalGreen,
                      size: 16,
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Adaptive input field with breathing animation
              AnimatedBuilder(
                animation: _breathingAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathingAnimation.value,
                    child: TextField(
                      controller: _textController,
                      maxLines: 4,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _getStagePrompt(),
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.glassBorder),
                        ),
                        filled: true,
                        fillColor: AppColors.glassBg,
                        suffixIcon: _isListening
                            ? Icon(Icons.mic, color: AppColors.warmGold)
                            : null,
                      ),
                    ),
                  );
                },
              ),
              
              if (_isListening) ...[
                const SizedBox(height: 8),
                Text(
                  'Listening... $_lastWords',
                  style: TextStyle(
                    color: AppColors.warmGold,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Input controls
              Row(
                children: [
                  // Voice input button
                  Expanded(
                    child: GlassmorphicCard(
                      backgroundColor: _isListening 
                          ? AppColors.warmGold.withValues(alpha: 0.2)
                          : AppColors.glassBg,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onTap: _speechEnabled 
                          ? (_isListening ? _stopListening : _startListening)
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            color: _speechEnabled 
                                ? (_isListening ? AppColors.warmGold : AppColors.textSecondary)
                                : AppColors.textTertiary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isListening ? 'Stop' : 'Voice Note',
                            style: TextStyle(
                              color: _speechEnabled 
                                  ? (_isListening ? AppColors.warmGold : AppColors.textSecondary)
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Save button
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _saveAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _saveAnimation.value,
                          child: GlassmorphicCard(
                            backgroundColor: AppColors.naturalGreen.withValues(alpha: 0.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onTap: _isSaving ? null : _saveMemory,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isSaving)
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: AppColors.naturalGreen,
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.save,
                                    color: AppColors.naturalGreen,
                                    size: 18,
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  _isSaving ? 'Saving...' : 'Save Memory',
                                  style: TextStyle(
                                    color: AppColors.naturalGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              // Health data indicator
              if (_healthData != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.naturalGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.naturalGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: AppColors.naturalGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Health data integrated for personalized prompts',
                          style: TextStyle(
                            color: AppColors.naturalGreen,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Data pathway visualization overlay
        if (_showPathways && _currentDestinations.isNotEmpty)
          Positioned.fill(
            child: DataPathwayVisualizer(
              destinations: _currentDestinations,
              onAnimationComplete: () {
                setState(() {
                  _showPathways = false;
                });
              },
            ),
          ),
      ],
    );
  }
}