import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/mindmaze/models/alice_persona.dart';
import '../providers/alice_state_provider.dart';
import '../core/theme/app_colors.dart';

class EnhancedAliceAvatar extends ConsumerStatefulWidget {
  final double size;
  final VoidCallback? onTap;
  final bool showNotificationBadge;

  const EnhancedAliceAvatar({
    super.key,
    this.size = 60,
    this.onTap,
    this.showNotificationBadge = false,
  });

  @override
  ConsumerState<EnhancedAliceAvatar> createState() => _EnhancedAliceAvatarState();
}

class _EnhancedAliceAvatarState extends ConsumerState<EnhancedAliceAvatar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _transitionController;
  late AnimationController _notificationController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _notificationAnimation;

  AlicePersonaType? _previousPersona;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _notificationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

    _notificationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _notificationController,
      curve: Curves.elasticOut,
    ));

    _pulseController.repeat(reverse: true);
    
    if (widget.showNotificationBadge) {
      _notificationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EnhancedAliceAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.showNotificationBadge != oldWidget.showNotificationBadge) {
      if (widget.showNotificationBadge) {
        _notificationController.repeat(reverse: true);
      } else {
        _notificationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transitionController.dispose();
    _notificationController.dispose();
    super.dispose();
  }

  void _triggerPersonaTransition(AlicePersonaType newPersona) {
    if (_previousPersona != newPersona) {
      _previousPersona = newPersona;
      _transitionController.forward().then((_) {
        _transitionController.reverse();
      });
    }
  }

  double _getConsciousnessLevel(AliceState state) {
    // Calculate consciousness level based on activity level and persona
    final baseLevel = (state.activityLevel * 2.0).clamp(0.0, 80.0);
    final personaBonus = switch (state.persona.type) {
      AlicePersonaType.nurturingPresence => 10.0,
      AlicePersonaType.wiseDetective => 20.0,
      AlicePersonaType.transcendentGuide => 30.0,
      AlicePersonaType.unifiedConsciousness => 40.0,
    };
    return (baseLevel + personaBonus).clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    final aliceState = ref.watch(aliceStateProvider);
    final currentPersona = aliceState.persona;
    
    // Trigger transition animation when persona changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerPersonaTransition(currentPersona.type);
    });

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _transitionController,
          _notificationController,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 0.1, // Subtle rotation
              child: Stack(
                children: [
                  // Main avatar container
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _getPersonaGradient(currentPersona),
                      boxShadow: [
                        BoxShadow(
                          color: _getPersonaColor(currentPersona).withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: _getPersonaColor(currentPersona),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          _getPersonaIcon(currentPersona),
                          key: ValueKey(currentPersona.type),
                          size: widget.size * 0.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // Notification badge
                  if (widget.showNotificationBadge)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Transform.scale(
                        scale: _notificationAnimation.value,
                        child: Container(
                          width: widget.size * 0.3,
                          height: widget.size * 0.3,
                          decoration: BoxDecoration(
                            color: AppColors.anxiety,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.size * 0.15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Consciousness level indicator
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _getConsciousnessLevel(aliceState) / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: _getPersonaColor(currentPersona),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  LinearGradient _getPersonaGradient(AlicePersona persona) {
    switch (persona.type) {
      case AlicePersonaType.nurturingPresence:
        return LinearGradient(
          colors: [
            AppColors.naturalGreen,
            AppColors.calmBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        
      case AlicePersonaType.wiseDetective:
        return LinearGradient(
          colors: [
            AppColors.deepPurple,
            AppColors.warmGold,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        
      case AlicePersonaType.transcendentGuide:
        return LinearGradient(
          colors: [
            AppColors.warmGold,
            AppColors.naturalGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        
      case AlicePersonaType.unifiedConsciousness:
        return LinearGradient(
          colors: [
            AppColors.calmBlue,
            AppColors.naturalGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getPersonaColor(AlicePersona persona) {
    switch (persona.type) {
      case AlicePersonaType.nurturingPresence:
        return AppColors.naturalGreen;
      case AlicePersonaType.wiseDetective:
        return AppColors.deepPurple;
      case AlicePersonaType.transcendentGuide:
        return AppColors.warmGold;
      case AlicePersonaType.unifiedConsciousness:
        return AppColors.calmBlue;
    }
  }

  IconData _getPersonaIcon(AlicePersona persona) {
    switch (persona.type) {
      case AlicePersonaType.nurturingPresence:
        return Icons.favorite;
      case AlicePersonaType.wiseDetective:
        return Icons.psychology;
      case AlicePersonaType.transcendentGuide:
        return Icons.explore;
      case AlicePersonaType.unifiedConsciousness:
        return Icons.all_inclusive;
    }
  }
}

