import 'package:flutter/material.dart';
import '../features/mindmaze/models/character.dart';
import '../services/character_service.dart';
import '../core/theme/app_colors.dart';

class CharacterTransitionWidget extends StatefulWidget {
  final Character? fromCharacter;
  final Character toCharacter;
  final Widget child;
  final Duration duration;
  final VoidCallback? onTransitionComplete;

  const CharacterTransitionWidget({
    super.key,
    this.fromCharacter,
    required this.toCharacter,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.onTransitionComplete,
  });

  @override
  State<CharacterTransitionWidget> createState() => _CharacterTransitionWidgetState();
}

class _CharacterTransitionWidgetState extends State<CharacterTransitionWidget>
    with TickerProviderStateMixin {
  late AnimationController _transitionController;
  late AnimationController _colorController;
  late AnimationController _scaleController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _transitionController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _colorController = AnimationController(
      duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 2),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: widget.fromCharacter?.primaryColor ?? AppColors.deepPurple,
      end: widget.toCharacter.primaryColor,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    ));

    _startTransition();
  }

  void _startTransition() {
    _colorController.forward();
    _scaleController.forward();
    _transitionController.forward().then((_) {
      widget.onTransitionComplete?.call();
    });
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _colorController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _transitionController,
        _colorController,
        _scaleController,
      ]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                (_colorAnimation.value ?? widget.toCharacter.primaryColor)
                    .withValues(alpha: 0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CharacterSwitchAnimation extends StatefulWidget {
  final Character currentCharacter;
  final Character newCharacter;
  final Widget Function(Character character) builder;
  final Duration duration;

  const CharacterSwitchAnimation({
    super.key,
    required this.currentCharacter,
    required this.newCharacter,
    required this.builder,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<CharacterSwitchAnimation> createState() => _CharacterSwitchAnimationState();
}

class _CharacterSwitchAnimationState extends State<CharacterSwitchAnimation>
    with TickerProviderStateMixin {
  late AnimationController _switchController;
  late Animation<double> _fadeOutAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _rotationAnimation;
  
  Character _displayedCharacter = Character(
    id: '',
    name: '',
    description: '',
    archetype: CharacterArchetype.compassionateFriend,
    avatarPath: '',
    primaryColor: Colors.transparent,
    traits: [],
    personalityMatrix: {},
  );
  
  bool _showingNew = false;

  @override
  void initState() {
    super.initState();
    _displayedCharacter = widget.currentCharacter;
    
    _switchController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeOutAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _switchController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _switchController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _switchController,
      curve: Curves.easeInOut,
    ));

    _switchController.addStatusListener((status) {
      if (status == AnimationStatus.forward && _switchController.value >= 0.5 && !_showingNew) {
        setState(() {
          _displayedCharacter = widget.newCharacter;
          _showingNew = true;
        });
      }
    });

    // Start the switch animation
    _switchController.forward();
  }

  @override
  void dispose() {
    _switchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _switchController,
      builder: (context, child) {
        final opacity = _showingNew ? _fadeInAnimation.value : _fadeOutAnimation.value;
        
        return Transform.rotate(
          angle: _rotationAnimation.value * 3.14159,
          child: Opacity(
            opacity: opacity,
            child: widget.builder(_displayedCharacter),
          ),
        );
      },
    );
  }
}