import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pruebas_pluter/todo/sqlite_task_repository.dart';
import 'package:pruebas_pluter/todo/todo_app.dart';

const _dbName = 'todo_integration_test.db';
const _taskText = 'Entregar reporte de QA a producción';

final _emptyState = find.byKey(const ValueKey('empty_state'));
final _fab = find.byKey(const ValueKey('fab_add_task'));
final _descriptionField = find.byKey(const ValueKey('input_task_description'));
final _priorityDropdown = find.byKey(const ValueKey('dropdown_priority'));
final _saveButton = find.byKey(const ValueKey('btn_save_task'));

/// La base SQLite responde en tiempo real (no en tiempo simulado), por eso
/// se hace polling hasta que el widget aparezca en lugar de confiar solo en
/// pumpAndSettle.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('No apareció $finder en ${timeout.inSeconds} s');
}

Future<void> addTask(
  WidgetTester tester, {
  required String description,
  required String priorityLabel,
}) async {
  await tester.tap(_fab);
  await tester.pumpAndSettle();
  await tester.enterText(_descriptionField, description);
  await tester.pumpAndSettle();
  await tester.tap(_priorityDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(priorityLabel).last);
  await tester.pumpAndSettle();
  await tester.tap(_saveButton);
  await tester.pumpAndSettle();
  await pumpUntilFound(tester, find.text(description));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SqliteTaskRepository repository;

  setUp(() async {
    await SqliteTaskRepository.deleteDb(_dbName); // arranque siempre limpio
    repository = SqliteTaskRepository(dbName: _dbName);
  });

  tearDown(() async {
    await repository.close();
  });

  group('Flujo E2E - Gestión de tareas:', () {
    testWidgets('Crear tarea con prioridad Alta y eliminarla con el botón',
        (WidgetTester tester) async {
      await tester.pumpWidget(TodoApp(repository: repository));
      await tester.pumpAndSettle();

      // 1. Lista inicial vacía.
      await pumpUntilFound(tester, _emptyState);
      expect(_emptyState, findsOneWidget);
      expect(find.byType(ListTile), findsNothing);

      // 2. Abrir el formulario modal con el FAB.
      await tester.tap(_fab);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 3. Descripción + prioridad 'Alta' mediante el Dropdown.
      await tester.enterText(_descriptionField, _taskText);
      await tester.pumpAndSettle();
      await tester.tap(_priorityDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alta').last);
      await tester.pumpAndSettle();

      // 4. Guardar y verificar el ítem con su chip de prioridad.
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.text(_taskText));

      expect(find.text(_taskText), findsOneWidget);
      expect(
        find.descendant(
            of: find.byType(Chip), matching: find.text('Alta')),
        findsOneWidget,
      );
      expect(_emptyState, findsNothing);

      // 5. Eliminar con el botón y volver al estado vacío.
      await tester.tap(find.byTooltip('Eliminar tarea'));
      await tester.pumpAndSettle();

      expect(find.text(_taskText), findsNothing);
      expect(_emptyState, findsOneWidget);
    });

    testWidgets('Eliminar una tarea con el gesto Swipe to Dismiss',
        (WidgetTester tester) async {
      await tester.pumpWidget(TodoApp(repository: repository));
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, _emptyState);

      await addTask(tester, description: _taskText, priorityLabel: 'Alta');
      expect(find.text(_taskText), findsOneWidget);

      await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(find.text(_taskText), findsNothing);
      expect(_emptyState, findsOneWidget);
    });
  });
}
