import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../features/mindmaze/models/chamber.dart';
import '../services/subscription_service.dart';
import '../core/theme/app_colors.dart';

class AnimatedChamberCard extends ConsumerStatefulWidget {
  final Chamber chamber;
  final VoidCallback onTap;
  final bool showUnlockAnimation;

  const AnimatedChamberCard({
    super.key,
    required this.chamber,
    required this.onTap,
    this.showUnlockAnimation = false,
  });

  @override
  ConsumerState<AnimatedChamberCard> createState() => _AnimatedChamberCardState();
}

class _AnimatedChamberCardState extends ConsumerState<AnimatedChamberCard>
    with TickerProviderStateMixin {
  late AnimationController _unlockController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _borderColorAnimation;

  bool _hasPlayedUnlockAnimation = false;

  @override
  void initState() {
    super.initState();
    
    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _borderColorAnimation = ColorTween(
      begin: Colors.grey.withValues(alpha: 0.3),
      end: AppColors.warmGold,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: Curves.easeInOut,
    ));

    // Start continuous pulse for unlocked chambers
    if (widget.chamber.isUnlocked) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedChamberCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger unlock animation when chamber becomes unlocked
    if (!oldWidget.chamber.isUnlocked && widget.chamber.isUnlocked && !_hasPlayedUnlockAnimation) {
      _playUnlockAnimation();
    }
    
    // Handle pulse animation based on unlock status
    if (widget.chamber.isUnlocked && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.chamber.isUnlocked && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  void _playUnlockAnimation() {
    _hasPlayedUnlockAnimation = true;
    _unlockController.forward().then((_) {
      _glowController.repeat(reverse: true);
      
      // Show unlock celebration
      _showUnlockCelebration();
      
      // Reset scale after animation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _unlockController.reverse();
        }
      });
    });
  }

  void _showUnlockCelebration() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.warmGold,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Celebration animation
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Lottie.asset(
                    'assets/lottie/celebration.json',
                    repeat: false,
                    onLoaded: (composition) {
                      // Auto-close after animation
                      Future.delayed(composition.duration, () {
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Unlock message
                Text(
                  'Chamber Unlocked!',
                  style: TextStyle(
                    color: AppColors.warmGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  widget.chamber.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'New depths of consciousness await',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      Navigator.of(context).pop();
                      widget.onTap();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmGold,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Explore Now'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _unlockController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = SubscriptionService.instance;
    final isAvailable = subscriptionService.isChamberTypeAvailable(widget.chamber.type.value);
    final isPremiumLocked = !isAvailable && !subscriptionService.isPremium;

    return AnimatedBuilder(
      animation: Listenable.merge([_unlockController, _pulseController, _glowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (widget.chamber.isUnlocked)
                  BoxShadow(
                    color: AppColors.warmGold.withValues(alpha: 0.3 * _glowAnimation.value),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 2 * _glowAnimation.value,
                  ),
              ],
            ),
            child: Card(
              elevation: widget.chamber.isUnlocked ? 8 : 4,
              color: AppColors.glassBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _getBorderColor(isPremiumLocked),
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: widget.chamber.isUnlocked ? widget.onTap : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Chamber icon with status overlay
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _getIconBackgroundColor(isPremiumLocked),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getIconBorderColor(isPremiumLocked),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getChamberIcon(),
                              size: 30,
                              color: _getIconColor(isPremiumLocked),
                            ),
                          ),
                          
                          // Premium lock indicator
                          if (isPremiumLocked)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.warmGold,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: const Icon(
                                  Icons.diamond,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          
                          // Unlock status indicator
                          if (!widget.chamber.isUnlocked && !isPremiumLocked)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Chamber name
                      Text(
                        widget.chamber.name,
                        style: TextStyle(
                          color: _getTextColor(isPremiumLocked),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Progress indicator
                      if (widget.chamber.isUnlocked)
                        LinearProgressIndicator(
                          value: widget.chamber.completionPercentage / 100,
                          backgroundColor: Colors.grey.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.warmGold,
                          ),
                        )
                      else if (isPremiumLocked)
                        Text(
                          'Premium',
                          style: TextStyle(
                            color: AppColors.warmGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          'Locked',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBorderColor(bool isPremiumLocked) {
    if (isPremiumLocked) {
      return AppColors.warmGold.withValues(alpha: 0.5);
    } else if (widget.chamber.isUnlocked) {
      return _borderColorAnimation.value ?? AppColors.warmGold;
    } else {
      return Colors.grey.withValues(alpha: 0.3);
    }
  }

  Color _getIconBackgroundColor(bool isPremiumLocked) {
    if (isPremiumLocked) {
      return AppColors.warmGold.withValues(alpha: 0.2);
    } else if (widget.chamber.isUnlocked) {
      return AppColors.deepPurple.withValues(alpha: 0.2);
    } else {
      return Colors.grey.withValues(alpha: 0.2);
    }
  }

  Color _getIconBorderColor(bool isPremiumLocked) {
    if (isPremiumLocked) {
      return AppColors.warmGold;
    } else if (widget.chamber.isUnlocked) {
      return AppColors.deepPurple;
    } else {
      return Colors.grey;
    }
  }

  Color _getIconColor(bool isPremiumLocked) {
    if (isPremiumLocked) {
      return AppColors.warmGold;
    } else if (widget.chamber.isUnlocked) {
      return AppColors.deepPurple;
    } else {
      return Colors.grey;
    }
  }

  Color _getTextColor(bool isPremiumLocked) {
    if (isPremiumLocked) {
      return AppColors.warmGold;
    } else if (widget.chamber.isUnlocked) {
      return AppColors.textPrimary;
    } else {
      return Colors.grey;
    }
  }

  IconData _getChamberIcon() {
    switch (widget.chamber.type) {
      case ChamberType.emotion:
        return Icons.favorite;
      case ChamberType.pattern:
        return Icons.analytics;
      case ChamberType.fortress:
        return Icons.security;
      case ChamberType.wisdom:
        return Icons.lightbulb;
      case ChamberType.transcendent:
        return Icons.auto_awesome;
    }
  }
}