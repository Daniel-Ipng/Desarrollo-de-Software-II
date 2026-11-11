import 'task.dart';

abstract class TaskRepository {
  Future<TaskPage> fetchTasks({required int page, required int limit});
  Future<Task> create({required String title, String description = ''});
  Future<Task> update(Task task);
  Future<void> delete(int id);
}
