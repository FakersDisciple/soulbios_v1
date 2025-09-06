import 'package:flutter/material.dart';
import 'animated_loading_widget.dart';
import '../core/theme/app_colors.dart';

class EnhancedLoadingOverlay extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final LoadingType loadingType;
  final String? loadingMessage;
  final Duration timeout;
  final VoidCallback? onTimeout;
  final bool showProgress;
  final double? progress;

  const EnhancedLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingType = LoadingType.general,
    this.loadingMessage,
    this.timeout = const Duration(seconds: 30),
    this.onTimeout,
    this.showProgress = false,
    this.progress,
  });

  @override
  State<EnhancedLoadingOverlay> createState() => _EnhancedLoadingOverlayState();
}

class _EnhancedLoadingOverlayState extends State<EnhancedLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _overlayController;
  late Animation<double> _overlayAnimation;
  
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOut,
    ));

    if (widget.isLoading) {
      _overlayController.forward();
      _startTimeout();
    }
  }

  @override
  void didUpdateWidget(EnhancedLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _overlayController.forward();
        _startTimeout();
      } else {
        _overlayController.reverse();
        _hasTimedOut = false;
      }
    }
  }

  void _startTimeout() {
    Future.delayed(widget.timeout, () {
      if (mounted && widget.isLoading && !_hasTimedOut) {
        setState(() {
          _hasTimedOut = true;
        });
        widget.onTimeout?.call();
      }
    });
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          AnimatedBuilder(
            animation: _overlayAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _overlayAnimation.value,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: AppColors.glassBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.deepPurple.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_hasTimedOut) ...[
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 48,
                              color: AppColors.warmGold,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Taking longer than expected',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This might be due to high demand. Please wait a bit longer or try again.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            AnimatedLoadingWidget(
                              type: widget.loadingType,
                              message: widget.loadingMessage,
                              size: 80,
                            ),
                            if (widget.showProgress && widget.progress != null) ...[
                              const SizedBox(height: 20),
                              LinearProgressIndicator(
                                value: widget.progress,
                                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getProgressColor(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(widget.progress! * 100).toInt()}%',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Color _getProgressColor() {
    switch (widget.loadingType) {
      case LoadingType.imageGeneration:
        return AppColors.warmGold;
      case LoadingType.patternAnalysis:
        return AppColors.naturalGreen;
      case LoadingType.memoryProcessing:
        return AppColors.calmBlue;
      case LoadingType.aliceThinking:
        return AppColors.warmGold;
      case LoadingType.general:
        return AppColors.deepPurple;
    }
  }
}

class ApiCallLoadingWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() apiCall;
  final LoadingType loadingType;
  final String? loadingMessage;
  final String? errorTitle;
  final String? errorMessage;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const ApiCallLoadingWrapper({
    super.key,
    required this.child,
    required this.apiCall,
    this.loadingType = LoadingType.general,
    this.loadingMessage,
    this.errorTitle,
    this.errorMessage,
    this.onSuccess,
    this.onError,
  });

  @override
  State<ApiCallLoadingWrapper> createState() => _ApiCallLoadingWrapperState();
}

class _ApiCallLoadingWrapperState extends State<ApiCallLoadingWrapper> {
  bool _isLoading = false;

  Future<void> _executeApiCall() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.apiCall();
      widget.onSuccess?.call();
    } catch (error) {
      widget.onError?.call();
      if (mounted) {
        _showErrorDialog(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glassBg,
        title: Text(
          widget.errorTitle ?? 'Error',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          widget.errorMessage ?? 'An error occurred: $error',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: AppColors.deepPurple),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executeApiCall();
            },
            child: Text(
              'Retry',
              style: TextStyle(color: AppColors.warmGold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EnhancedLoadingOverlay(
      isLoading: _isLoading,
      loadingType: widget.loadingType,
      loadingMessage: widget.loadingMessage,
      onTimeout: () {
        if (mounted) {
          _showErrorDialog('Request timed out');
        }
      },
      child: GestureDetector(
        onTap: _executeApiCall,
        child: widget.child,
      ),
    );
  }
}