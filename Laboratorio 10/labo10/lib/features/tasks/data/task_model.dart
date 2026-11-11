import '../domain/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.completed,
    required super.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as int,
        title: json['title'] as String,
        description: (json['description'] as String?) ?? '',
        completed: json['completed'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
