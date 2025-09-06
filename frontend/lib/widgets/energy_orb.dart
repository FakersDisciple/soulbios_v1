import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/today_state.dart';

class EnergyOrb extends ConsumerWidget {
  final Color glowColor;
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDimmed;
  final VoidCallback onTap;
  final VoidCallback? onAddTap;
  
  const EnergyOrb({
    super.key,
    required this.glowColor,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDimmed,
    required this.onTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the TodayPageStateNotifier to get glow intensity
    final todayState = ref.watch(todayPageProvider);
    
    double size = isActive ? 70 : (isDimmed ? 55 : 65);
    
    // Look up the glow intensity for the current orb's label in the orbGlowIntensities map
    // If no entry exists for that orb (i.e., no text has been typed), default to base glow intensity of 0.4
    double baseGlowIntensity = todayState.orbGlowIntensities[label] ?? 0.4;
    
    // Apply the existing animation logic for isActive and isDimmed states
    double glowIntensity = isActive ? baseGlowIntensity : (isDimmed ? 0.2 : baseGlowIntensity);
    double glowSpread = isActive ? 1.0 : (isDimmed ? 0.5 : 1.0);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: glowIntensity * glowSpread),
                        blurRadius: isActive ? 24 : (isDimmed ? 12 : 16),
                        spreadRadius: isActive ? 3 : (isDimmed ? 1 : 2),
                      ),
                      BoxShadow(
                        color: glowColor.withValues(alpha: glowIntensity * 0.5 * glowSpread),
                        blurRadius: isActive ? 48 : (isDimmed ? 24 : 32),
                        spreadRadius: isActive ? 6 : (isDimmed ? 2 : 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: isActive ? 30 : (isDimmed ? 22 : 26),
                    color: glowColor.withValues(alpha: isDimmed ? 0.6 : 1.0),
                  ),
                ),
                
                // Add button that appears only for active orbs
                if (isActive && onAddTap != null)
                  Positioned(
                    bottom: -8,
                    left: size / 2 - 16,
                    child: AnimatedScale(
                      scale: isActive ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: onAddTap,
                            child: Icon(
                              Icons.add,
                              size: 18,
                              color: glowColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDimmed ? Colors.white38 : Colors.white70,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}