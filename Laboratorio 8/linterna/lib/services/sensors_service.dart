import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorsService {
  // Intervalo de muestreo (20 Hz)
  static const Duration samplingPeriod = Duration(milliseconds: 50);

  // Streams de sensores
  Stream<AccelerometerEvent> get acelerometro =>
      accelerometerEventStream(samplingPeriod: samplingPeriod);

  Stream<UserAccelerometerEvent> get movimiento =>
      userAccelerometerEventStream(samplingPeriod: samplingPeriod);

  Stream<GyroscopeEvent> get giroscopio =>
      gyroscopeEventStream(samplingPeriod: samplingPeriod);

  Stream<MagnetometerEvent> get magnetometro =>
      magnetometerEventStream(samplingPeriod: samplingPeriod);

  /// Calcula la magnitud total de aceleración
  static double magnitud(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  /// Detecta si el dispositivo fue agitado
  static bool esAgitamiento(UserAccelerometerEvent e, {double umbral = 15.0}) {
    return magnitud(e.x, e.y, e.z) > umbral;
  }

  /// Calcula la inclinación (ángulo en grados)
  static double inclinacion(AccelerometerEvent e) {
    return atan2(e.y, sqrt(e.x * e.x + e.z * e.z)) * (180 / pi);
  }
}