import 'package:torch_light/torch_light.dart';

class LinternaService {
  bool _encendida = false;
  bool get encendida => _encendida;

  Future<bool> toggleLinterna() async {
    try {
      if (_encendida) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      _encendida = !_encendida;
      return _encendida;
    } catch (e) {
      return false; // Dispositivo sin linterna o error
    }
  }

  Future<void> apagar() async {
    if (_encendida) {
      try {
        await TorchLight.disableTorch();
      } catch (_) {}
    }
    _encendida = false;
  }
}