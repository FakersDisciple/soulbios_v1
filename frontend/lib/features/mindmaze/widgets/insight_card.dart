import 'package:flutter/material.dart';
import '../models/mindmaze_insight.dart';
import '../models/chamber.dart';

class InsightCard extends StatelessWidget {
  final MindMazeInsight insight;
  final Chamber chamber;

  const InsightCard({
    super.key,
    required this.insight,
    required this.chamber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            chamber.themeColor.withValues(alpha: 0.2),
            const Color(0xFF2D2D4A),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chamber.themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(chamber.icon, color: chamber.themeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chamber.name,
                  style: TextStyle(
                    color: chamber.themeColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              insight.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatTimeAgo(insight.discoveredAt),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}