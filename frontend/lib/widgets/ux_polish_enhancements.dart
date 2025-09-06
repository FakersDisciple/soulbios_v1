import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import 'animated_loading_widget.dart';
import 'enhanced_error_dialog.dart';

/// A collection of UX polish enhancements for the SoulBios app
class UXPolishEnhancements {
  
  /// Shows a success feedback with haptic feedback and visual confirmation
  static void showSuccessFeedback(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.naturalGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.glassBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.naturalGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows an error with user-friendly message and retry option
  static void showUserFriendlyError(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    ErrorType type = ErrorType.general,
  }) {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => EnhancedErrorDialog(
        type: type,
        title: title,
        message: message,
        onRetry: onRetry,
        retryText: onRetry != null ? 'Try Again' : null,
      ),
    );
  }

  /// Shows image generation failure with specific messaging
  static void showImageGenerationError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showUserFriendlyError(
      context,
      title: 'Image Generation Failed',
      message: 'Unable to generate your scene right now. This might be due to high demand or a temporary issue. Would you like to try again?',
      onRetry: onRetry,
      type: ErrorType.imageGeneration,
    );
  }

  /// Shows network error with retry option
  static void showNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showUserFriendlyError(
      context,
      title: 'Connection Issue',
      message: 'Unable to connect to the server. Please check your internet connection and try again.',
      onRetry: onRetry,
      type: ErrorType.network,
    );
  }

  /// Shows pattern analysis error
  static void showPatternAnalysisError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showUserFriendlyError(
      context,
      title: 'Analysis Unavailable',
      message: 'Unable to analyze your patterns right now. Your data is safe, and we\'ll try again shortly.',
      onRetry: onRetry,
      type: ErrorType.patternAnalysis,
    );
  }
}

/// Enhanced button with loading state and haptic feedback
class EnhancedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const EnhancedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isLoading || widget.onPressed == null) return;

    HapticFeedback.lightImpact();
    _controller.forward().then((_) {
      _controller.reverse();
    });
    
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : _handleTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor ?? AppColors.deepPurple,
              foregroundColor: widget.foregroundColor ?? Colors.white,
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(25),
              ),
              elevation: widget.isLoading ? 0 : 4,
            ),
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.foregroundColor ?? Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon),
                        const SizedBox(width: 8),
                      ],
                      Text(widget.text),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Smooth page transition animations
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;

  SmoothPageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

/// Loading state manager for API calls
class LoadingStateManager extends ChangeNotifier {
  final Map<String, bool> _loadingStates = {};
  final Map<String, String?> _errorMessages = {};

  bool isLoading(String key) => _loadingStates[key] ?? false;
  String? getError(String key) => _errorMessages[key];

  void setLoading(String key, bool loading) {
    _loadingStates[key] = loading;
    if (loading) {
      _errorMessages[key] = null;
    }
    notifyListeners();
  }

  void setError(String key, String error) {
    _loadingStates[key] = false;
    _errorMessages[key] = error;
    notifyListeners();
  }

  void clearError(String key) {
    _errorMessages[key] = null;
    notifyListeners();
  }

  void clear(String key) {
    _loadingStates.remove(key);
    _errorMessages.remove(key);
    notifyListeners();
  }
}

/// Animated list item for smooth list transitions
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Stagger the animation based on index
    Future.delayed(
      Duration(milliseconds: widget.index * widget.delay.inMilliseconds),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Utility class for consistent animations throughout the app
class AnimationUtils {
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOut;

  /// Creates a smooth scale transition
  static Widget scaleTransition({
    required Animation<double> animation,
    required Widget child,
    double begin = 0.8,
    double end = 1.0,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: begin, end: end).animate(
        CurvedAnimation(parent: animation, curve: defaultCurve),
      ),
      child: child,
    );
  }

  /// Creates a smooth fade transition
  static Widget fadeTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Creates a smooth slide transition
  static Widget slideTransition({
    required Animation<double> animation,
    required Widget child,
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: end).animate(
        CurvedAnimation(parent: animation, curve: defaultCurve),
      ),
      child: child,
    );
  }
}