import 'package:shared_preferences/shared_preferences.dart';

import 'weather_constants.dart';

/// Guarda y recupera la última ciudad buscada.
class WeatherStorage {
  Future<String?> loadLastCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(WeatherConfig.lastCityPrefsKey);
  }

  Future<void> saveLastCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(WeatherConfig.lastCityPrefsKey, city);
  }
}
