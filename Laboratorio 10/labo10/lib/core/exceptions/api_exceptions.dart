/// Jerarquía de errores de la API (clase `sealed`: los `switch` deben ser exhaustivos).
sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Sin conexión a internet / servidor inaccesible.
class NetworkException extends ApiException {
  const NetworkException()
      : super('No se pudo conectar. Verifica tu red o que el servidor esté activo.');
}

/// La petición tardó demasiado.
class TimeoutException extends ApiException {
  const TimeoutException()
      : super('La petición tardó demasiado. Intenta de nuevo.');
}

/// 401 / 403: credenciales inválidas o sesión expirada.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([String? message])
      : super(message ?? 'Sesión expirada. Por favor inicia sesión.');
}

/// 4xx con mensaje del servidor (datos inválidos, correo duplicado, etc.).
class ValidationException extends ApiException {
  final int statusCode;
  const ValidationException(super.message, [this.statusCode = 400]);
}

/// 5xx, 404, 429...
class ServerException extends ApiException {
  final int statusCode;
  const ServerException(this.statusCode, super.message);
}

/// La respuesta no tiene el formato esperado.
class ParseException extends ApiException {
  final String details; // solo para logging, nunca se muestra al usuario
  const ParseException(this.details)
      : super('No pudimos procesar la respuesta del servidor.');
}

/// Error inesperado.
class UnknownException extends ApiException {
  final String details;
  const UnknownException(this.details) : super('Ocurrió un error inesperado.');
}
