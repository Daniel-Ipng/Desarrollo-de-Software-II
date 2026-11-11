import 'package:flutter/material.dart';

import 'todo/sqlite_task_repository.dart';
import 'todo/todo_app.dart';

void main() {
  runApp(TodoApp(repository: SqliteTaskRepository()));
}
