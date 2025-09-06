import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum ErrorType {
  network,
  imageGeneration,
  patternAnalysis,
  authentication,
  subscription,
  general,
}

class EnhancedErrorDialog extends StatefulWidget {
  final ErrorType type;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final String? retryText;
  final String? cancelText;
  final bool showAnimation;

  const EnhancedErrorDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.onRetry,
    this.onCancel,
    this.retryText,
    this.cancelText,
    this.showAnimation = true,
  });

  @override
  State<EnhancedErrorDialog> createState() => _EnhancedErrorDialogState();
}

class _EnhancedErrorDialogState extends State<EnhancedErrorDialog>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));

    if (widget.showAnimation) {
      _shakeController.forward();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            widget.showAnimation ? _shakeAnimation.value * 10 * (1 - _shakeAnimation.value) : 0,
            0,
          ),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getErrorColor().withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getErrorColor().withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Error icon/animation
                    _buildErrorIcon(),
                    
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Message
                    Text(
                      widget.message,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorIcon() {
    switch (widget.type) {
      case ErrorType.network:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.anxiety.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.wifi_off,
            size: 40,
            color: AppColors.anxiety,
          ),
        );
        
      case ErrorType.imageGeneration:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.anxiety.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.image_not_supported,
            size: 40,
            color: AppColors.anxiety,
          ),
        );
        
      case ErrorType.patternAnalysis:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.anxiety.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.analytics_outlined,
            size: 40,
            color: AppColors.anxiety,
          ),
        );
        
      case ErrorType.authentication:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.anxiety.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_outline,
            size: 40,
            color: AppColors.anxiety,
          ),
        );
        
      case ErrorType.subscription:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.warmGold.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.diamond_outlined,
            size: 40,
            color: AppColors.warmGold,
          ),
        );
        
      case ErrorType.general:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.anxiety.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            size: 40,
            color: AppColors.anxiety,
          ),
        );
    }
  }

  Widget _buildActionButtons() {
    final hasRetry = widget.onRetry != null;
    final hasCancel = widget.onCancel != null;
    
    if (!hasRetry && !hasCancel) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text('OK'),
        ),
      );
    }
    
    return Row(
      children: [
        if (hasCancel) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onCancel?.call();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.textSecondary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(widget.cancelText ?? 'Cancel'),
            ),
          ),
          if (hasRetry) const SizedBox(width: 12),
        ],
        
        if (hasRetry)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onRetry?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getErrorColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(widget.retryText ?? 'Retry'),
            ),
          ),
      ],
    );
  }

  Color _getErrorColor() {
    switch (widget.type) {
      case ErrorType.subscription:
        return AppColors.warmGold;
      case ErrorType.network:
      case ErrorType.imageGeneration:
      case ErrorType.patternAnalysis:
      case ErrorType.authentication:
      case ErrorType.general:
        return AppColors.anxiety;
    }
  }
}

// Convenience methods for showing different types of errors
class ErrorDialogHelper {
  static void showNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => EnhancedErrorDialog(
        type: ErrorType.network,
        title: 'Connection Issue',
        message: 'Unable to connect to the server. Please check your internet connection and try again.',
        onRetry: onRetry,
        retryText: 'Try Again',
      ),
    );
  }

  static void showImageGenerationError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => EnhancedErrorDialog(
        type: ErrorType.imageGeneration,
        title: 'Image Generation Failed',
        message: customMessage ?? 'Unable to generate your scene. This might be due to high demand or a temporary issue.',
        onRetry: onRetry,
        retryText: 'Try Again',
        cancelText: 'Maybe Later',
        onCancel: () {},
      ),
    );
  }

  static void showPatternAnalysisError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => EnhancedErrorDialog(
        type: ErrorType.patternAnalysis,
        title: 'Analysis Unavailable',
        message: 'Unable to analyze your patterns right now. Your data is safe, and we\'ll try again shortly.',
        onRetry: onRetry,
        retryText: 'Retry Analysis',
      ),
    );
  }

  static void showSubscriptionError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => EnhancedErrorDialog(
        type: ErrorType.subscription,
        title: 'Subscription Issue',
        message: customMessage ?? 'There was an issue with your subscription. Please try again or contact support.',
        onRetry: onRetry,
        retryText: 'Try Again',
        cancelText: 'Contact Support',
        onCancel: () {
          // Open support contact - could integrate with email or support system
        },
      ),
    );
  }

  static void showGeneralError(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => EnhancedErrorDialog(
        type: ErrorType.general,
        title: title ?? 'Something Went Wrong',
        message: message ?? 'An unexpected error occurred. Please try again.',
        onRetry: onRetry,
        retryText: 'Try Again',
      ),
    );
  }
}