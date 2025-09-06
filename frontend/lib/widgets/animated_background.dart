import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final List<Color> activeVibeColors;

  const AnimatedBackground({
    super.key, 
    required this.child,
    this.activeVibeColors = const [],
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late List<Particle> particles;

  @override
  void initState() {
    super.initState();
    
    _controller1 = AnimationController(
      duration: const Duration(seconds: 40), // Slowed down by half
      vsync: this,
    )..repeat();
    
    _controller2 = AnimationController(
      duration: const Duration(seconds: 30), // Slowed down by half
      vsync: this,
    )..repeat();
    
    _controller3 = AnimationController(
      duration: const Duration(seconds: 50), // Slowed down by half
      vsync: this,
    )..repeat();

    particles = List.generate(20, (index) => Particle(activeVibeColors: widget.activeVibeColors));
  }

  @override
  void didUpdateWidget(AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate particles when active vibe colors change
    if (widget.activeVibeColors != oldWidget.activeVibeColors) {
      particles = List.generate(20, (index) => Particle(activeVibeColors: widget.activeVibeColors));
    }
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dynamic gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A0B3D), // Deep purple-900
                Color(0xFF1E3A8A), // Deep blue-900
                Color(0xFF312E81), // Deep indigo-900
                Color(0xFF0F172A), // Slate-900
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
        
        // Animated particles
        AnimatedBuilder(
          animation: Listenable.merge([_controller1, _controller2, _controller3]),
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                particles: particles,
                animation1: _controller1.value,
                animation2: _controller2.value,
                animation3: _controller3.value,
                activeVibeColors: widget.activeVibeColors,
              ),
              size: Size.infinite,
            );
          },
        ),
        
        // Animated blur orbs
        AnimatedBuilder(
          animation: _controller1,
          builder: (context, child) {
            return Positioned(
              top: 100 + sin(_controller1.value * 2 * pi) * 50,
              left: 50 + cos(_controller1.value * 2 * pi) * 30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.withValues(alpha: 0.3),
                      Colors.purple.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
        
        AnimatedBuilder(
          animation: _controller2,
          builder: (context, child) {
            return Positioned(
              bottom: 150 + sin(_controller2.value * 2 * pi + pi/3) * 40,
              right: 60 + cos(_controller2.value * 2 * pi + pi/3) * 25,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.25),
                      Colors.blue.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
        
        AnimatedBuilder(
          animation: _controller3,
          builder: (context, child) {
            return Positioned(
              top: MediaQuery.of(context).size.height * 0.4 + 
                   sin(_controller3.value * 2 * pi + pi/2) * 60,
              left: MediaQuery.of(context).size.width * 0.3 + 
                    cos(_controller3.value * 2 * pi + pi/2) * 40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.pink.withValues(alpha: 0.2),
                      Colors.pink.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
        
        // Main content
        widget.child,
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late Color color;
  late double opacity;

  Particle({List<Color> activeVibeColors = const []}) {
    final random = Random();
    x = random.nextDouble();
    y = random.nextDouble();
    size = random.nextDouble() * 3 + 1;
    speed = (random.nextDouble() * 0.01 + 0.0025); // Slowed down by half
    opacity = random.nextDouble() * 0.5 + 0.1;
    
    // Use active vibe colors if available, otherwise white only
    final colors = activeVibeColors.isNotEmpty 
        ? [
            ...activeVibeColors.map((c) => c.withValues(alpha: 0.7)),
            Colors.white.withValues(alpha: 0.3),
          ]
        : [
            Colors.white, // Only white particles when no orbs are active
          ];
    color = colors[random.nextInt(colors.length)];
  }

  void update() {
    y -= speed;
    if (y < 0) {
      y = 1.0;
      x = Random().nextDouble();
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation1;
  final double animation2;
  final double animation3;
  final List<Color> activeVibeColors;

  ParticlePainter({
    required this.particles,
    required this.animation1,
    required this.animation2,
    required this.animation3,
    required this.activeVibeColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();
      
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(
          particle.x * size.width,
          particle.y * size.height,
        ),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}