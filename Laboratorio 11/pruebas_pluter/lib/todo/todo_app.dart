import 'package:flutter/material.dart';

import 'task.dart';
import 'task_repository.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.repository});

  final TaskRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5548D9),
          surface: const Color(0xFFF7F7FC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7FC),
        useMaterial3: true,
      ),
      home: TodoPage(repository: repository),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key, required this.repository});

  final TaskRepository repository;

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Task> _tasks = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await widget.repository.getAll();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _loaded = true;
    });
  }

  Future<void> _addTask() async {
    final draft = await showDialog<_TaskDraft>(
      context: context,
      builder: (_) => const _TaskFormDialog(),
    );
    if (draft == null) return;
    final task = await widget.repository.add(draft.description, draft.priority);
    if (!mounted) return;
    setState(() => _tasks = [..._tasks, task]);
  }

  Future<void> _deleteTask(Task task) async {
    // Se quita de la lista primero: Dismissible exige que el widget salga del árbol.
    setState(() => _tasks = _tasks.where((t) => t.id != task.id).toList());
    await widget.repository.delete(task.id!);
  }

  Widget _buildTaskCard(Task task) {
    final priorityColor = switch (task.priority) {
      Priority.alta => const Color(0xFFCF4C58),
      Priority.media => const Color(0xFFCB8524),
      Priority.baja => const Color(0xFF39876D),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('task_${task.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFE6E7),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          child: const Icon(Icons.delete_outline, color: Color(0xFFCF4C58)),
        ),
        onDismissed: (_) => _deleteTask(task),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFECECF4)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              task.description,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF25243A),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                avatar: Icon(
                  Icons.flag_rounded,
                  size: 15,
                  color: priorityColor,
                ),
                label: Text(task.priority.label),
                visualDensity: VisualDensity.compact,
                backgroundColor: priorityColor.withValues(alpha: 0.10),
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: priorityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: const Color(0xFF89889A),
              tooltip: 'Eliminar tarea',
              onPressed: () => _deleteTask(task),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      key: const ValueKey('empty_state'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECECF4)),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFF0EEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              size: 38,
              color: Color(0xFF5548D9),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Un paso a la vez',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF25243A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega tu primera tarea y empieza a organizar tus pendientes.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.45, color: Color(0xFF77768A)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_loaded) return const SizedBox.shrink();

    final highPriorityCount = _tasks
        .where((task) => task.priority == Priority.alta)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF77768A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Mis tareas',
                    style: TextStyle(
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: Color(0xFF25243A),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECECF4)),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF5548D9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6255E7), Color(0xFF4739C6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x225548D9),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu espacio de trabajo',
                      style: TextStyle(
                        color: Color(0xFFDCD9FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_tasks.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _tasks.length == 1
                          ? 'tarea en tu lista'
                          : 'tareas en tu lista',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.format_list_bulleted_rounded,
                label: 'En total',
                value: '${_tasks.length}',
                color: const Color(0xFF5548D9),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.flag_rounded,
                label: 'Prioridad alta',
                value: '$highPriorityCount',
                color: const Color(0xFFCF4C58),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tu lista',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF25243A),
                ),
              ),
            ),
            Text(
              '${_tasks.length} ${_tasks.length == 1 ? 'tarea' : 'tareas'}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF77768A)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_tasks.isEmpty)
          _buildEmptyState()
        else
          ..._tasks.map(_buildTaskCard),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECECF4)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF25243A),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF77768A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7FC),
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 8,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('fab_add_task'),
        onPressed: _addTask,
        tooltip: 'Agregar tarea',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TaskDraft {
  const _TaskDraft(this.description, this.priority);
  final String description;
  final Priority priority;
}

class _TaskFormDialog extends StatefulWidget {
  const _TaskFormDialog();

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  final _controller = TextEditingController();
  Priority _priority = Priority.media;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Escribe una descripción');
      return;
    }
    Navigator.of(context).pop(_TaskDraft(text, _priority));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Nueva tarea',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('input_task_description'),
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Descripción',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Prioridad',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Priority>(
                key: const ValueKey('dropdown_priority'),
                value: _priority,
                isExpanded: true,
                items: Priority.values
                    .map(
                      (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                    )
                    .toList(),
                onChanged: (p) => setState(() => _priority = p ?? _priority),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('btn_save_task'),
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
