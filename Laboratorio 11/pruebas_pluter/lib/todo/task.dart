enum Priority {
  baja('Baja'),
  media('Media'),
  alta('Alta');

  const Priority(this.label);
  final String label;
}

class Task {
  const Task({this.id, required this.description, required this.priority});

  final int? id;
  final String description;
  final Priority priority;
}
