import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SoulBiosBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SoulBiosBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final List<IconData> icons = const [
    Icons.today,        // Today
    Icons.explore,      // Compass  
    Icons.book,         // Journey
    Icons.landscape,    // Horizon
    Icons.account_tree, // Mind Maze
  ];

  double _calculateIndicatorPosition(BuildContext context) {
    final containerWidth = MediaQuery.of(context).size.width - 32; // Subtract margins
    final itemWidth = containerWidth / icons.length;
    return (currentIndex * itemWidth) + (itemWidth / 2) - 25; // Center the 50px circle
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withValues(alpha: 0.9), // Semi-transparent
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Floating indicator circle
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _calculateIndicatorPosition(context),
            top: 10,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B), // Orange circle
                shape: BoxShape.circle,
              ),
              child: Icon(
                icons[currentIndex],
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          // Navigation items (just icons, NO TEXT)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: icons.asMap().entries.map((entry) {
              final index = entry.key;
              final icon = entry.value;
              final isSelected = index == currentIndex;
              
              return GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onTap(index);
                },
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: isSelected ? 0.0 : 1.0, // Hide selected icon (shows in circle)
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        icon,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}