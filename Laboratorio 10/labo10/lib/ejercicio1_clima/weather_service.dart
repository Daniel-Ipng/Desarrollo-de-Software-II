import 'dart:async' as async;
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import 'weather.dart';
import 'weather_constants.dart';
import 'weather_exceptions.dart';

/// Entrada de caché con marca de tiempo.
class _CacheEntry {
  final Weather weather;
  final DateTime savedAt;
  const _CacheEntry(this.weather, this.savedAt);

  bool get isExpired =>
      DateTime.now().difference(savedAt) > WeatherConfig.cacheDuration;
}

/// Consume la API de OpenWeatherMap con manejo completo de errores.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Caché en memoria (bonus): evita repetir la petición por 5 minutos.
  final Map<String, _CacheEntry> _cache = {};

  Future<Weather> getWeather(String city, {bool forceRefresh = false}) async {
    final name = city.trim();
    final key = name.toLowerCase();

    if (!forceRefresh) {
      final cached = _cache[key];
      if (cached != null && !cached.isExpired) return cached.weather;
    }

    final weather = await _fetch(name);
    _cache[key] = _CacheEntry(weather, DateTime.now());
    return weather;
  }

  /// Invalidación manual de la caché.
  void clearCache() => _cache.clear();

  Future<Weather> _fetch(String city) async {
    if (WeatherConfig.apiKey.isEmpty) throw const ApiKeyException();

    // Uri.https codifica correctamente la ciudad (espacios, tildes, etc.).
    final uri = Uri.https(WeatherConfig.host, WeatherConfig.currentWeatherPath, {
      'q': city,
      'appid': WeatherConfig.apiKey,
      'units': WeatherConfig.units,
      'lang': WeatherConfig.lang,
    });

    try {
      final response =
          await _client.get(uri).timeout(WeatherConfig.requestTimeout);

      return switch (response.statusCode) {
        200 => _parse(response.body),
        401 => throw const ApiKeyException(),
        404 => throw CityNotFoundException(city),
        _ => throw ServerException(response.statusCode),
      };
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on async.TimeoutException {
      throw const TimeoutException();
    }
  }

  Weather _parse(String body) {
    try {
      return Weather.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } catch (_) {
      throw const ParseException();
    }
  }

  void dispose() => _client.close();
}
