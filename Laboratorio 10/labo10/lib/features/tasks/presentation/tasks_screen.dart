import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exceptions/api_exceptions.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/task.dart';
import 'task_form_dialog.dart';
import 'tasks_controller.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _busy = false; // hay una operación CRUD en curso

  TasksController get _controller => ref.read(tasksControllerProvider.notifier);

  void _showSnack(String message, {bool isError = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? scheme.error : null,
      ));
  }

  /// Ejecuta una operación CRUD con indicador de progreso y feedback visual.
  Future<void> _run(Future<void> Function() action, String successMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _showSnack(successMessage);
    } catch (e) {
      if (mounted) _showSnack(friendlyMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addTask() async {
    final result = await showTaskFormDialog(context);
    if (result == null || !mounted) return;
    await _run(
      () => _controller.createTask(title: result.title, description: result.description),
      'Tarea creada',
    );
  }

  Future<void> _editTask(Task task) async {
    final result = await showTaskFormDialog(context, initial: task);
    if (result == null || !mounted) return;
    await _run(
      () => _controller.updateTask(
        task.copyWith(title: result.title, description: result.description),
      ),
      'Tarea actualizada',
    );
  }

  Future<void> _toggleTask(Task task, bool completed) {
    return _run(
      () => _controller.updateTask(task.copyWith(completed: completed)),
      completed ? 'Tarea completada' : 'Tarea marcada como pendiente',
    );
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() => _controller.deleteTask(task.id), 'Tarea eliminada');
  }

  Future<void> _onRefresh() async {
    try {
      final _ = await ref.refresh(tasksControllerProvider.future);
    } catch (e) {
      if (mounted) _showSnack(friendlyMessage(e), isError: true);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(user == null ? 'Mis tareas' : 'Tareas de ${user.name}'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _busy ? null : _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nueva tarea',
        onPressed: _busy ? null : _addTask,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: tasks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(tasksControllerProvider),
              ),
              data: _buildList,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(TasksState state) {
    if (state.items.isEmpty) {
      // ListView para que el pull-to-refresh funcione también con la lista vacía.
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.inbox_outlined, size: 72),
            SizedBox(height: 12),
            Center(child: Text('No tienes tareas. Toca + para crear una.')),
          ],
        ),
      );
    }

    final showFooter = state.hasMore || state.loadMoreError != null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${state.items.length} de ${state.total} tareas',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.items.length + (showFooter ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  return _LoadMoreFooter(
                    error: state.loadMoreError,
                    onLoad: _controller.loadMore,
                  );
                }
                return _TaskTile(
                  task: state.items[index],
                  enabled: !_busy,
                  onToggle: (value) => _toggleTask(state.items[index], value),
                  onEdit: () => _editTask(state.items[index]),
                  onDelete: () => _deleteTask(state.items[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.enabled,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: task.completed,
        onChanged: enabled ? (v) => onToggle(v ?? false) : null,
      ),
      title: Text(
        task.title,
        style: task.completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: task.description.isEmpty ? null : Text(task.description),
      trailing: IconButton(
        tooltip: 'Eliminar',
        icon: const Icon(Icons.delete_outline),
        onPressed: enabled ? onDelete : null,
      ),
      onTap: enabled ? onEdit : null,
    );
  }
}

/// Pie de la lista: cuando aparece en pantalla dispara la carga de la siguiente página.
class _LoadMoreFooter extends StatefulWidget {
  const _LoadMoreFooter({required this.error, required this.onLoad});

  final ApiException? error;
  final Future<void> Function() onLoad;

  @override
  State<_LoadMoreFooter> createState() => _LoadMoreFooterState();
}

class _LoadMoreFooterState extends State<_LoadMoreFooter> {
  @override
  void initState() {
    super.initState();
    if (widget.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoad());
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(error.message, textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: widget.onLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
