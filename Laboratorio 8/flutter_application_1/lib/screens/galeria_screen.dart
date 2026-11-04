import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_picker_helper.dart';
import 'imagen_screen.dart';

class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({super.key});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  final List<File> _imagenes = [];
  String? _video;

  Future<void> _ejecutar(Future<void> Function() accion) async {
    try {
      await accion();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selector de imágenes')),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _ejecutar(() async {
                  final f = await ImagePickerHelper.seleccionarImagen();
                  if (f != null) setState(() => _imagenes.add(f));
                }),
                child: const Text('Galería'),
              ),
              ElevatedButton(
                onPressed: () => _ejecutar(() async {
                  final f = await ImagePickerHelper.seleccionarImagen(
                      fuente: ImageSource.camera);
                  if (f != null) setState(() => _imagenes.add(f));
                }),
                child: const Text('Cámara'),
              ),
              ElevatedButton(
                onPressed: () => _ejecutar(() async {
                  final lista = await ImagePickerHelper.seleccionarMultiple();
                  setState(() => _imagenes.addAll(lista));
                }),
                child: const Text('Múltiple'),
              ),
              ElevatedButton(
                onPressed: () => _ejecutar(() async {
                  final v = await ImagePickerHelper.grabarVideo(
                      duracionMaxima: const Duration(seconds: 30));
                  if (v != null) setState(() => _video = v.path);
                }),
                child: const Text('Video'),
              ),
            ],
          ),
          if (_video != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Video: $_video', style: const TextStyle(fontSize: 12)),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
              itemCount: _imagenes.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ImagenScreen(ruta: _imagenes[i].path)),
                ),
                child: Image.file(_imagenes[i], fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
