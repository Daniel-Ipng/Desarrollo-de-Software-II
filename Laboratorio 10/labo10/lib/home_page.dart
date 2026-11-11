import 'package:flutter/material.dart';

import 'ejercicio1_clima/weather_screen.dart';
import 'features/auth/presentation/auth_gate.dart';

/// Menú para entrar a cada ejercicio de la práctica.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Práctica 10 - Flutter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.wb_sunny_outlined, size: 36),
              title: const Text('Ejercicio 1'),
              subtitle: const Text('App de clima: manejo de errores y estados'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeatherScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.task_alt, size: 36),
              title: const Text('Ejercicio 2'),
              subtitle: const Text('To-Do con JWT, Dio, interceptores y Riverpod'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthGate()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
