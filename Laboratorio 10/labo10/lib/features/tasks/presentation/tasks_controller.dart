import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exceptions/api_exceptions.dart';
import '../../../core/providers.dart';
import '../data/task_remote_datasource.dart';
import '../data/task_repository_impl.dart';
import '../domain/task.dart';
import '../domain/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(TaskRemoteDataSource(ref.watch(dioProvider)));
});

/// Estado de la lista: elementos cargados + datos de paginación.
class TasksState {
  final List<Task> items;
  final int page;
  final int totalPages;
  final int total;
  final bool isLoadingMore;
  final ApiException? loadMoreError;

  const TasksState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  bool get hasMore => page < totalPages;

  TasksState copyWith({
    List<Task>? items,
    int? page,
    int? totalPages,
    int? total,
    bool? isLoadingMore,
    ApiException? loadMoreError,
    bool clearLoadMoreError = false,
  }) =>
      TasksState(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError: clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      );
}

/// AsyncNotifier de tareas: loading / data / error + CRUD + paginación.
/// `autoDispose`: al cerrar sesión (o salir de la pantalla) el estado se descarta.
class TasksController extends AutoDisposeAsyncNotifier<TasksState> {
  static const int pageSize = 15;

  bool _alive = true;

  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  @override
  Future<TasksState> build() async {
    _alive = true;
    ref.onDispose(() => _alive = false);

    final page = await _repo.fetchTasks(page: 1, limit: pageSize);
    return TasksState(
      items: page.items,
      page: page.page,
      totalPages: page.totalPages,
      total: page.total,
    );
  }

  /// Carga la siguiente página (paginación infinita).
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));
    try {
      final next = await _repo.fetchTasks(page: current.page + 1, limit: pageSize);
      if (!_alive) return;
      final latest = state.valueOrNull ?? current;
      final knownIds = latest.items.map((t) => t.id).toSet();
      state = AsyncData(latest.copyWith(
        items: [...latest.items, ...next.items.where((t) => !knownIds.contains(t.id))],
        page: next.page,
        totalPages: next.totalPages,
        total: next.total,
        isLoadingMore: false,
      ));
    } on ApiException catch (e) {
      if (!_alive) return;
      final latest = state.valueOrNull ?? current;
      state = AsyncData(latest.copyWith(isLoadingMore: false, loadMoreError: e));
    }
  }

  // Las operaciones CRUD lanzan ApiException: la pantalla muestra el feedback.

  Future<void> createTask({required String title, String description = ''}) async {
    final task = await _repo.create(title: title, description: description);
    final current = state.valueOrNull;
    if (!_alive || current == null) return;
    state = AsyncData(current.copyWith(items: [task, ...current.items], total: current.total + 1));
  }

  Future<void> updateTask(Task task) async {
    final updated = await _repo.update(task);
    final current = state.valueOrNull;
    if (!_alive || current == null) return;
    state = AsyncData(current.copyWith(
      items: [for (final t in current.items) t.id == updated.id ? updated : t],
    ));
  }

  Future<void> deleteTask(int id) async {
    await _repo.delete(id);
    final current = state.valueOrNull;
    if (!_alive || current == null) return;
    state = AsyncData(current.copyWith(
      items: current.items.where((t) => t.id != id).toList(),
      total: current.total - 1,
    ));
  }
}

final tasksControllerProvider =
    AsyncNotifierProvider.autoDispose<TasksController, TasksState>(TasksController.new);
