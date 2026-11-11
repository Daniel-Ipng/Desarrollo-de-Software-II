import 'weather_constants.dart';

/// Modelo del clima actual (parseo manual del JSON de OpenWeatherMap).
class Weather {
  final int id;
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String iconUrl;

  const Weather({
    required this.id,
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.iconUrl,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final condition =
        (json['weather'] as List<dynamic>).first as Map<String, dynamic>;
    final wind = (json['wind'] as Map<String, dynamic>?) ?? const {};
    final sys = (json['sys'] as Map<String, dynamic>?) ?? const {};

    return Weather(
      id: json['id'] as int,
      cityName: json['name'] as String,
      country: (sys['country'] as String?) ?? '',
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      humidity: (main['humidity'] as num).toInt(),
      windSpeed: ((wind['speed'] ?? 0) as num).toDouble(),
      description: condition['description'] as String,
      iconUrl: WeatherConfig.iconUrl(condition['icon'] as String),
    );
  }
}
