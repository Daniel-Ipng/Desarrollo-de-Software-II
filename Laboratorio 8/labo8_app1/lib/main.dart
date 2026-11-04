import 'package:flutter/material.dart';
import 'screens/mapa_screen.dart';
import 'screens/camara_screen.dart';
import 'screens/galeria_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Práctica 08.1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const InicioScreen(),
    );
  }
}

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void ir(Widget pantalla) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

    return Scaffold(
      appBar: AppBar(title: const Text('Práctica 08.1 - GPS y Cámara')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.map, color: Colors.teal),
              title: const Text('Mapa y GPS'),
              subtitle: const Text('Ubicación, rastreo de ruta y marcadores'),
              onTap: () => ir(const MapaScreen()),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.teal),
              title: const Text('Cámara'),
              subtitle: const Text('Fotos, video, zoom, flash y enfoque'),
              onTap: () => ir(const CamaraScreen()),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.teal),
              title: const Text('Selector de imágenes'),
              subtitle: const Text('image_picker: galería, cámara y video'),
              onTap: () => ir(const GaleriaScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
