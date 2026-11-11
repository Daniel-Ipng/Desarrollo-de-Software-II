import 'package:dio/dio.dart';

import '../domain/task.dart';
import 'task_model.dart';

/// Endpoints CRUD de tareas (el token lo agrega el AuthInterceptor).
class TaskRemoteDataSource {
  TaskRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TaskPage> fetchTasks({required int page, required int limit}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/tasks',
      queryParameters: {'page': page, 'limit': limit},
    );
    final json = res.data!;
    final items = (json['data'] as List<dynamic>)
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return TaskPage(
      items: items,
      page: json['page'] as int,
      totalPages: json['totalPages'] as int,
      total: json['total'] as int,
    );
  }

  Future<TaskModel> create({required String title, required String description}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/tasks',
      data: {'title': title, 'description': description},
    );
    return TaskModel.fromJson(res.data!);
  }

  Future<TaskModel> update(Task task) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/tasks/${task.id}',
      data: {
        'title': task.title,
        'description': task.description,
        'completed': task.completed,
      },
    );
    return TaskModel.fromJson(res.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/tasks/$id');
  }
}
