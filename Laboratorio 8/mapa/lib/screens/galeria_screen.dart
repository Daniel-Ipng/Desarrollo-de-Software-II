import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/image_picker_helper.dart';
import 'imagen_screen.dart';

class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({super.key});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  final List<File> _imagenes = [];
  String? _video;

  void _aviso(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _uno(ImageSource fuente) async {
    try {
      final f = await ImagePickerHelper.seleccionarImagen(fuente: fuente);
      if (f != null) setState(() => _imagenes.add(f));
    } catch (e) {
      _aviso('Error: $e');
    }
  }

  Future<void> _multiple() async {
    try {
      final fs = await ImagePickerHelper.seleccionarMultiple(limite: 5);
      if (fs.isNotEmpty) setState(() => _imagenes.addAll(fs));
    } catch (e) {
      _aviso('Error: $e');
    }
  }

  Future<void> _video() async {
    try {
      final v = await ImagePickerHelper.grabarVideo(
          duracionMaxima: const Duration(seconds: 30));
      if (v != null) setState(() => _video = v.path);
    } catch (e) {
      _aviso('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selector de imágenes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _uno(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('Galería'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _uno(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cámara'),
                ),
                ElevatedButton.icon(
                  onPressed: _multiple,
                  icon: const Icon(Icons.collections),
                  label: const Text('Varias'),
                ),
                ElevatedButton.icon(
                  onPressed: _video,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Video'),
                ),
              ],
            ),
          ),
          if (_video != null)
            ListTile(
              leading: const Icon(Icons.movie),
              title: const Text('Último video'),
              subtitle: Text(_video!),
            ),
          Expanded(
            child: _imagenes.isEmpty
                ? const Center(child: Text('Aún no hay imágenes'))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: _imagenes.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ImagenScreen(ruta: _imagenes[i].path)),
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
