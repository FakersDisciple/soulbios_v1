import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../core/theme/app_colors.dart';
import '../widgets/glassmorphic_card.dart';

class UserFeedbackSurvey extends StatefulWidget {
  final String context; // 'chamber_completion', 'app_launch', 'feature_use'
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const UserFeedbackSurvey({
    super.key,
    required this.context,
    this.onComplete,
    this.onSkip,
  });

  @override
  State<UserFeedbackSurvey> createState() => _UserFeedbackSurveyState();
}

class _UserFeedbackSurveyState extends State<UserFeedbackSurvey> {
  int _currentStep = 0;
  final Map<String, dynamic> _responses = {};
  
  // Survey questions based on context
  List<SurveyQuestion> get _questions {
    switch (widget.context) {
      case 'chamber_completion':
        return [
          SurveyQuestion(
            id: 'chamber_satisfaction',
            type: SurveyQuestionType.rating,
            question: 'How satisfied were you with this chamber experience?',
            options: ['1', '2', '3', '4', '5'],
            labels: ['Not satisfied', 'Very satisfied'],
          ),
          SurveyQuestion(
            id: 'chamber_insights',
            type: SurveyQuestionType.multipleChoice,
            question: 'Did you gain new insights about yourself?',
            options: ['Yes, significant insights', 'Some insights', 'A few insights', 'No new insights'],
          ),
          SurveyQuestion(
            id: 'chamber_difficulty',
            type: SurveyQuestionType.rating,
            question: 'How would you rate the difficulty level?',
            options: ['1', '2', '3', '4', '5'],
            labels: ['Too easy', 'Too difficult'],
          ),
          SurveyQuestion(
            id: 'chamber_feedback',
            type: SurveyQuestionType.openText,
            question: 'Any additional feedback about this chamber?',
            optional: true,
          ),
        ];
        
      case 'app_launch':
        return [
          SurveyQuestion(
            id: 'app_satisfaction',
            type: SurveyQuestionType.rating,
            question: 'How would you rate your overall experience with SoulBios?',
            options: ['1', '2', '3', '4', '5'],
            labels: ['Poor', 'Excellent'],
          ),
          SurveyQuestion(
            id: 'most_valuable_feature',
            type: SurveyQuestionType.multipleChoice,
            question: 'Which feature do you find most valuable?',
            options: [
              'Alice conversations',
              'Pattern recognition',
              'Memory timeline',
              'Chamber experiences',
              'Image generation',
            ],
          ),
          SurveyQuestion(
            id: 'recommendation',
            type: SurveyQuestionType.rating,
            question: 'How likely are you to recommend SoulBios to others?',
            options: ['1', '2', '3', '4', '5'],
            labels: ['Not likely', 'Very likely'],
          ),
          SurveyQuestion(
            id: 'improvement_suggestions',
            type: SurveyQuestionType.openText,
            question: 'What would you like to see improved?',
            optional: true,
          ),
        ];
        
      case 'feature_use':
      default:
        return [
          SurveyQuestion(
            id: 'feature_usefulness',
            type: SurveyQuestionType.rating,
            question: 'How useful was this feature?',
            options: ['1', '2', '3', '4', '5'],
            labels: ['Not useful', 'Very useful'],
          ),
          SurveyQuestion(
            id: 'feature_ease',
            type: SurveyQuestionType.rating,
            question: 'How easy was it to use?',
            options: ['1', '2', '3', '4', '5'],
            labels: ['Very difficult', 'Very easy'],
          ),
          SurveyQuestion(
            id: 'feature_feedback',
            type: SurveyQuestionType.openText,
            question: 'Any suggestions for improvement?',
            optional: true,
          ),
        ];
    }
  }

