import 'dart:async';
import 'package:pedometer/pedometer.dart';

class PedometroService {
  late StreamSubscription<StepCount> _pasosSub;
  late StreamSubscription<PedestrianStatus> _estadoSub;

  int pasosHoy = 0;
  String estado = 'parado';

  void iniciar({
    required Function(int pasos) onPasos,
    required Function(String estado) onEstado,
  }) {
    _pasosSub = Pedometer.stepCountStream.listen(
      (event) {
        pasosHoy = event.steps;
        onPasos(pasosHoy);
      },
      onError: (e) => print('Error pedómetro: $e'),
    );

    _estadoSub = Pedometer.pedestrianStatusStream.listen(
      (event) {
        estado = event.status;
        onEstado(estado);
      },
      onError: (e) => print('Error estado pedómetro: $e'),
    );
  }

  void detener() {
    _pasosSub.cancel();
    _estadoSub.cancel();
  }

  double caloriasAproximadas(int pasos, {double pesoKg = 70.0}) {
    return pasos * 0.04 * pesoKg / 70;
  }

  double distanciaMetros(int pasos, {double longitudPasoM = 0.75}) {
    return pasos * longitudPasoM;
  }
}