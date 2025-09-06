import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/glassmorphic_card.dart';
import '../../../core/theme/app_colors.dart';

class Value {
  final String name;
  final Color color;
  final double angle;
  final double distance;
  final bool isSelected;

  Value({
    required this.name,
    required this.color,
    required this.angle,
    required this.distance,
    required this.isSelected,
  });

  Value copyWith({
    String? name,
    Color? color,
    double? angle,
    double? distance,
    bool? isSelected,
  }) {
    return Value(
      name: name ?? this.name,
      color: color ?? this.color,
      angle: angle ?? this.angle,
      distance: distance ?? this.distance,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class InteractiveCompass extends ConsumerStatefulWidget {
  const InteractiveCompass({super.key});

  @override
  ConsumerState<InteractiveCompass> createState() => _InteractiveCompassState();
}

class _InteractiveCompassState extends ConsumerState<InteractiveCompass>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late List<Value> _values;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _values = [
      Value(
        name: 'Freedom',
        color: AppColors.energy,
        angle: 0,
        distance: 80,
        isSelected: false,
      ),
      Value(
        name: 'Family',
        color: AppColors.warmGold,
        angle: pi / 3,
        distance: 90,
        isSelected: true,
      ),
      Value(
        name: 'Creativity',
        color: AppColors.deepPurple,
        angle: 2 * pi / 3,
        distance: 85,
        isSelected: false,
      ),
      Value(
        name: 'Growth',
        color: AppColors.naturalGreen,
        angle: pi,
        distance: 95,
        isSelected: true,
      ),
      Value(
        name: 'Security',
        color: AppColors.calmBlue,
        angle: 4 * pi / 3,
        distance: 75,
        isSelected: false,
      ),
      Value(
        name: 'Adventure',
        color: AppColors.softTeal,
        angle: 5 * pi / 3,
        distance: 70,
        isSelected: false,
      ),
    ];
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleValue(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _values[index] = _values[index].copyWith(
        isSelected: !_values[index].isSelected,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Your Values Compass',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Tap values to prioritize them in your authentic center',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          // Compass Visualization
          SizedBox(
            width: 280,
            height: 280,
            child: AnimatedBuilder(
              animation: Listenable.merge([_rotationController, _pulseController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: CompassPainter(
                    values: _values,
                    rotationAnimation: _rotationController.value,
                    pulseAnimation: _pulseController.value,
                  ),
                  size: const Size(280, 280),
                  child: Stack(
                    children: [
                      // Center Circle (Authentic Self)
                      Positioned(
                        left: 140 - 40,
                        top: 140 - 40,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                AppColors.warmGold.withValues(alpha: 0.8),
                                AppColors.warmGold.withValues(alpha: 0.3),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warmGold.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.self_improvement,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'YOU',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Value Dots
                      ..._values.asMap().entries.map((entry) {
                        final index = entry.key;
                        final value = entry.value;
                        final x = 140 + cos(value.angle) * value.distance - 25;
                        final y = 140 + sin(value.angle) * value.distance - 25;
                        
                        return Positioned(
                          left: x,
                          top: y,
                          child: GestureDetector(
                            onTap: () => _toggleValue(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: value.isSelected
                                    ? value.color
                                    : value.color.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: value.isSelected
                                      ? Colors.white
                                      : value.color.withValues(alpha: 0.5),
                                  width: value.isSelected ? 3 : 1,
                                ),
                                boxShadow: value.isSelected
                                    ? [
                                        BoxShadow(
                                          color: value.color.withValues(alpha: 0.5),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  value.name.substring(0, 1),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Values Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _values.map((value) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: value.isSelected
                      ? value.color.withValues(alpha: 0.2)
                      : AppColors.glassBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: value.isSelected
                        ? value.color.withValues(alpha: 0.5)
                        : AppColors.glassBorder,
                  ),
                ),
                child: Text(
                  value.name,
                  style: TextStyle(
                    color: value.isSelected
                        ? value.color
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // Selected Values Count
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warmGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warmGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: AppColors.warmGold,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_values.where((v) => v.isSelected).length} core values selected',
                  style: TextStyle(
                    color: AppColors.warmGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class CompassPainter extends CustomPainter {
  final List<Value> values;
  final double rotationAnimation;
  final double pulseAnimation;

  CompassPainter({
    required this.values,
    required this.rotationAnimation,
    required this.pulseAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw compass rings
    for (int i = 1; i <= 3; i++) {
      paint.color = Colors.white.withValues(alpha: 0.1);
      canvas.drawCircle(center, 40.0 * i + 20, paint);
    }

    // Draw connection lines for selected values
    final selectedValues = values.where((v) => v.isSelected).toList();
    if (selectedValues.length > 1) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.warmGold.withValues(alpha: 0.3);

      for (int i = 0; i < selectedValues.length; i++) {
        final current = selectedValues[i];
        final next = selectedValues[(i + 1) % selectedValues.length];
        
        final currentPos = Offset(
          center.dx + cos(current.angle) * current.distance,
          center.dy + sin(current.angle) * current.distance,
        );
        final nextPos = Offset(
          center.dx + cos(next.angle) * next.distance,
          center.dy + sin(next.angle) * next.distance,
        );
        
        canvas.drawLine(currentPos, nextPos, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}