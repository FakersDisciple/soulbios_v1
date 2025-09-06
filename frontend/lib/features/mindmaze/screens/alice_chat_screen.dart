import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/user_service.dart';
import 'lifebook_upload_screen.dart';

class AliceChatScreen extends ConsumerStatefulWidget {
  const AliceChatScreen({super.key});

  @override
  ConsumerState<AliceChatScreen> createState() => _AliceChatScreenState();
}

class _AliceChatScreenState extends ConsumerState<AliceChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Chat with Alice', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.amber),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
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
          if (userState.isConnected)
            const Icon(Icons.cloud_done, color: Colors.green)
          else
            const Icon(Icons.cloud_off, color: Colors.red),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          if (!userState.isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withValues(alpha: 0.2),
              child: Text(
                'Offline Mode - ${userState.error ?? "Connection failed"}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
                  SizedBox(width: 12),
                  Text('Alice is thinking...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              border: Border(top: BorderSide(color: Colors.amber, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask Alice anything...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.amber),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  backgroundColor: Colors.amber,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.black),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: message.isError ? Colors.red : Colors.amber,
              radius: 16,
              child: Icon(
                message.isError ? Icons.error : Icons.psychology,
                color: Colors.black,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? Colors.amber.withValues(alpha: 0.2)
                    : message.isError
                        ? Colors.red.withValues(alpha: 0.2)
                        : const Color(0xFF2D2D4A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: message.isUser 
                      ? Colors.amber.withValues(alpha: 0.5)
                      : message.isError
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (!message.isUser && !message.isError) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (message.alicePersona != null)
                          _buildTag('Persona: ${message.alicePersona}', Colors.blue),
                        if (message.consciousnessLevel != null)
                          _buildTag('Level: ${message.consciousnessLevel}', Colors.purple),
                        if (message.wisdomDepth != null)
                          _buildTag('Wisdom: ${message.wisdomDepth}/10', Colors.orange),
                        if (message.breakthroughPotential != null)
                          _buildTag('Breakthrough: ${(message.breakthroughPotential! * 100).round()}%', Colors.green),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.amber,
              radius: 16,
              child: Icon(Icons.person, color: Colors.black, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10),
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