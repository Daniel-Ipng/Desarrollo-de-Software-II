import 'package:flutter/foundation.dart';

import 'weather.dart';
import 'weather_constants.dart';
import 'weather_exceptions.dart';
import 'weather_service.dart';
import 'weather_storage.dart';

/// Estados de la UI: Empty, Loading, Success y Error.
sealed class WeatherState {
  const WeatherState();
}

class WeatherEmpty extends WeatherState {
  const WeatherEmpty();
}

class WeatherLoading extends WeatherState {
  final String city;
  const WeatherLoading(this.city);
}

class WeatherSuccess extends WeatherState {
  final Weather weather;
  final String query;
  const WeatherSuccess(this.weather, this.query);
}

class WeatherError extends WeatherState {
  final WeatherException error;
  final String city;
  const WeatherError(this.error, this.city);
}

class WeatherController extends ChangeNotifier {
  WeatherController({required this.service, required this.storage});

  final WeatherService service;
  final WeatherStorage storage;

  WeatherState _state = const WeatherEmpty();
  WeatherState get state => _state;

  String? _lastCity;
  String? get lastCity => _lastCity;

  int _requestId = 0; // descarta respuestas de búsquedas antiguas
  bool _disposed = false;

  /// Lee la última ciudad guardada (SharedPreferences).
  Future<String?> restoreLastCity() async {
    final saved = await storage.loadLastCity();
    if (saved != null && saved.isNotEmpty) {
      _lastCity = saved;
      _emit();
      return saved;
    }
    return null;
  }

  Future<void> search(String city, {bool forceRefresh = false}) async {
    final query = city.trim();
    if (query.length < WeatherConfig.minCityLength) return;

    final requestId = ++_requestId;
    _state = WeatherLoading(query);
    _emit();

    try {
      final weather = await service.getWeather(query, forceRefresh: forceRefresh);
      if (requestId != _requestId) return;

      await storage.saveLastCity(query);
      _lastCity = query;
      _state = WeatherSuccess(weather, query);
    } on WeatherException catch (e) {
      if (requestId != _requestId) return;
      _state = WeatherError(e, query);
    } catch (_) {
      if (requestId != _requestId) return;
      _state = WeatherError(const UnknownException(), query);
    }
    _emit();
  }

  /// Botón "Reintentar": repite la búsqueda ignorando la caché.
  Future<void> retry() async {
    final current = _state;
    if (current is WeatherError) {
      await search(current.city, forceRefresh: true);
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
