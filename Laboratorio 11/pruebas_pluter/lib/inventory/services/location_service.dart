/// Devuelve el código de región geográfica del usuario (p. ej. 'PE', 'US').
abstract class LocationService {
  Future<String> getRegionCode();
}
