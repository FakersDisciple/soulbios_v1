import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../core/theme/app_colors.dart';

class MomentCapture extends ConsumerStatefulWidget {
  const MomentCapture({super.key});

  @override
  ConsumerState<MomentCapture> createState() => _MomentCaptureState();
}

class _MomentCaptureState extends ConsumerState<MomentCapture> {
  final TextEditingController _controller = TextEditingController();
  bool _isRecording = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _captureVoiceNote() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = !_isRecording;
    });
    
    // Simple placeholder for voice recording
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRecording ? 'Recording...' : 'Voice capture coming soon!'),
        backgroundColor: AppColors.softTeal,
      ),
    );
  }

  void _saveMoment() {
    if (_controller.text.trim().isEmpty) return;
    
    HapticFeedback.lightImpact();
    
    // Simple placeholder for ChromaDB save
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Moment captured! Alice is learning from your insights.'),
        backgroundColor: AppColors.naturalGreen,
      ),
    );
    
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.softTeal,
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
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Quick insights, feelings, or observations that Alice can learn from',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Text Input
          TextField(
            controller: _controller,
            maxLines: 4,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'What are you noticing right now? Any insights or patterns?',
              hintStyle: TextStyle(
                color: AppColors.textTertiary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.glassBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.glassBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.softTeal,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.glassBg,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              // Voice Note Button
              Expanded(
                child: GlassmorphicCard(
                  backgroundColor: _isRecording
                      ? AppColors.energy.withValues(alpha: 0.2)
                      : AppColors.glassBg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onTap: _captureVoiceNote,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: _isRecording ? AppColors.energy : AppColors.softTeal,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRecording ? 'Stop' : 'Voice Note',
                        style: TextStyle(
                          color: _isRecording ? AppColors.energy : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Save Button
              Expanded(
                child: GlassmorphicCard(
                  backgroundColor: _controller.text.trim().isNotEmpty
                      ? AppColors.naturalGreen.withValues(alpha: 0.2)
                      : AppColors.glassBg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onTap: _controller.text.trim().isNotEmpty ? _saveMoment : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.save,
                        color: _controller.text.trim().isNotEmpty
                            ? AppColors.naturalGreen
                            : AppColors.textTertiary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Save Moment',
                        style: TextStyle(
                          color: _controller.text.trim().isNotEmpty
                              ? AppColors.naturalGreen
                              : AppColors.textTertiary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // AI Processing Hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.deepPurple.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.deepPurple,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alice analyzes your moments to recognize patterns and provide personalized insights',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}