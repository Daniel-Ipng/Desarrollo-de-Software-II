/// Jerarquía de errores del Ejercicio 1.
/// Es `sealed`: el compilador obliga a manejar todos los casos en un `switch`.
sealed class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);

  @override
  String toString() => message;
}

/// Sin conexión a internet.
class NetworkException extends WeatherException {
  const NetworkException()
      : super('Sin conexión a internet. Verifica tu red e intenta de nuevo.');
}

/// La petición superó el tiempo máximo de espera.
class TimeoutException extends WeatherException {
  const TimeoutException()
      : super('La petición tardó demasiado. Intenta de nuevo.');
}

/// API key inválida (401) o no configurada.
class ApiKeyException extends WeatherException {
  const ApiKeyException()
      : super('API key inválida o no configurada. Revisa tu clave de OpenWeatherMap.');
}

/// La ciudad no existe (404).
class CityNotFoundException extends WeatherException {
  final String city;
  CityNotFoundException(this.city)
      : super('No encontramos la ciudad "$city". Revisa el nombre.');
}

/// Otro error del servidor (5xx, 429, etc.).
class ServerException extends WeatherException {
  final int statusCode;
  ServerException(this.statusCode)
      : super('El servicio del clima no está disponible ($statusCode). Intenta más tarde.');
}

/// La respuesta no tiene el formato esperado.
class ParseException extends WeatherException {
  const ParseException()
      : super('No pudimos procesar la respuesta del servicio del clima.');
}

/// Cualquier error inesperado.
class UnknownException extends WeatherException {
  const UnknownException() : super('Ocurrió un error inesperado.');
}
