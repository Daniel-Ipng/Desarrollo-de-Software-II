import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/sensors_service.dart';

class SensoresScreen extends StatefulWidget {
  const SensoresScreen({super.key});

  @override
  State<SensoresScreen> createState() => _SensoresScreenState();
}

class _SensoresScreenState extends State<SensoresScreen> {
  final SensorsService _service = SensorsService();
  
  AccelerometerEvent? _accel;
  GyroscopeEvent? _gyro;
  UserAccelerometerEvent? _movimiento;
  bool _agitado = false;

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _subs.add(_service.acelerometro.listen((e) {
      if (mounted) setState(() => _accel = e);
    }));

    _subs.add(_service.giroscopio.listen((e) {
      if (mounted) setState(() => _gyro = e);
    }));

    _subs.add(_service.movimiento.listen((e) {
      if (mounted) {
        setState(() {
          _movimiento = e;
          if (SensorsService.esAgitamiento(e)) {
            _agitado = true;
          }
        });
      }
      if (_agitado) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => _agitado = false);
        });
      }
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Widget _fila(String label, double? x, double? y, double? z) {
    String fmt(double? v) => v != null ? v.toStringAsFixed(2) : '-';
    return ListTile(
      leading: const Icon(Icons.sensors),
      title: Text(label),
      subtitle: Text('X: ${fmt(x)}  Y: ${fmt(y)}  Z: ${fmt(z)}'),
      trailing: x != null && y != null && z != null
          ? Text('|${SensorsService.magnitud(x, y, z).toStringAsFixed(1)}|')
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensores de Movimiento')),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _agitado ? Colors.red.shade100 : Colors.transparent,
        child: ListView(
          children: [
            if (_agitado)
              const ListTile(
                leading: Icon(Icons.vibration, color: Colors.red),
                title: Text(
                  'AGITAMIENTO DETECTADO',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            _fila('Acelerómetro (con gravedad)', _accel?.x, _accel?.y, _accel?.z),
            _fila('Movimiento (sin gravedad)', _movimiento?.x, _movimiento?.y, _movimiento?.z),
            _fila('Giroscopio (rad/s)', _gyro?.x, _gyro?.y, _gyro?.z),
            if (_accel != null)
              ListTile(
                title: const Text('Inclinación'),
                subtitle: Text('${SensorsService.inclinacion(_accel!).toStringAsFixed(1)} grados'),
              ),
          ],
        ),
      ),
    );
  }
}