// lib/services/location_service.dart
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Excepción propia para poder mostrar mensajes claros y ofrecer acciones
/// (abrir ajustes de GPS o de la app).
enum LocationError { gpsDesactivado, permisoDenegado, permisoDenegadoPermanente }

class LocationException implements Exception {
  final LocationError tipo;
  final String mensaje;
  LocationException(this.tipo, this.mensaje);

  @override
  String toString() => mensaje;
}

class LocationService {
  // Perfil de alta precisión (rastreo normal)
  static const LocationSettings _altaPrecision = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // metros mínimos para emitir una nueva posición
  );

  // Perfil de ahorro de batería
  static const LocationSettings _ahorroBateria = LocationSettings(
    accuracy: LocationAccuracy.low,
    distanceFilter: 50,
  );

  /// Verifica GPS y permisos; lanza [LocationException] si algo falla.
  Future<void> verificarPermisos() async {
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      throw LocationException(
          LocationError.gpsDesactivado, 'El servicio de GPS está desactivado.');
    }

    var permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw LocationException(
            LocationError.permisoDenegado, 'Permiso de ubicación denegado.');
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      throw LocationException(LocationError.permisoDenegadoPermanente,
          'Permiso denegado permanentemente. Actívalo desde los ajustes.');
    }
  }

  Future<void> abrirAjustesGps() => Geolocator.openLocationSettings();
  Future<void> abrirAjustesApp() => Geolocator.openAppSettings();

  /// Posición actual (uso puntual)
  Future<Position> obtenerPosicion() async {
    await verificarPermisos();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Stream de posiciones (rastreo continuo)
  Future<Stream<Position>> rastrearPosicion({bool ahorroBateria = false}) async {
    await verificarPermisos();
    return Geolocator.getPositionStream(
      locationSettings: ahorroBateria ? _ahorroBateria : _altaPrecision,
    );
  }

  /// Distancia en metros entre dos coordenadas
  double distanciaEntre(double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);

  /// Geocodificación inversa: coordenadas -> dirección
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

  /// Geocodificación directa: dirección -> coordenadas
  Future<Location?> direccionACoordenadas(String direccion) async {
    final locations = await locationFromAddress(direccion);
    return locations.isNotEmpty ? locations.first : null;
  }
}
