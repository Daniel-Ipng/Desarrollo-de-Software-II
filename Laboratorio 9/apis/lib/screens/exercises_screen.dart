import 'package:flutter/material.dart';

import 'dio_demo_screen.dart';
import 'graphql_posts_screen.dart';
import 'paginated_posts_screen.dart';
import '../widgets/liquid_glass.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Ejercicios propuestos'),
          flexibleSpace: const LiquidGlassAppBar(),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            GlassPanel(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.bolt, color: Color(0xFF8BE9E5)),
                title: const Text('1. Dio'),
                subtitle: const Text('Interceptores, reintentos, cancelación'),
                onTap: () => _open(context, const DioDemoScreen()),
              ),
            ),
            const GlassPanel(
              margin: EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(Icons.science, color: Color(0xFF8BE9E5)),
                title: Text('2. Pruebas unitarias (mockito)'),
                subtitle: Text('Se ejecutan con: flutter test'),
              ),
            ),
            GlassPanel(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.hub, color: Color(0xFF8BE9E5)),
                title: const Text('3. GraphQL'),
                subtitle: const Text('graphql_flutter vs REST'),
                onTap: () => _open(context, const GraphqlPostsScreen()),
              ),
            ),
            GlassPanel(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(
                  Icons.format_list_numbered,
                  color: Color(0xFF8BE9E5),
                ),
                title: const Text('4. Paginación'),
                subtitle: const Text('Páginas numéricas con REST'),
                onTap: () => _open(context, const PaginatedPostsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
