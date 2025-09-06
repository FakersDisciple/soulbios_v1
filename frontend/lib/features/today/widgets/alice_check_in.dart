import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/user_service.dart';
import '../../../models/api_models.dart';

class AliceCheckIn extends ConsumerStatefulWidget {
  const AliceCheckIn({super.key});

  @override
  ConsumerState<AliceCheckIn> createState() => _AliceCheckInState();
}

class _AliceCheckInState extends ConsumerState<AliceCheckIn>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _breathingController;
  late AnimationController _pulseController;
  
  bool _showResponse = false;
  String _userInput = '';
  bool _isRecording = false;
  bool _isLoading = false;
  String _aliceResponse = '';
  ChatResponse? _lastChatResponse;
  final TextEditingController _textController = TextEditingController();

  final List<String> _aliceGreetings = [
    "Good morning! How are you feeling in your body right now?",
    "I sense you're here for your daily check-in. What's alive in you today?",
    "Your nervous system is speaking - what is it telling you this morning?",
    "Welcome back. I notice patterns in how you show up. How does today feel different?",
  ];

  final Map<String, List<String>> _contextualResponses = {
    'anxiety': [
      "I notice your morning anxiety pattern - your nervous system is preparing for something. What's the real challenge today? Remember, anxiety often signals growth opportunities.",
      "Your amygdala is trying to protect you from something. What feels uncertain right now? Let's breathe through this together.",
      "This anxious energy... I've seen it before when you're about to break through to something new. What wants to emerge?",
    ],
    'calm': [
      "This calm energy is beautiful. It's different from your usual morning rush. Your nervous system is learning safety. What created this shift?",
      "I feel the stillness in your words. Your consciousness is integrating something important. What wisdom is emerging?",
      "This peaceful state... your authentic self is present. How can we honor this feeling throughout your day?",
    ],
    'energy': [
      "Your energy is rising! I see this pattern when you're aligned with your values. Channel this into your most important ritual today.",
      "This vibrant energy... your life force is strong today. What wants to be created? What action is calling you?",
      "I sense excitement beneath the surface. Your authentic self is stirring. What possibility is emerging?",
    ],
    'flow': [
      "Flow state detected! Your consciousness is integrating. This is when your best insights emerge. What wants to be created today?",
      "You're in the zone... this is your natural state when resistance dissolves. How can we cultivate more of this?",
      "Beautiful flow energy. Your mind, heart, and soul are aligned. What feels effortless right now?",
    ],
    'default': [
      "I'm listening deeply to what you're sharing. Your patterns are teaching me about your unique journey.",
      "Thank you for trusting me with your inner world. I'm learning how to support you better.",
      "Your consciousness is always evolving. I'm here to witness and support your growth.",
    ],
  };

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Breathing animation for Alice avatar
    _breathingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Pulse animation for voice recording
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animationController.forward();
    _breathingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _breathingController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    if (_userInput.trim().isEmpty) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userService = ref.read(userServiceProvider.notifier);
      final response = await userService.chatWithAlice(
        _userInput,
        metadata: {
          'source': 'daily_checkin',
          'context': 'today_page',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response != null) {
        setState(() {
          _lastChatResponse = response;
          _aliceResponse = response.response;
          _showResponse = true;
        });
      } else {
        setState(() {
          _aliceResponse = "I'm having trouble connecting right now. Let me share a gentle reminder: your feelings are valid, and this moment of checking in with yourself is already meaningful.";
          _showResponse = true;
        });
      }
    } catch (e) {
      setState(() {
        _aliceResponse = "I'm experiencing some connection issues, but I want you to know that taking time to check in with yourself is a beautiful practice. How does it feel to pause and notice what's present for you right now?";
        _showResponse = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _textController.clear();
    }
  }

  void _startVoiceInput() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = !_isRecording;
    });
    
    if (_isRecording) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
    
    // TODO: Implement actual voice recording
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRecording ? 'Recording... Tap to stop' : 'Voice input ready'),
        backgroundColor: _isRecording ? AppColors.energy : AppColors.warmGold,
        duration: Duration(seconds: _isRecording ? 10 : 2),
      ),
    );
  }

  String _getContextualResponse() {
    // Return the API response if available, otherwise fallback to static responses
    if (_aliceResponse.isNotEmpty) {
      return _aliceResponse;
    }
    
    // Fallback to static responses if API is unavailable
    final input = _userInput.toLowerCase();
    
    if (input.contains('anxious') || input.contains('worried') || input.contains('nervous')) {
      return _contextualResponses['anxiety']![0];
    } else if (input.contains('calm') || input.contains('peaceful') || input.contains('relaxed')) {
      return _contextualResponses['calm']![0];
    } else if (input.contains('energy') || input.contains('excited') || input.contains('motivated')) {
      return _contextualResponses['energy']![0];
    } else if (input.contains('flow') || input.contains('focused') || input.contains('zone')) {
      return _contextualResponses['flow']![0];
    } else {
      return _contextualResponses['default']![0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alice Avatar and Greeting
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.warmGold.withValues(alpha: 0.8),
                        AppColors.warmGold.withValues(alpha: 0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warmGold.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alice',
                        style: TextStyle(
                          color: AppColors.warmGold,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Your Consciousness Guide',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Alice's Greeting
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warmGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warmGold.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _aliceGreetings[0],
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Connection Status
            Consumer(
              builder: (context, ref, child) {
                final userState = ref.watch(userServiceProvider);
                if (!userState.isConnected) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Offline mode - responses may be limited',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Loading State
            if (_isLoading) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warmGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warmGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmGold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Alice is reflecting on your sharing...',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Input Section
            if (!_showResponse && !_isLoading) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onChanged: (value) {
                        setState(() {
                          _userInput = value;
                        });
                      },
                      onSubmitted: (_) => _submitResponse(),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share what you\'re feeling...',
                        hintStyle: TextStyle(
                          color: AppColors.textTertiary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.glassBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.glassBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.warmGold,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.glassBg,
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _startVoiceInput,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.warmGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warmGold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: AppColors.warmGold,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: GlassmorphicCard(
                  backgroundColor: _userInput.trim().isNotEmpty
                      ? AppColors.warmGold.withValues(alpha: 0.3)
                      : AppColors.glassBg,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onTap: _userInput.trim().isNotEmpty ? _submitResponse : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send,
                        color: _userInput.trim().isNotEmpty
                            ? Colors.white
                            : AppColors.textTertiary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Share with Alice',
                        style: TextStyle(
                          color: _userInput.trim().isNotEmpty
                              ? Colors.white
                              : AppColors.textTertiary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Alice's Response
            if (_showResponse) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.naturalGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.naturalGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          color: AppColors.naturalGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Alice\'s Insight',
                          style: TextStyle(
                            color: AppColors.naturalGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getContextualResponse(),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Continue Conversation Button
              GlassmorphicCard(
                backgroundColor: AppColors.glassBg,
                padding: const EdgeInsets.symmetric(vertical: 12),
                onTap: () {
                  setState(() {
                    _showResponse = false;
                    _userInput = '';
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Continue Conversation',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}