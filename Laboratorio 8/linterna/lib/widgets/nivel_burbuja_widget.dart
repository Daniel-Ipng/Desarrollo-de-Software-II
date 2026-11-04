import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class NivelBurbujaWidget extends StatelessWidget {
  final AccelerometerEvent evento;

  const NivelBurbujaWidget({super.key, required this.evento});

  @override
  Widget build(BuildContext context) {
    final nx = (evento.x / 9.8).clamp(-1.0, 1.0);
    final ny = (evento.y / 9.8).clamp(-1.0, 1.0);
    final estaPlano = nx.abs() < 0.05 && ny.abs() < 0.05;

    return CustomPaint(
      size: const Size(200, 200),
      painter: BurbujasPainter(nx: nx, ny: ny, plano: estaPlano),
    );
  }
}

class BurbujasPainter extends CustomPainter {
  final double nx, ny;
  final bool plano;

  BurbujasPainter({required this.nx, required this.ny, required this.plano});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radio = size.width / 2 - 10;

    // Círculo exterior
    canvas.drawCircle(
      Offset(cx, cy),
      radio,
      Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Cruz central de referencia
    final paintLine = Paint()..color = Colors.grey..strokeWidth = 1;
    canvas.drawLine(Offset(cx - 10, cy), Offset(cx + 10, cy), paintLine);
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx, cy + 10), paintLine);

    // Burbuja
    final bx = cx + nx * radio * 0.8;
    final by = cy + ny * radio * 0.8;
    canvas.drawCircle(
      Offset(bx, by),
      20,
      Paint()..color = plano ? Colors.green : Colors.red.shade400,
    );
  }

  @override
  bool shouldRepaint(BurbujasPainter old) =>
      nx != old.nx || ny != old.ny || plano != old.plano;
}