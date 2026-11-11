class Task {
  final int id;
  final String title;
  final String description;
  final bool completed;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.createdAt,
  });

  Task copyWith({String? title, String? description, bool? completed}) => Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        completed: completed ?? this.completed,
        createdAt: createdAt,
      );
}

/// Una página de resultados.
class TaskPage {
  final List<Task> items;
  final int page;
  final int totalPages;
  final int total;

  const TaskPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  bool get hasNextPage => page < totalPages;
}
