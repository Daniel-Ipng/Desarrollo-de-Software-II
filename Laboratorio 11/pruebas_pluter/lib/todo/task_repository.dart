import 'task.dart';

abstract class TaskRepository {
  Future<List<Task>> getAll();
  Future<Task> add(String description, Priority priority);
  Future<void> delete(int id);
}
