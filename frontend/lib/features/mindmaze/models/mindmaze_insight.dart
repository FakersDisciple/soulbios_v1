import 'chamber.dart';

class MindMazeInsight {
  final String id;
  final String text;
  final ChamberType chamber;
  final DateTime discoveredAt;
  final String pattern;

  const MindMazeInsight({
    required this.id,
    required this.text,
    required this.chamber,
    required this.discoveredAt,
    required this.pattern,
  });

  MindMazeInsight copyWith({
    String? id,
    String? text,
    ChamberType? chamber,
    DateTime? discoveredAt,
    String? pattern,
  }) {
    return MindMazeInsight(
      id: id ?? this.id,
      text: text ?? this.text,
      chamber: chamber ?? this.chamber,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      pattern: pattern ?? this.pattern,
    );
  }
}