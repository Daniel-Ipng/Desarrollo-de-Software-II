import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/camera_service.dart';
import 'imagen_screen.dart';

class CamaraScreen extends StatefulWidget {
  const CamaraScreen({super.key});

  @override
  State<CamaraScreen> createState() => _CamaraScreenState();
}

class _CamaraScreenState extends State<CamaraScreen>
    with WidgetsBindingObserver {
  final _cameraService = CameraService();
  bool _grabando = false;
  bool _permisosOk = false;
  bool _permisoPermanente = false;
  String? _error;
  double _zoomActual = 1.0;
  double _zoomBase = 1.0;
  FlashMode _flash = FlashMode.auto;
  String? _ultimaFoto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciar();
  }

  Future<void> _iniciar() async {
    final estados =
        await [Permission.camera, Permission.microphone].request();
    final cam = estados[Permission.camera]!;
    final mic = estados[Permission.microphone]!;

    if (!cam.isGranted || !mic.isGranted) {
      if (!mounted) return;
      setState(() {
        _permisosOk = false;
        _permisoPermanente = cam.isPermanentlyDenied || mic.isPermanentlyDenied;
        _error = 'Se necesitan permisos de cámara y micrófono.';
      });
      return;
    }

    try {
      await _cameraService.inicializar();
      _zoomActual = 1.0;
      if (!mounted) return;
      setState(() {
        _permisosOk = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Liberar la cámara cuando la app pasa a segundo plano
    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose().then((_) {
        if (mounted) setState(() {});
      });
    } else if (state == AppLifecycleState.resumed) {
      _iniciar();
    }
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _capturar() async {
    try {
      final ruta = await _cameraService.tomarFoto();
      if (mounted) setState(() => _ultimaFoto = ruta);
    } catch (e) {
      _aviso('No se pudo tomar la foto: $e');
    }
  }

  Future<void> _toggleVideo() async {
    try {
      if (!_grabando) {
        await _cameraService.iniciarVideo();
        setState(() => _grabando = true);
      } else {
        final ruta = await _cameraService.detenerVideo();
        setState(() => _grabando = false);
        _aviso('Video guardado: $ruta');
      }
    } catch (e) {
      setState(() => _grabando = false);
      _aviso('Error de video: $e');
    }
  }

  Future<void> _cambiarFlash() async {
    final siguiente = switch (_flash) {
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.auto,
    };
    await _cameraService.setFlash(siguiente);
    setState(() => _flash = siguiente);
  }

  IconData get _iconoFlash => switch (_flash) {
        FlashMode.auto => Icons.flash_auto,
        FlashMode.always => Icons.flash_on,
        _ => Icons.flash_off,
      };

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _permisoPermanente ? openAppSettings : _iniciar,
                  child: Text(_permisoPermanente
                      ? 'Abrir ajustes'
                      : 'Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_permisosOk || !_cameraService.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Preview con enfoque al tocar y zoom con pellizco
            LayoutBuilder(builder: (context, c) {
              return GestureDetector(
                onTapUp: (det) => _cameraService.enfocarEn(Offset(
                  det.localPosition.dx / c.maxWidth,
                  det.localPosition.dy / c.maxHeight,
                )),
                onScaleStart: (_) => _zoomBase = _zoomActual,
                onScaleUpdate: (det) {
                  _zoomActual = (_zoomBase * det.scale).clamp(1.0, 8.0);
                  _cameraService.setZoom(_zoomActual);
                },
                child: SizedBox.expand(
                  child: Center(
                      child: CameraPreview(_cameraService.controller!)),
                ),
              );
            }),
            // Botón atrás + flash
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (_grabando)
                    const Row(children: [
                      Icon(Icons.fiber_manual_record, color: Colors.red),
                      SizedBox(width: 4),
                      Text('REC', style: TextStyle(color: Colors.white)),
                    ]),
                  IconButton(
                    icon: Icon(_iconoFlash, color: Colors.white),
                    onPressed: _cambiarFlash,
                  ),
                ],
              ),
            ),
            // Controles inferiores
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_ultimaFoto != null)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ImagenScreen(ruta: _ultimaFoto!)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_ultimaFoto!),
                            width: 60, height: 60, fit: BoxFit.cover),
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                  // Toque = foto, pulsación larga = iniciar/detener video
                  GestureDetector(
                    onTap: _capturar,
                    onLongPress: _toggleVideo,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _grabando ? Colors.red : Colors.white24,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios,
                        color: Colors.white, size: 32),
                    onPressed: () async {
                      await _cameraService.cambiarCamara();
                      _zoomActual = 1.0;
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
