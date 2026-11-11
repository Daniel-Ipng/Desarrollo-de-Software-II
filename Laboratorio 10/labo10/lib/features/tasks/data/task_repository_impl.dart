import '../../../core/network/api_guard.dart';
import '../domain/task.dart';
import '../domain/task_repository.dart';
import 'task_remote_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remote);

  final TaskRemoteDataSource _remote;

  @override
  Future<TaskPage> fetchTasks({required int page, required int limit}) =>
      guardApi(() => _remote.fetchTasks(page: page, limit: limit));

  @override
  Future<Task> create({required String title, String description = ''}) =>
      guardApi(() => _remote.create(title: title, description: description));

  @override
  Future<Task> update(Task task) => guardApi(() => _remote.update(task));

  @override
  Future<void> delete(int id) => guardApi(() => _remote.delete(id));
}
