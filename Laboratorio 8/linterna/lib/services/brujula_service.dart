import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class BrujolaService {
  late StreamSubscription _magSub;
  late StreamSubscription _accelSub;

  MagnetometerEvent? _mag;
  // ignore: unused_field
  AccelerometerEvent? _accel;

  final StreamController<double> _controller = StreamController<double>.broadcast();
  Stream<double> get rumboStream => _controller.stream;

  void iniciar() {
    _magSub = magnetometerEventStream().listen((e) {
      _mag = e;
      _calcularRumbo();
    });

    _accelSub = accelerometerEventStream().listen((e) {
      _accel = e;
    });
  }

  void _calcularRumbo() {
    if (_mag == null) return;
    // Rumbo simple usando X e Y del magnetómetro
    double rumbo = atan2(_mag!.y, _mag!.x) * (180 / pi);
    if (rumbo < 0) rumbo += 360;
    _controller.add(rumbo);
  }

  void detener() {
    _magSub.cancel();
    _accelSub.cancel();
    _controller.close();
  }
}