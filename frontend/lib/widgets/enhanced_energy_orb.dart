import 'package:flutter/material.dart';
import '../models/orb_state.dart';

class EnhancedEnergyOrb extends StatefulWidget {
  final OrbState orbState;
  final VoidCallback onTap;

  const EnhancedEnergyOrb({
    super.key,
    required this.orbState,
    required this.onTap,
  });

  @override
  State<EnhancedEnergyOrb> createState() => _EnhancedEnergyOrbState();
}

class _EnhancedEnergyOrbState extends State<EnhancedEnergyOrb>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for high activity
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Scale animation for tap feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _updatePulseAnimation();
  }

  @override
  void didUpdateWidget(EnhancedEnergyOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orbState.intensity != widget.orbState.intensity) {
      _updatePulseAnimation();
    }
  }

  void _updatePulseAnimation() {
    if (widget.orbState.intensity > 0.7) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 80.0;
    final glowRadius = widget.orbState.intensity * 40;
    final opacity = 0.7 + (widget.orbState.intensity * 0.3);

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.orbState.color.withValues(alpha: 0.3),
                    boxShadow: [
                      BoxShadow(
                        color: widget.orbState.color.withValues(
                          alpha: widget.orbState.intensity * 0.8 * _pulseAnimation.value,
                        ),
                        blurRadius: glowRadius * _pulseAnimation.value,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.3),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.orbState.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.orbState.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.orbState.activity,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}