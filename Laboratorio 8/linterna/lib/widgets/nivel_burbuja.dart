import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class NivelBurbujaWidget extends StatelessWidget {
  final AccelerometerEvent evento;
  const NivelBurbujaWidget({super.key, required this.evento});

  @override
  Widget build(BuildContext context) {
    final nx = (evento.x / 9.8).clamp(-1.0, 1.0);
    final ny = (evento.y / 9.8).clamp(-1.0, 1.0);
    final plano = nx.abs() < 0.05 && ny.abs() < 0.05;
    return CustomPaint(
      size: const Size(240, 240),
      painter: _BurbujaPainter(nx: nx, ny: ny, plano: plano),
    );
  }
}

class _BurbujaPainter extends CustomPainter {
  final double nx, ny;
  final bool plano;
  _BurbujaPainter({required this.nx, required this.ny, required this.plano});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final radio = size.width / 2 - 10;
    canvas.drawCircle(
        Offset(cx, cy),
        radio,
        Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final p = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    canvas.drawLine(Offset(cx - 10, cy), Offset(cx + 10, cy), p);
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx, cy + 10), p);
    // La burbuja sube hacia el lado alto, como un nivel real
    final bx = cx - nx * radio * 0.8;
    final by = cy + ny * radio * 0.8;
    canvas.drawCircle(Offset(bx, by), 20,
        Paint()..color = plano ? Colors.green : Colors.red.shade400);
  }

  @override
  bool shouldRepaint(_BurbujaPainter o) =>
      nx != o.nx || ny != o.ny || plano != o.plano;
}
