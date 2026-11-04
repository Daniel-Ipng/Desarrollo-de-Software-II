import 'package:flutter/material.dart';
import 'screens/mapa_screen.dart';
import 'screens/camara_screen.dart';
import 'screens/galeria_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Práctica 08',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _ir(BuildContext context, Widget pantalla) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Práctica 08 - GPS y Cámara')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.map, color: Colors.teal),
            title: const Text('Mapa y rastreo GPS'),
            subtitle: const Text('Ubicación, marcadores y ruta en tiempo real'),
            onTap: () => _ir(context, const MapaScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.teal),
            title: const Text('Cámara'),
            subtitle: const Text('Preview, foto, video, zoom y flash'),
            onTap: () => _ir(context, const CamaraScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.teal),
            title: const Text('Selector de imágenes'),
            subtitle: const Text('image_picker: galería, cámara y video'),
            onTap: () => _ir(context, const GaleriaScreen()),
          ),
        ],
      ),
    );
  }
}
