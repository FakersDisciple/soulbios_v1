import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../services/user_service.dart';
import '../../mindmaze/screens/lifebook_upload_screen.dart';

class AliceChatWidget extends ConsumerStatefulWidget {
  const AliceChatWidget({super.key});

  @override
  ConsumerState<AliceChatWidget> createState() => _AliceChatWidgetState();
}

class _AliceChatWidgetState extends ConsumerState<AliceChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isExpanded = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
          text: "Error: ${e.toString()}",
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

    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.deepPurple,
                      AppColors.warmGold,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat with Alice',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Your conscious living companion',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.upload_file,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LifebookUploadScreen(),
                        ),
                      );
                    },
                    tooltip: 'Upload Life Book',
                  ),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),

          // Connection status
          if (!userState.isConnected) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline Mode - ${userState.error ?? "Connection failed"}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Chat messages (only show if expanded or if there are messages)
          if (_isExpanded || _messages.isNotEmpty) ...[
            Container(
              height: _isExpanded ? 300 : 150,
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology,
                            color: AppColors.textTertiary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation with Alice',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
            ),

            const SizedBox(height: 12),

            // Loading indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.warmGold,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alice is thinking...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // Input area
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ask Alice about your journey...',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.warmGold),
                    ),
                    filled: true,
                    fillColor: AppColors.glassBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 2,
                  minLines: 1,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.deepPurple,
                      AppColors.warmGold,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: message.isError 
                    ? LinearGradient(colors: [Colors.red, Colors.red])
                    : LinearGradient(
                        colors: [AppColors.deepPurple, AppColors.warmGold],
                      ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.isError ? Icons.error : Icons.psychology,
                color: Colors.white,
                size: 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? AppColors.warmGold.withValues(alpha: 0.2)
                    : message.isError
                        ? Colors.red.withValues(alpha: 0.2)
                        : AppColors.deepPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: message.isUser 
                      ? AppColors.warmGold.withValues(alpha: 0.5)
                      : message.isError
                          ? Colors.red.withValues(alpha: 0.5)
                          : AppColors.deepPurple.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  if (!message.isUser && !message.isError && message.alicePersona != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Persona: ${message.alicePersona}',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.warmGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 12),
            ),
          ],
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