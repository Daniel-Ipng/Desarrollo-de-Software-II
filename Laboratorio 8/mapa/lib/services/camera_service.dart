import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> inicializar({ResolutionPreset preset = ResolutionPreset.high}) async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) throw Exception('No se encontraron cámaras');
    await _crearControlador(preset);
  }

  Future<void> _crearControlador(ResolutionPreset preset) async {
    await _controller?.dispose();
    _controller = CameraController(
      _cameras[_cameraIndex],
      preset,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();
    await _controller!.setFlashMode(FlashMode.auto);
  }

  /// Captura una foto, la copia a la carpeta de la app y retorna la ruta.
  Future<String> tomarFoto() async {
    if (!isInitialized) throw Exception('Cámara no inicializada');
    final XFile foto = await _controller!.takePicture();
    final dir = await getApplicationDocumentsDirectory();
    final carpeta = Directory('${dir.path}/fotos');
    if (!await carpeta.exists()) await carpeta.create(recursive: true);
    final destino =
        '${carpeta.path}/foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(foto.path).copy(destino);
    return destino;
  }

  Future<void> iniciarVideo() async {
    if (!isInitialized || _controller!.value.isRecordingVideo) return;
    await _controller!.startVideoRecording();
  }

  Future<String> detenerVideo() async {
    final XFile video = await _controller!.stopVideoRecording();
    return video.path;
  }

  Future<void> cambiarCamara() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _crearControlador(_controller!.resolutionPreset);
  }

  Future<void> setFlash(FlashMode modo) async {
    await _controller?.setFlashMode(modo);
  }

  Future<double> get zoomMin async => _controller!.getMinZoomLevel();
  Future<double> get zoomMax async => _controller!.getMaxZoomLevel();

  /// Ajusta el zoom (1.0 = sin zoom)
  Future<void> setZoom(double nivel) async {
    final max = await _controller!.getMaxZoomLevel();
    final min = await _controller!.getMinZoomLevel();
    await _controller!.setZoomLevel(nivel.clamp(min, max));
  }

  /// Enfoca en el punto tocado (offset normalizado 0.0 a 1.0)
  Future<void> enfocarEn(Offset punto) async {
    try {
      await _controller!.setFocusPoint(punto);
      await _controller!.setExposurePoint(punto);
    } catch (_) {
      // Algunos dispositivos/cámaras no soportan enfoque manual
    }
  }

  Future<void> dispose() async {
    final c = _controller;
    _controller = null;
    await c?.dispose();
  }
}
