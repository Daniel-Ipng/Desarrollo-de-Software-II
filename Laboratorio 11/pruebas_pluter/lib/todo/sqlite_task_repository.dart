import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'task.dart';
import 'task_repository.dart';

class SqliteTaskRepository implements TaskRepository {
  SqliteTaskRepository({this.dbName = 'todo.db'});

  final String dbName;
  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), dbName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE tasks('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'description TEXT NOT NULL, '
        'priority TEXT NOT NULL)',
      ),
    );
  }

  @override
  Future<List<Task>> getAll() async {
    final db = await _database;
    final rows = await db.query('tasks', orderBy: 'id ASC');
    return rows
        .map((r) => Task(
              id: r['id'] as int,
              description: r['description'] as String,
              priority: Priority.values.byName(r['priority'] as String),
            ))
        .toList();
  }

  @override
  Future<Task> add(String description, Priority priority) async {
    final db = await _database;
    final id = await db.insert('tasks', {
      'description': description,
      'priority': priority.name,
    });
    return Task(id: id, description: description, priority: priority);
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Borra por completo el archivo de base de datos (útil en pruebas).
  static Future<void> deleteDb(String dbName) async {
    await deleteDatabase(p.join(await getDatabasesPath(), dbName));
  }
}
