import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import 'imagen_screen.dart';

class CamaraScreen extends StatefulWidget {
  const CamaraScreen({super.key});

  @override
  State<CamaraScreen> createState() => _CamaraScreenState();
}

class _CamaraScreenState extends State<CamaraScreen> with WidgetsBindingObserver {
  final _cameraService = CameraService();
  bool _grabando = false;
  double _zoomActual = 1.0;
  double _zoomBase = 1.0;
  FlashMode _flash = FlashMode.auto;
  String? _ultimaFoto;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciarCamara();
  }

  Future<void> _iniciarCamara() async {
    try {
      await _cameraService.inicializar();
      if (mounted) setState(() => _error = null);
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = 'Cámara: ${e.description ?? e.code}');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Liberar cámara cuando la app pasa a segundo plano
    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose().then((_) {
        if (mounted) setState(() {});
      });
    } else if (state == AppLifecycleState.resumed) {
      _iniciarCamara();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _capturar() async {
    try {
      final ruta = await _cameraService.tomarFoto();
      if (mounted) setState(() => _ultimaFoto = ruta);
    } catch (e) {
      _msg('No se pudo tomar la foto: $e');
    }
  }

  Future<void> _toggleVideo() async {
    try {
      if (!_grabando) {
        await _cameraService.iniciarVideo();
        if (mounted) setState(() => _grabando = true);
      } else {
        final ruta = await _cameraService.detenerVideo();
        if (mounted) setState(() => _grabando = false);
        _msg('Video guardado: $ruta');
      }
    } catch (e) {
      _msg('Error de video: $e');
    }
  }

  Future<void> _cambiarFlash() async {
    final siguiente = switch (_flash) {
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.auto,
    };
    await _cameraService.setFlash(siguiente);
    if (mounted) setState(() => _flash = siguiente);
  }

  IconData get _iconoFlash => switch (_flash) {
        FlashMode.auto => Icons.flash_auto,
        FlashMode.always => Icons.flash_on,
        _ => Icons.flash_off,
      };

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cámara')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _iniciarCamara, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      );
    }
    if (!_cameraService.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Preview con enfoque al tocar y zoom con pellizco
            GestureDetector(
              onTapUp: (det) {
                final size = MediaQuery.of(context).size;
                _cameraService.enfocarEn(Offset(
                  det.localPosition.dx / size.width,
                  det.localPosition.dy / size.height,
                ));
              },
              onScaleStart: (_) => _zoomBase = _zoomActual,
              onScaleUpdate: (det) {
                _zoomActual = (_zoomBase * det.scale).clamp(1.0, 8.0);
                _cameraService.setZoom(_zoomActual);
              },
              child: SizedBox.expand(child: CameraPreview(_cameraService.controller!)),
            ),
            Positioned(
              top: 8, right: 8,
              child: IconButton(
                icon: Icon(_iconoFlash, color: Colors.white, size: 28),
                onPressed: _cambiarFlash,
              ),
            ),
            Positioned(
              top: 8, left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 20, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_ultimaFoto != null)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ImagenScreen(ruta: _ultimaFoto!)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_ultimaFoto!),
                            width: 60, height: 60, fit: BoxFit.cover),
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                  // Toque = foto, mantener = iniciar/detener video
                  GestureDetector(
                    onTap: _capturar,
                    onLongPress: _toggleVideo,
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _grabando ? Colors.red : Colors.white24,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 32),
                    onPressed: () async {
                      await _cameraService.cambiarCamara();
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
