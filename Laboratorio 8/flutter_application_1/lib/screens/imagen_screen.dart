import 'dart:io';
import 'package:flutter/material.dart';

class ImagenScreen extends StatelessWidget {
  final String ruta;
  const ImagenScreen({super.key, required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Foto')),
      body: Center(
        child: InteractiveViewer(child: Image.file(File(ruta))),
      ),
    );
  }
}
