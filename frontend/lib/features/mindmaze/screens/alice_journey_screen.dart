import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/user_service.dart';

class AliceJourneyScreen extends ConsumerStatefulWidget {
  const AliceJourneyScreen({super.key});

  @override
  ConsumerState<AliceJourneyScreen> createState() => _AliceJourneyScreenState();
}

class _AliceJourneyScreenState extends ConsumerState<AliceJourneyScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  late AnimationController _breathingController;
  late AnimationController _particleController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();

    // Breathing animation for ambient effect
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    _breathingController.repeat(reverse: true);

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _particleController.repeat();

    // Add welcome message
    _messages.add(ChatMessage(
      text:
          "Welcome to your inner journey. I'm Alice, your consciousness guide. What's on your mind today?",
      isUser: false,
      timestamp: DateTime.now(),
      alicePersona: "Gentle Guide",
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _breathingController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final userService = ref.read(userServiceProvider.notifier);
      final response = await userService.chatWithAlice(message);

      if (response != null) {
        setState(() {
          _messages.add(ChatMessage(
            text: response.response,
            isUser: false,
            timestamp: DateTime.now(),
            alicePersona: response.alicePersona,
            consciousnessLevel: response.consciousnessLevel,
            wisdomDepth: response.wisdomDepth,
            breakthroughPotential: response.breakthroughPotential,
          ));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: "I'm having trouble connecting right now. Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Connection error. Please check your internet and try again.",
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userServiceProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(userState),

                // Messages
                Expanded(
                  child: _buildMessagesList(),
                ),

                // Input area
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A1A),
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Breathing orbs
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Positioned(
                top: 100,
                right: 50,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber
                            .withValues(alpha: _breathingAnimation.value * 0.3),
                        Colors.amber
                            .withValues(alpha: _breathingAnimation.value * 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Second breathing orb
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: 200,
                left: 30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.withValues(
                            alpha: (1 - _breathingAnimation.value) * 0.4),
                        Colors.purple.withValues(
                            alpha: (1 - _breathingAnimation.value) * 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_particleController.value),
                size: Size.infinite,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserState userState) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Journey with Alice',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userState.isConnected
                      ? 'Connected • Consciousness Guide Active'
                      : 'Offline • Reconnecting...',
                  style: TextStyle(
                    color: userState.isConnected ? Colors.green : Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.amber,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _isLoading) {
            return _buildTypingIndicator();
          }
          return _buildMessageBubble(_messages[index]);
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.amber,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D4A).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Alice is reflecting',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.amber.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: message.isError
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: message.isError
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                message.isError ? Icons.error : Icons.psychology,
                color: message.isError ? Colors.red : Colors.amber,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.amber.withValues(alpha: 0.15)
                    : message.isError
                        ? Colors.red.withValues(alpha: 0.15)
                        : const Color(0xFF2D2D4A).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: message.isUser
                      ? Colors.amber.withValues(alpha: 0.3)
                      : message.isError
                          ? Colors.red.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  if (!message.isUser &&
                      !message.isError &&
                      message.alicePersona != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${message.alicePersona}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.amber,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: Colors.amber.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D4A).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts with Alice...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber, Colors.amber.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: _isLoading ? null : _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    _isLoading ? Icons.hourglass_empty : Icons.send,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? alicePersona;
  final String? consciousnessLevel;
  final int? wisdomDepth;
  final double? breakthroughPotential;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.alicePersona,
    this.consciousnessLevel,
    this.wisdomDepth,
    this.breakthroughPotential,
    this.isError = false,
  });
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width * 0.1 + (i * 37) % size.width.toInt()) % size.width;
      final y = (size.height * 0.2 +
              (animationValue * size.height * 2 + i * 43) %
                  size.height.toInt()) %
          size.height;

      final opacity =
          (0.1 + (i % 3) * 0.05) * (0.5 + 0.5 * (animationValue + i * 0.1) % 1);
      paint.color = Colors.white.withValues(alpha: opacity);

      canvas.drawCircle(
        Offset(x, y),
        1.0 + (i % 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
