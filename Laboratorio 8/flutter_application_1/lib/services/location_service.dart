import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Configuraciones de precisión
  static const LocationSettings _highAccuracy = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // metros mínimos para emitir nueva ubicación
  );
  static const LocationSettings _lowPower = LocationSettings(
    accuracy: LocationAccuracy.low,
    distanceFilter: 50,
  );

  /// Verifica y solicita permisos; lanza excepción si se deniegan
  Future<void> verificarPermisos() async {
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      await Geolocator.openLocationSettings();
      throw Exception('El servicio de GPS está desactivado.');
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado.');
      }
    }
    if (permiso == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception('Permiso denegado permanentemente. Actívalo en Ajustes.');
    }
  }

  /// Obtiene la posición actual (uso puntual)
  Future<Position> obtenerPosicion() async {
    await verificarPermisos();
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  /// Stream de posiciones (uso continuo / rastreo)
  Stream<Position> rastrearPosicion({bool ahorroBateria = false}) {
    return Geolocator.getPositionStream(
      locationSettings: ahorroBateria ? _lowPower : _highAccuracy,
    );
  }

  /// Calcula distancia en metros entre dos puntos
  double calcularDistancia(Position a, Position b) {
    return Geolocator.distanceBetween(
      a.latitude, a.longitude,
      b.latitude, b.longitude,
    );
  }

  /// Geocodificación inversa: coordenadas -> dirección
  Future<String> coordenadasADireccion(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Dirección desconocida';
      final p = placemarks.first;
      return '${p.street}, ${p.locality}, ${p.administrativeArea}, ${p.country}';
    } catch (_) {
      return 'Dirección no disponible';
    }
  }

  /// Geocodificación directa: dirección -> coordenadas
  Future<Location?> direccionACoordenadas(String direccion) async {
    final locations = await locationFromAddress(direccion);
    return locations.isNotEmpty ? locations.first : null;
  }
}
