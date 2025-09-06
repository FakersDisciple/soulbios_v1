class LogEntry {
  final String id;
  final String text;
  final DateTime timestamp;
  final List<String> patterns;

  LogEntry({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.patterns,
  });

  LogEntry copyWith({
    String? id,
    String? text,
    DateTime? timestamp,
    List<String>? patterns,
  }) {
    return LogEntry(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      patterns: patterns ?? this.patterns,
    );
  }
}