import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AliceThinkingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;

  const AliceThinkingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AliceThinkingIndicator> createState() => _AliceThinkingIndicatorState();
}

class _AliceThinkingIndicatorState extends State<AliceThinkingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (widget.color ?? AppColors.warmGold).withValues(alpha: 0.8 * _animation.value),
                (widget.color ?? AppColors.warmGold).withValues(alpha: 0.2 * _animation.value),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.psychology,
              size: widget.size * 0.5,
              color: (widget.color ?? AppColors.warmGold).withValues(alpha: 0.9),
            ),
          ),
        );
      },
    );
  }
}