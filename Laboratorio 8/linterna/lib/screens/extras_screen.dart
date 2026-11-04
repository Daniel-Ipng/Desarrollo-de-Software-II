import 'dart:math';
import 'package:flutter/material.dart';
import '../services/brujula_service.dart';
import '../services/pedometro_service.dart';
import '../services/linterna_service.dart';

class ExtrasScreen extends StatefulWidget {
  const ExtrasScreen({super.key});
  @override
  State<ExtrasScreen> createState() => _ExtrasScreenState();
}

class _ExtrasScreenState extends State<ExtrasScreen> {
  final _brujula = BrujulaService();
  final _pedometro = PedometroService();
  final _linterna = LinternaService();

  int _pasos = 0;
  String _estado = 'parado';
  String? _error;

  @override
  void initState() {
    super.initState();
    _brujula.iniciar();
    _pedometro.iniciar(
      onPasos: (p) {
        if (mounted) setState(() => _pasos = p);
      },
      onEstado: (s) {
        if (mounted) setState(() => _estado = s);
      },
      onError: (e) {
        if (mounted) setState(() => _error = e);
      },
    );
  }

  @override
  void dispose() {
    _brujula.detener();
    _pedometro.detener();
    _linterna.apagar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Brújula, pasos y linterna')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<double>(
                stream: _brujula.rumboStream,
                builder: (c, s) {
                  final rumbo = s.data ?? 0.0;
                  return Column(children: [
                    Transform.rotate(
                      angle: -rumbo * pi / 180,
                      child: const Icon(Icons.navigation,
                          size: 90, color: Colors.red),
                    ),
                    Text(
                        '${rumbo.toStringAsFixed(0)}° ${BrujulaService.punto(rumbo)}',
                        style: Theme.of(c).textTheme.headlineSmall),
                    const Text('Mantén el celular casi horizontal',
                        style: TextStyle(color: Colors.grey)),
                  ]);
                },
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(_estado == 'caminando'
                  ? Icons.directions_walk
                  : Icons.accessibility_new),
              title: Text('$_pasos pasos ($_estado)'),
              subtitle: Text(_error ??
                  '${PedometroService.distanciaMetros(_pasos).toStringAsFixed(0)} m · '
                      '${PedometroService.calorias(_pasos).toStringAsFixed(1)} kcal aprox.'),
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: Icon(_linterna.encendida
                  ? Icons.flashlight_on
                  : Icons.flashlight_off),
              title: const Text('Linterna'),
              value: _linterna.encendida,
              onChanged: (_) async {
                await _linterna.toggle();
                if (mounted) setState(() {});
              },
            ),
          ),
        ]),
      );
}
