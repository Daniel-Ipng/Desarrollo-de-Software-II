import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/sensors_service.dart';
import '../widgets/nivel_burbuja.dart';

class NivelScreen extends StatelessWidget {
  const NivelScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nivel de burbuja')),
        body: Center(
          child: StreamBuilder<AccelerometerEvent>(
            stream: SensorsService().acelerometro,
            builder: (c, s) {
              if (!s.hasData) return const CircularProgressIndicator();
              final e = s.data!;
              final plano =
                  (e.x / 9.8).abs() < 0.05 && (e.y / 9.8).abs() < 0.05;
              return Column(mainAxisSize: MainAxisSize.min, children: [
                NivelBurbujaWidget(evento: e),
                const SizedBox(height: 16),
                Text(plano ? 'Superficie plana ✔' : 'Inclinado',
                    style: Theme.of(c).textTheme.titleLarge),
                Text(
                    'Inclinación: ${SensorsService.inclinacion(e).toStringAsFixed(1)}°'),
              ]);
            },
          ),
        ),
      );
}
