import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum LoadingType {
  general,
  imageGeneration,
  patternAnalysis,
  memoryProcessing,
  aliceThinking,
}

class AnimatedLoadingWidget extends StatefulWidget {
  final LoadingType type;
  final String? message;
  final double size;
  final bool showMessage;

  const AnimatedLoadingWidget({
    super.key,
    this.type = LoadingType.general,
    this.message,
    this.size = 100,
    this.showMessage = true,
  });

  @override
  State<AnimatedLoadingWidget> createState() => _AnimatedLoadingWidgetState();
}

class _AnimatedLoadingWidgetState extends State<AnimatedLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading animation
          AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _rotationController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159,
                  child: _buildLoadingIcon(),
                ),
              );
            },
          ),
          
          if (widget.showMessage) ...[
            const SizedBox(height: 20),
            
            // Loading message
            Text(
              widget.message ?? _getDefaultMessage(),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Animated dots
            _buildAnimatedDots(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIcon() {
    switch (widget.type) {
      case LoadingType.imageGeneration:
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.deepPurple,
                AppColors.warmGold,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.image,
            size: widget.size * 0.5,
            color: Colors.white,
          ),
        );
        
      case LoadingType.patternAnalysis:
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.naturalGreen,
                AppColors.calmBlue,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.analytics,
            size: widget.size * 0.5,
            color: Colors.white,
          ),
        );
        
      case LoadingType.memoryProcessing:
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.calmBlue,
                AppColors.deepPurple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.memory,
            size: widget.size * 0.5,
            color: Colors.white,
          ),
        );
        
      case LoadingType.aliceThinking:
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.warmGold,
                AppColors.naturalGreen,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.psychology,
            size: widget.size * 0.5,
            color: Colors.white,
          ),
        );
        
      case LoadingType.general:
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.deepPurple,
                AppColors.calmBlue,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
    }
  }

  String _getDefaultMessage() {
    switch (widget.type) {
      case LoadingType.imageGeneration:
        return 'Generating your scene...';
      case LoadingType.patternAnalysis:
        return 'Analyzing patterns...';
      case LoadingType.memoryProcessing:
        return 'Processing memories...';
      case LoadingType.aliceThinking:
        return 'Alice is thinking...';
      case LoadingType.general:
        return 'Loading...';
    }
  }

  Widget _buildAnimatedDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final delay = index * 0.3;
            final animationValue = (_pulseController.value + delay) % 1.0;
            final opacity = (animationValue < 0.5) 
                ? animationValue * 2 
                : (1.0 - animationValue) * 2;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final LoadingType loadingType;
  final String? loadingMessage;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingType = LoadingType.general,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: AnimatedLoadingWidget(
              type: loadingType,
              message: loadingMessage,
            ),
          ),
      ],
    );
  }
}