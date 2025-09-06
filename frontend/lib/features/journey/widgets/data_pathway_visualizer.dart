import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/api_models.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../utils/performance_optimizer.dart';

class DataPathwayVisualizer extends ConsumerStatefulWidget {
  final List<DataDestination> destinations;
  final VoidCallback? onAnimationComplete;
  final bool autoStart;

  const DataPathwayVisualizer({
    super.key,
    required this.destinations,
    this.onAnimationComplete,
    this.autoStart = true,
  });

  @override
  ConsumerState<DataPathwayVisualizer> createState() => _DataPathwayVisualizerState();
}

class _DataPathwayVisualizerState extends ConsumerState<DataPathwayVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _pathwayController;
  late AnimationController _pulseController;
  late Animation<double> _pathwayAnimation;
  late Animation<double> _pulseAnimation;
  
  final List<GlobalKey> _destinationKeys = [];
  final List<Offset> _destinationPositions = [];
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    
    _pathwayController = OptimizedAnimationController.create(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
      debugLabel: 'DataPathwayController',
    );
    
    _pulseController = OptimizedAnimationController.create(
      duration: const Duration(milliseconds: 800),
      vsync: this,
      debugLabel: 'PulseController',
    );
    
    _pathwayAnimation = CurvedAnimation(
      parent: _pathwayController,
      curve: Curves.easeInOut,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    // Initialize destination keys
    for (int i = 0; i < widget.destinations.length; i++) {
      _destinationKeys.add(GlobalKey());
    }

    _pathwayController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.forward().then((_) {
          _pulseController.reverse();
          widget.onAnimationComplete?.call();
          setState(() => _isAnimating = false);
        });
      }
    });

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAnimation();
      });
    }
  }

  @override
  void dispose() {
    _pathwayController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (_isAnimating) return;
    
    setState(() => _isAnimating = true);
    _calculateDestinationPositions();
    _pathwayController.forward(from: 0);
  }

  void _calculateDestinationPositions() {
    _destinationPositions.clear();
    for (final key in _destinationKeys) {
      final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        _destinationPositions.add(position);
      } else {
        _destinationPositions.add(Offset.zero);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Destination icons
        ...widget.destinations.asMap().entries.map((entry) {
          final index = entry.key;
          final destination = entry.value;
          
          return Positioned(
            top: 100 + (index * 80.0),
            right: 20 + (index % 2 * 60.0),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isAnimating ? _pulseAnimation.value : 1.0,
                  child: GlassmorphicCard(
                    key: _destinationKeys[index],
                    padding: const EdgeInsets.all(12),
                    backgroundColor: destination.color.withValues(alpha: 0.2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconFromPath(destination.iconPath),
                          color: destination.color,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination.description,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
        
        // Animated pathways
        if (_isAnimating)
          AnimatedBuilder(
            animation: _pathwayAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: PathwayPainter(
                  destinations: widget.destinations,
                  destinationPositions: _destinationPositions,
                  animationValue: _pathwayAnimation.value,
                  sourcePosition: const Offset(50, 200), // Input field position
                ),
                size: Size.infinite,
              );
            },
          ),
        
        // Control button
        Positioned(
          bottom: 20,
          left: 20,
          child: GlassmorphicCard(
            onTap: _startAnimation,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isAnimating ? Icons.refresh : Icons.play_arrow,
                  color: AppColors.warmGold,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isAnimating ? 'Animating...' : 'Show Pathways',
                  style: TextStyle(
                    color: AppColors.warmGold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconFromPath(String iconPath) {
    switch (iconPath) {
      case 'speech_bubble':
        return Icons.chat_bubble_outline;
      case 'search':
        return Icons.search;
      case 'memory':
        return Icons.psychology;
      case 'pattern':
        return Icons.hub;
      case 'wisdom':
        return Icons.lightbulb_outline;
      default:
        return Icons.circle;
    }
  }
}

class PathwayPainter extends CustomPainter {
  final List<DataDestination> destinations;
  final List<Offset> destinationPositions;
  final double animationValue;
  final Offset sourcePosition;

  PathwayPainter({
    required this.destinations,
    required this.destinationPositions,
    required this.animationValue,
    required this.sourcePosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < destinationPositions.length; i++) {
      if (i >= destinations.length) continue;
      
      final destination = destinations[i];
      final targetPosition = destinationPositions[i];
      
      if (targetPosition == Offset.zero) continue;
      
      // Create curved path
      final path = Path();
      path.moveTo(sourcePosition.dx, sourcePosition.dy);
      
      // Control points for smooth curve
      final controlPoint1 = Offset(
        sourcePosition.dx + (targetPosition.dx - sourcePosition.dx) * 0.3,
        sourcePosition.dy - 50,
      );
      final controlPoint2 = Offset(
        sourcePosition.dx + (targetPosition.dx - sourcePosition.dx) * 0.7,
        targetPosition.dy - 30,
      );
      
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        targetPosition.dx, targetPosition.dy,
      );
      
      // Calculate path length for animation
      final pathMetrics = path.computeMetrics();
      final pathMetric = pathMetrics.first;
      final animatedLength = pathMetric.length * animationValue;
      
      // Draw animated path
      final animatedPath = pathMetric.extractPath(0, animatedLength);
      
      final paint = Paint()
        ..color = destination.color.withValues(alpha: 0.8)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      // Add glow effect
      final glowPaint = Paint()
        ..color = destination.color.withValues(alpha: 0.3)
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawPath(animatedPath, glowPaint);
      canvas.drawPath(animatedPath, paint);
      
      // Draw flowing particles
      if (animationValue > 0.2) {
        _drawFlowingParticles(canvas, pathMetric, destination.color, animationValue);
      }
    }
  }

  void _drawFlowingParticles(Canvas canvas, ui.PathMetric pathMetric, Color color, double animationValue) {
    // Use performance optimizer to determine particle count
    final optimizer = PerformanceOptimizer.instance;
    final particleCount = optimizer.getOptimizedParticleCount(5);
    
    final particlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < particleCount; i++) {
      final particleProgress = (animationValue + (i * 0.2)) % 1.0;
      final particleDistance = pathMetric.length * particleProgress;
      
      final tangent = pathMetric.getTangentForOffset(particleDistance);
      if (tangent != null) {
        final particleSize = 4.0 * (1.0 - (i * 0.2));
        canvas.drawCircle(tangent.position, particleSize, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}