enum TaskType { pinned, routine, ritual, reflection, courage, connection }

class Task {
  final String id;
  final TaskType type;
  final String description;
  final String timeHint;
  final List<String> categories;
  final bool isCompleted;

  Task({
    required this.id,
    required this.type,
    required this.description,
    this.timeHint = '',
    required this.categories,
    this.isCompleted = false,
  });

  Task copyWith({
    String? id,
    TaskType? type,
    String? description,
    String? timeHint,
    List<String>? categories,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      timeHint: timeHint ?? this.timeHint,
      categories: categories ?? this.categories,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}