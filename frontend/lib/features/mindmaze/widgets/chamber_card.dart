import 'package:flutter/material.dart';
import '../models/chamber.dart';

class ChamberCard extends StatelessWidget {
  final Chamber chamber;
  final VoidCallback? onTap;

  const ChamberCard({
    super.key,
    required this.chamber,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: chamber.isUnlocked ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: chamber.isUnlocked
              ? LinearGradient(
                  colors: [
                    chamber.themeColor.withValues(alpha: 0.3),
                    const Color(0xFF2D2D4A),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.withValues(alpha: 0.2),
                    const Color(0xFF2D2D4A),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chamber.isUnlocked
                ? chamber.themeColor.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        chamber.icon,
                        color: chamber.isUnlocked ? chamber.themeColor : Colors.grey,
                        size: 28,
                      ),
                      const Spacer(),
                      if (!chamber.isUnlocked)
                        const Icon(Icons.lock, color: Colors.grey, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    chamber.name,
                    style: TextStyle(
                      color: chamber.isUnlocked ? Colors.white : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      chamber.description,
                      style: TextStyle(
                        color: chamber.isUnlocked ? Colors.white70 : Colors.grey,
                        fontSize: 12,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (chamber.isUnlocked) ...[
                    const SizedBox(height: 8),
                    _buildChamberProgress(),
                  ],
                ],
              ),
            ),
            if (chamber.isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChamberProgress() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            Text(
              '${chamber.completedQuestions}/${chamber.totalQuestions}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: chamber.completionPercentage,
          backgroundColor: Colors.white30,
          valueColor: AlwaysStoppedAnimation<Color>(chamber.themeColor),
        ),
      ],
    );
  }
}