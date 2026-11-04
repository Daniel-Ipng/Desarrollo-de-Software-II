import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  double minZoom = 1.0;
  double maxZoom = 1.0;

  Future<void> inicializar({ResolutionPreset preset = ResolutionPreset.high}) async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) throw Exception('No se encontraron cámaras');
    await _crearControlador(preset);
  }

  Future<void> _crearControlador(ResolutionPreset preset) async {
    await _controller?.dispose();
    final nuevo = CameraController(
      _cameras[_cameraIndex],
      preset,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = nuevo;
    await nuevo.initialize();
    await nuevo.setFlashMode(FlashMode.auto);
    minZoom = await nuevo.getMinZoomLevel();
    maxZoom = await nuevo.getMaxZoomLevel();
  }

  /// Captura una foto y retorna la ruta del archivo
  Future<String> tomarFoto() async {
    if (!isInitialized) throw Exception('Cámara no inicializada');
    final XFile foto = await _controller!.takePicture();
    return foto.path;
  }

  Future<void> iniciarVideo() async {
    if (!isInitialized || _controller!.value.isRecordingVideo) return;
    await _controller!.startVideoRecording();
  }

  /// Detiene grabación y retorna la ruta del video
  Future<String> detenerVideo() async {
    final XFile video = await _controller!.stopVideoRecording();
    return video.path;
  }

  /// Cambia entre cámara frontal y trasera
  Future<void> cambiarCamara() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _crearControlador(_controller!.resolutionPreset);
  }

  Future<void> setZoom(double nivel) async {
    if (!isInitialized) return;
    await _controller!.setZoomLevel(nivel.clamp(minZoom, maxZoom));
  }

  Future<void> setFlash(FlashMode modo) async {
    if (!isInitialized) return;
    await _controller!.setFlashMode(modo);
  }

  /// Enfoca en el punto tocado (offset normalizado 0.0 a 1.0)
  Future<void> enfocarEn(Offset punto) async {
    if (!isInitialized) return;
    try {
      await _controller!.setFocusPoint(punto);
      await _controller!.setExposurePoint(punto);
    } catch (_) {/* algunos dispositivos no lo soportan */}
  }

  Future<void> dispose() async {
    final c = _controller;
    _controller = null; // evita usar un controlador ya liberado
    await c?.dispose();
  }
}
