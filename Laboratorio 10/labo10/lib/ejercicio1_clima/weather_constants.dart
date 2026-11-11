/// Configuración y textos del Ejercicio 1 (sin "magic strings" en el resto del código).
class WeatherConfig {
  WeatherConfig._();

  /// Se puede pasar con:  flutter run --dart-define=OPENWEATHER_API_KEY=tu_clave
  /// o pegar tu clave aquí en `defaultValue` (no la subas a git).
  static const String apiKey =
      String.fromEnvironment('OPENWEATHER_API_KEY', defaultValue: '');

  static const String host = 'api.openweathermap.org';
  static const String currentWeatherPath = '/data/2.5/weather';
  static const String units = 'metric';
  static const String lang = 'es';

  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration cacheDuration = Duration(minutes: 5);
  static const Duration debounceDuration = Duration(milliseconds: 500);
  static const int minCityLength = 3;

  static const String lastCityPrefsKey = 'last_city';

  static String iconUrl(String icon) =>
      'https://openweathermap.org/img/wn/$icon@2x.png';
}

class WeatherStrings {
  WeatherStrings._();

  static const String title = 'Clima - Ejercicio 1';
  static const String cityLabel = 'Ciudad';
  static const String cityHint = 'Ej: Cusco';
  static const String minLengthError = 'Escribe al menos 3 caracteres';
  static const String emptyInputError = 'Escribe el nombre de una ciudad';
  static const String emptyTitle = 'Busca una ciudad';
  static const String emptyMessage =
      'Escribe el nombre de una ciudad para ver su clima actual.';
  static const String loading = 'Consultando clima de';
  static const String retry = 'Reintentar';
  static const String refresh = 'Actualizar';
  static const String savedCity = 'Última ciudad guardada';
}
