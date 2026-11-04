import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Errores propios para poder reaccionar distinto en la UI.
enum UbicacionError { gpsApagado, denegado, denegadoPermanente }

class UbicacionException implements Exception {
  final UbicacionError tipo;
  final String mensaje;
  UbicacionException(this.tipo, this.mensaje);
  @override
  String toString() => mensaje;
}

class LocationService {
  // Perfiles de precisión
  static const LocationSettings _altaPrecision = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // metros mínimos para emitir nueva ubicación
  );
  static const LocationSettings _ahorroBateria = LocationSettings(
    accuracy: LocationAccuracy.low,
    distanceFilter: 50,
  );

  /// Verifica servicio GPS y permisos; lanza [UbicacionException] si falla.
  Future<void> verificarPermisos() async {
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      throw UbicacionException(
          UbicacionError.gpsApagado, 'El servicio de GPS está desactivado.');
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw UbicacionException(
            UbicacionError.denegado, 'Permiso de ubicación denegado.');
      }
    }
    if (permiso == LocationPermission.deniedForever) {
      throw UbicacionException(UbicacionError.denegadoPermanente,
          'Permiso denegado permanentemente. Actívalo en Ajustes.');
    }
  }

  Future<void> abrirAjustesApp() => Geolocator.openAppSettings();
  Future<void> abrirAjustesGps() => Geolocator.openLocationSettings();

  /// Posición puntual.
  Future<Position> obtenerPosicion() async {
    await verificarPermisos();
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  /// Flujo continuo (rastreo).
  Stream<Position> rastrearPosicion({bool ahorroBateria = false}) {
    return Geolocator.getPositionStream(
      locationSettings: ahorroBateria ? _ahorroBateria : _altaPrecision,
    );
  }

  /// Distancia en metros entre dos puntos.
  double calcularDistancia(Position a, Position b) => Geolocator.distanceBetween(
      a.latitude, a.longitude, b.latitude, b.longitude);

  /// Geocodificación inversa: coordenadas -> dirección.
  Future<String> coordenadasADireccion(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Dirección desconocida';
      final p = placemarks.first;
      return [p.street, p.locality, p.administrativeArea, p.country]
          .where((e) => e != null && e.isNotEmpty)
          .join(', ');
    } catch (_) {
      return 'Dirección no disponible';
    }
  }

  /// Geocodificación directa: dirección -> coordenadas.
  Future<Location?> direccionACoordenadas(String direccion) async {
    final locations = await locationFromAddress(direccion);
    return locations.isNotEmpty ? locations.first : null;
  }
}
