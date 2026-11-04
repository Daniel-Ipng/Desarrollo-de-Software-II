import 'dart:math';
import 'package:flutter/material.dart';
import '../services/brujula_service.dart';

class BrujulaWidget extends StatefulWidget {
  const BrujulaWidget({super.key});

  @override
  State<BrujulaWidget> createState() => _BrujulaWidgetState();
}

class _BrujulaWidgetState extends State<BrujulaWidget> {
  final BrujolaService _brujolaService = BrujolaService();

  @override
  void initState() {
    super.initState();
    _brujolaService.iniciar();
  }

  @override
  void dispose() {
    _brujolaService.detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: _brujolaService.rumboStream,
      builder: (context, snapshot) {
        final rumbo = snapshot.data ?? 0.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${rumbo.toStringAsFixed(1)}°',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Transform.rotate(
              angle: -rumbo * pi / 180,
              child: const Icon(
                Icons.navigation,
                size: 80,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}