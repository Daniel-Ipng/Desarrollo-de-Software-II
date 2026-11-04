import 'package:flutter/material.dart';
import 'screens/sensores_screen.dart';
import 'widgets/brujula_widget.dart';
import 'services/linterna_service.dart';
import 'services/pedometro_service.dart';

void main() {
  runApp(const MiAppSensores());
}

class MiAppSensores extends StatelessWidget {
  const MiAppSensores({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Práctica Sensores',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MenuPrincipalScreen(),
    );
  }
}

class MenuPrincipalScreen extends StatefulWidget {
  const MenuPrincipalScreen({super.key});

  @override
  State<MenuPrincipalScreen> createState() => _MenuPrincipalScreenState();
}

class _MenuPrincipalScreenState extends State<MenuPrincipalScreen> {
  final LinternaService _linternaService = LinternaService();
  final PedometroService _pedometroService = PedometroService();

  bool _linternaEncendida = false;
  int _pasos = 0;
  String _estadoPedometro = 'parado';

  @override
  void initState() {
    super.initState();
    // Iniciar escucha del pedómetro
    _pedometroService.iniciar(
      onPasos: (pasos) {
        if (mounted) setState(() => _pasos = pasos);
      },
      onEstado: (estado) {
        if (mounted) setState(() => _estadoPedometro = estado);
      },
    );
  }

  @override
  void dispose() {
    _pedometroService.detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Integración de Sensores'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sensors), text: 'Movimiento'),
              Tab(icon: Icon(Icons.explore), text: 'Brújula'),
              Tab(icon: Icon(Icons.directions_walk), text: 'Extra'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña 1: Sensores de movimiento (Acelerómetro, Giroscopio)
            const SensoresScreen(),

            // Pestaña 2: Brújula
            const Center(child: BrujulaWidget()),

            // Pestaña 3: Pedómetro y Linterna
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Módulo Pedómetro
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.directions_walk, size: 40),
                      title: Text('Pasos detectados: $_pasos'),
                      subtitle: Text('Estado: $_estadoPedometro\n'
                          'Calorías aprox: ${_pedometroService.caloriasAproximadas(_pasos).toStringAsFixed(1)} kcal'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Módulo Linterna
                  ElevatedButton.icon(
                    icon: Icon(_linternaEncendida ? Icons.flash_off : Icons.flash_on),
                    label: Text(_linternaEncendida ? 'Apagar Linterna' : 'Encender Linterna'),
                    onPressed: () async {
                      bool estado = await _linternaService.toggleLinterna();
                      if (mounted) {
                        setState(() => _linternaEncendida = estado);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}