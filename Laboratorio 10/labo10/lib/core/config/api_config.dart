/// Configuración de la API del Ejercicio 2.
class ApiConfig {
  ApiConfig._();

  /// 10.0.2.2 = tu PC visto desde el emulador de Android.
  /// En celular físico:  flutter run --dart-define=API_BASE_URL=http://192.168.X.X:3000
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Claves de `RequestOptions.extra`.
  static const String skipAuthKey = 'skipAuth'; // endpoints públicos (login, register...)
  static const String retriedKey = 'retried'; // la petición ya se reintentó tras refrescar
}