  void _nextStep() {
    if (_currentStep < _questions.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeSurvey();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _completeSurvey() async {
    // Log survey completion to Firebase Analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'survey_completed',
      parameters: {
        'survey_context': widget.context,
        'total_questions': _questions.length,
        'completion_rate': 1.0,
        ...Map.fromEntries(
          _responses.entries.map((e) => MapEntry('response_${e.key}', e.value.toString())),
        ),
      },
    );

    // Store responses locally for analysis
    await _storeFeedbackLocally();

    widget.onComplete?.call();
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _skipSurvey() async {
    // Log survey skip to Firebase Analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'survey_skipped',
      parameters: {
        'survey_context': widget.context,
        'step_reached': _currentStep,
        'completion_rate': _currentStep / _questions.length,
      },
    );

    widget.onSkip?.call();
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _storeFeedbackLocally() async {
    // Store feedback in Hive for later analysis
    try {
      // This would integrate with your existing Hive storage
      final feedbackData = {
        'context': widget.context,
        'timestamp': DateTime.now().toIso8601String(),
        'responses': _responses,
      };
      
      // Store in local database for offline analysis
      // await Hive.box('user_feedback').add(feedbackData);
    } catch (e) {
      debugPrint('Failed to store feedback locally: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentStep];
    final progress = (_currentStep + 1) / _questions.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Feedback',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _skipSurvey,
                  icon: Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress indicator
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmGold),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Question ${_currentStep + 1} of ${_questions.length}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Question
            Text(
              question.question,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Answer options
            _buildAnswerWidget(question),
            
            const SizedBox(height: 24),
            
            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _previousStep,
                    child: Text(
                      'Previous',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  const SizedBox(),
                
                Row(
                  children: [
                    if (question.optional)
                      TextButton(
                        onPressed: _nextStep,
                        child: Text(
                          'Skip',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    
                    const SizedBox(width: 8),
                    
                    ElevatedButton(
                      onPressed: _canProceed(question) ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warmGold,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _currentStep == _questions.length - 1 ? 'Complete' : 'Next',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerWidget(SurveyQuestion question) {
    switch (question.type) {
      case SurveyQuestionType.rating:
        return _buildRatingWidget(question);
      case SurveyQuestionType.multipleChoice:
        return _buildMultipleChoiceWidget(question);
      case SurveyQuestionType.openText:
        return _buildOpenTextWidget(question);
    }
  }

  Widget _buildRatingWidget(SurveyQuestion question) {
    return Column(
      children: [
        if (question.labels != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                question.labels![0],
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                question.labels![1],
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        
        const SizedBox(height: 8),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: question.options.map((option) {
            final isSelected = _responses[question.id] == option;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _responses[question.id] = option;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.warmGold : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.warmGold : AppColors.textSecondary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultipleChoiceWidget(SurveyQuestion question) {
    return Column(
      children: question.options.map((option) {
        final isSelected = _responses[question.id] == option;
        return GestureDetector(
          onTap: () {
            setState(() {
              _responses[question.id] = option;
            });
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.warmGold.withValues(alpha: 0.2) : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.warmGold : AppColors.textSecondary.withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? AppColors.warmGold : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOpenTextWidget(SurveyQuestion question) {
    return TextField(
      onChanged: (value) {
        _responses[question.id] = value;
      },
      maxLines: 3,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Your feedback...',
        hintStyle: TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.warmGold),
        ),
      ),
    );
  }

  bool _canProceed(SurveyQuestion question) {
    if (question.optional) return true;
    return _responses.containsKey(question.id) && 
           _responses[question.id] != null && 
           _responses[question.id].toString().isNotEmpty;
  }
}

class SurveyQuestion {
  final String id;
  final SurveyQuestionType type;
  final String question;
  final List<String> options;
  final List<String>? labels;
  final bool optional;

  SurveyQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.options = const [],
    this.labels,
    this.optional = false,
  });
}

enum SurveyQuestionType {
  rating,
  multipleChoice,
  openText,
}

// Helper class to show surveys at appropriate times
class SurveyTrigger {
  static bool _shouldShowSurvey(String context) {
    // Simple logic to avoid survey fatigue
    // In production, this would be more sophisticated
    final now = DateTime.now();
    final lastSurvey = DateTime.now().subtract(const Duration(days: 7)); // Example
    
    return now.difference(lastSurvey).inDays >= 7;
  }

  static void showChamberCompletionSurvey(BuildContext context) {
    if (_shouldShowSurvey('chamber_completion')) {
      showDialog(
        context: context,
        builder: (context) => UserFeedbackSurvey(
          context: 'chamber_completion',
          onComplete: () {
            // Handle completion
          },
        ),
      );
    }
  }

  static void showAppLaunchSurvey(BuildContext context) {
    if (_shouldShowSurvey('app_launch')) {
      // Show after a delay to not interrupt app launch
      Future.delayed(const Duration(seconds: 5), () {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => UserFeedbackSurvey(
              context: 'app_launch',
              onComplete: () {
                // Handle completion
              },
            ),
          );
        }
      });
    }
  }

  static void showFeatureUseSurvey(BuildContext context, String feature) {
    if (_shouldShowSurvey('feature_use_$feature')) {
      showDialog(
        context: context,
        builder: (context) => UserFeedbackSurvey(
          context: 'feature_use',
          onComplete: () {
            // Handle completion
          },
        ),
      );
    }
  }
}